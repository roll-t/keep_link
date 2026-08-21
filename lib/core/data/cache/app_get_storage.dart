import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/core/localization/translation_service.dart';

class AppGetStorage {
  static final GetStorage _box = GetStorage();

  // ========== Init ========== //
  static Future<void> init() async {
    await GetStorage.init();
  }

  // ========== Keys ========== //
  static const String _themeKey = 'isDarkMode';
  static const String _tokenKey = 'accessToken';
  static const String _userKey = 'userData';
  static const String _isLoggedIn = 'isLoggedIn';
  static const String _selectedLanguageKey = 'selected_language';
  static const String _isNotificationEnabled = 'isNotificationEnabled';

  // Security Keys
  static const String _pinKey = 'app_pin';
  static const String _pinSaltKey = 'app_pin_salt';
  static const String _pinFailCountKey = 'app_pin_fail_count';
  static const String _pinLockUntilKey = 'app_pin_lock_until';
  static const String _securityEnabledKey = 'security_enabled';
  static const String _fingerprintEnabledKey = 'fingerprint_enabled';

  // 👉 THÊM KEY MỚI CHO CATEGORY
  static const String _categorySecurityEnabledKey = 'category_security_enabled';

  // ========== Theme ========== //
  static void saveTheme(bool isDark) => _box.write(_themeKey, isDark);
  static bool getTheme() => _box.read(_themeKey) ?? false;

  static void setNotificationEnabled(bool value) => _box.write(_isNotificationEnabled, value);
  static bool isNotificationEnabled() => _box.read(_isNotificationEnabled) ?? true;

  // ========== Token ========== //
  static void saveToken(String token) => _box.write(_tokenKey, token);
  static String? getToken() => _box.read(_tokenKey);

  // ========== Security (Global) ========== //
  static void setSecurityEnabled(bool value) => _box.write(_securityEnabledKey, value);
  static bool isSecurityEnabled() => _box.read(_securityEnabledKey) ?? false;

  static void setFingerprintEnabled(bool value) => _box.write(_fingerprintEnabledKey, value);

  // SỬA DÒNG NÀY: Mở khóa lại và cho phép đọc từ GetStorage
  static bool isFingerprintEnabled() => _box.read(_fingerprintEnabledKey) ?? false;

  /// Salt ngẫu nhiên riêng cho từng máy cài đặt, sinh 1 lần và lưu lại.
  /// Tránh dùng salt cố định trong source code (dễ bị precompute vì PIN chỉ có 10.000 khả năng).
  static String _getOrCreateSalt() {
    final existing = _box.read<String>(_pinSaltKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final salt = base64UrlEncode(bytes);
    _box.write(_pinSaltKey, salt);
    return salt;
  }

  static String _hashPin(String pin) {
    final salt = _getOrCreateSalt();
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  /// Hash kiểu cũ (salt cố định trong source) — chỉ dùng để migrate dữ liệu đã lưu trước đây.
  static String _legacyHashPin(String pin) {
    return sha256.convert(utf8.encode('keep_link_salt_$pin')).toString();
  }

  static void savePin(String pin) {
    _box.write(_pinKey, _hashPin(pin));
    resetPinFailCount();
  }

  /// Check if a PIN has been set
  static bool hasPin() {
    final pin = _box.read<String>(_pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Verify if the given raw PIN matches the stored hash (migrating legacy hash/plaintext PIN if present)
  static bool verifyPin(String rawPin) {
    final stored = _box.read<String>(_pinKey);
    if (stored == null || stored.isEmpty) return false;
    if (stored == _hashPin(rawPin)) return true;
    // Migration: PIN hashed with the old hardcoded-salt scheme
    if (stored == _legacyHashPin(rawPin)) {
      savePin(rawPin);
      return true;
    }
    // Migration: very old plaintext PIN
    if (stored == rawPin) {
      savePin(rawPin);
      return true;
    }
    return false;
  }

  @Deprecated('Use hasPin() or verifyPin() instead for security')
  static String? getPin() => _box.read(_pinKey);

  // ========== PIN brute-force lockout ========== //
  static const int _pinAttemptsPerLockTier = 5;
  static const List<int> _pinLockTierSeconds = [30, 60, 300, 900];

  /// Số lần nhập sai liên tiếp kể từ lần đúng/đặt PIN gần nhất.
  static int getPinFailCount() => _box.read<int>(_pinFailCountKey) ?? 0;

  /// Ghi nhận 1 lần nhập sai PIN và khoá tạm thời nếu vượt ngưỡng.
  static void registerPinFailure() {
    final count = getPinFailCount() + 1;
    _box.write(_pinFailCountKey, count);
    if (count % _pinAttemptsPerLockTier == 0) {
      final tier = (count ~/ _pinAttemptsPerLockTier) - 1;
      final seconds = _pinLockTierSeconds[min(tier, _pinLockTierSeconds.length - 1)];
      _box.write(_pinLockUntilKey, DateTime.now().add(Duration(seconds: seconds)).millisecondsSinceEpoch);
    }
  }

  static void resetPinFailCount() {
    _box.remove(_pinFailCountKey);
    _box.remove(_pinLockUntilKey);
  }

  /// Thời gian còn lại đang bị khoá nhập PIN, null nếu không bị khoá.
  static Duration? pinLockRemaining() {
    final untilMs = _box.read<int>(_pinLockUntilKey);
    if (untilMs == null) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(untilMs);
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  static bool isPinLocked() => pinLockRemaining() != null;

  // ========== Category Security (New Logic) ========== //

  /// Bật/Tắt bảo mật riêng cho danh mục
  static void setCategorySecurity(bool value) => _box.write(_categorySecurityEnabledKey, value);

  /// Kiểm tra xem bảo mật danh mục có đang bật không.
  /// Mặc định là FALSE — chỉ bật khi user chủ động bật ở màn Security Methods,
  /// tránh việc yêu cầu tạo PIN ngoài ý muốn ngay khi họ mở 1 danh mục private lần đầu.
  static bool isCategorySecurity() => _box.read(_categorySecurityEnabledKey) ?? false;

  /// Helper: Kiểm tra tổng hợp có cần check PIN cho category không
  /// Logic: Phải bật Bảo mật tổng (App Lock) VÀ bật Bảo mật danh mục
  static bool shouldCheckCategorySecurity() {
    return isSecurityEnabled() && isCategorySecurity();
  }

  // ========== Login ========== //
  static void setLoggedIn(bool value) => _box.write(_isLoggedIn, value);
  static bool isLoggedIn() => _box.read(_tokenKey) != null;

  static void clearAuth() {
    _box.remove(_tokenKey);
    _box.remove(_userKey);
  }

  /// Xoá toàn bộ dữ liệu của user (dùng khi đăng xuất hoặc cài mới).
  /// Giữ lại các tuỳ chọn chung như theme và ngôn ngữ.
  static void clearUserData() {
    _box.remove(_tokenKey);
    _box.remove(_userKey);
    _box.remove(_isLoggedIn);
    _box.remove(_pinKey);
    _box.remove(_securityEnabledKey);
    _box.remove(_fingerprintEnabledKey);
    _box.remove(_categorySecurityEnabledKey);
    _box.remove(_searchHistoryKey);
    _box.remove(_guestDefaultCategoryKey);
    _box.remove(_pinnedCategoryIdsKey);
  }

  // ========== Saved Accounts for Quick Switch ========== //
  static const String _savedAccountsKey = 'saved_accounts_list';

  static List<Map<String, dynamic>> getSavedAccounts() {
    final raw = _box.read<List>(_savedAccountsKey);
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static void saveAccountProfile({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
  }) {
    if (uid.isEmpty) return;
    final list = getSavedAccounts();
    final index = list.indexWhere((a) => a['uid'] == uid);
    final accountData = {
      'uid': uid,
      'email': email ?? '',
      'displayName': displayName ?? '',
      'photoUrl': photoUrl ?? '',
      'lastActiveAt': DateTime.now().millisecondsSinceEpoch,
    };
    if (index >= 0) {
      list[index] = accountData;
    } else {
      list.add(accountData);
    }
    _box.write(_savedAccountsKey, list);
  }

  static void removeSavedAccount(String uid) {
    final list = getSavedAccounts();
    list.removeWhere((a) => a['uid'] == uid);
    _box.write(_savedAccountsKey, list);
  }

  // ========== First Launch ========== //
  static const String _firstLaunchKey = 'app_first_launch_done';

  /// Trả về true nếu đây là lần đầu tiên app chạy sau khi cài đặt.
  static bool isFirstLaunch() => _box.read<bool>(_firstLaunchKey) != true;

  /// Đánh dấu đã chạy lần đầu; gọi ngay sau khi xử lý xong first-launch.
  static void markLaunched() => _box.write(_firstLaunchKey, true);

  // ========== Language ========== //
  static void setLanguage(String language) {
    _box.write(_selectedLanguageKey, language);
    LocalizationService.changeLocale(language == 'English' ? 'en' : 'vi');
  }

  static String getLanguage() {
    return _box.read(_selectedLanguageKey) ?? 'English';
  }

  // ========== Search History ========== //
  static const String _searchHistoryKey = 'search_history';
  static const int _maxSearchHistory = 20;

  static List<String> getSearchHistory() {
    final raw = _box.read<List>(_searchHistoryKey);
    if (raw == null) return [];
    return raw.cast<String>();
  }

  static void saveSearchHistory(List<String> history) {
    _box.write(_searchHistoryKey, history);
  }

  // ========== Guest Default Category ========== //
  static const String _guestDefaultCategoryKey = 'guest_default_category_id';

  /// ID of the auto-created default category for guest users.
  /// Null once the user has signed in and the category has been handled.
  static String? get guestDefaultCategoryId => _box.read<String>(_guestDefaultCategoryKey);

  static void setGuestDefaultCategoryId(String id) => _box.write(_guestDefaultCategoryKey, id);

  static void clearGuestDefaultCategoryId() => _box.remove(_guestDefaultCategoryKey);

  // ========== App Review ========== //
  static const String _hasRatedAppKey = 'has_rated_app';

  static String _ratedAppKeyForUser(String? userId) {
    if (userId == null || userId.trim().isEmpty) return _hasRatedAppKey;
    return '${_hasRatedAppKey}_${userId.trim()}';
  }

  static bool hasRatedApp({String? userId}) {
    return _box.read<bool>(_ratedAppKeyForUser(userId)) ?? false;
  }

  static void setHasRatedApp({String? userId}) {
    _box.write(_ratedAppKeyForUser(userId), true);
  }

  // ========== Avatar fingerprint ========== //
  static const String _avatarFingerprintKey = 'avatar_fingerprint';

  static String _avatarFingerprintKeyForUser(String uid) => '${_avatarFingerprintKey}_$uid';

  static int? getAvatarFingerprint(String uid) {
    return _box.read<int>(_avatarFingerprintKeyForUser(uid));
  }

  static void setAvatarFingerprint(String uid, int fingerprint) {
    _box.write(_avatarFingerprintKeyForUser(uid), fingerprint);
  }

  // ========== Avatar change limit (2/day) ========== //
  static const String _avatarChangeDateKey = 'avatar_change_date';
  static const String _avatarChangeCountKey = 'avatar_change_count';
  static const int maxAvatarChangesPerDay = 2;

  static String _avatarChangeDateKeyForUser(String uid) => '${_avatarChangeDateKey}_$uid';
  static String _avatarChangeCountKeyForUser(String uid) => '${_avatarChangeCountKey}_$uid';

  static int _todayDateInt() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Returns how many avatar changes remain today (0 means limit reached).
  static int avatarChangesRemainingToday(String uid) {
    final savedDate = _box.read<int>(_avatarChangeDateKeyForUser(uid));
    final today = _todayDateInt();
    if (savedDate != today) return maxAvatarChangesPerDay;
    final count = _box.read<int>(_avatarChangeCountKeyForUser(uid)) ?? 0;
    final remaining = maxAvatarChangesPerDay - count;
    return remaining < 0 ? 0 : remaining;
  }

  /// Call this after a successful avatar upload.
  static void recordAvatarChange(String uid) {
    final today = _todayDateInt();
    final savedDate = _box.read<int>(_avatarChangeDateKeyForUser(uid));
    final count = savedDate == today ? (_box.read<int>(_avatarChangeCountKeyForUser(uid)) ?? 0) : 0;
    _box.write(_avatarChangeDateKeyForUser(uid), today);
    _box.write(_avatarChangeCountKeyForUser(uid), count + 1);
  }

  static void clearSearchHistory() {
    _box.remove(_searchHistoryKey);
  }

  static int get maxSearchHistory => _maxSearchHistory;

  // ========== Custom Data ========== //
  static void write<T>(String key, T value) => _box.write(key, value);
  static T? read<T>(String key) => _box.read<T>(key);
  static void remove(String key) => _box.remove(key);
  static void clear() => _box.erase();

  // ========== Seen Shared Category Keys ========== //
  static const String _seenSharedKeysPrefix = 'seen_shared_keys_';

  /// Lấy danh sách key đã xem của user (dạng "ownerUid/catId")
  static Set<String> getSeenSharedKeys(String uid) {
    final raw = _box.read<List>('$_seenSharedKeysPrefix$uid');
    if (raw == null) return {};
    return raw.cast<String>().toSet();
  }

  /// Lưu danh sách key đã xem sau khi user mở trang danh mục chia sẻ
  static void setSeenSharedKeys(String uid, Set<String> keys) {
    _box.write('$_seenSharedKeysPrefix$uid', keys.toList());
  }

  /// Xoá seen keys khi user đăng xuất
  static void clearSeenSharedKeys(String uid) {
    _box.remove('$_seenSharedKeysPrefix$uid');
  }

  // ========== Viewed Shared Category Items (per-item red dot) ========== //
  static const String _viewedSharedItemsPrefix = 'viewed_shared_items_';

  /// Lấy danh sách key đã mở chi tiết từng item (dạng "ownerUid/catId" hoặc "ownerUid/linkId")
  static Set<String> getViewedSharedItemKeys(String uid) {
    final raw = _box.read<List>('$_viewedSharedItemsPrefix$uid');
    if (raw == null) return {};
    return raw.cast<String>().toSet();
  }

  /// Thêm key của item đã mở xem
  static void addViewedSharedItemKey(String uid, String key) {
    final current = getViewedSharedItemKeys(uid);
    current.add(key);
    _box.write('$_viewedSharedItemsPrefix$uid', current.toList());
  }

  /// Lưu danh sách key đã mở chi tiết từng item
  static void setViewedSharedItemKeys(String uid, Set<String> keys) {
    _box.write('$_viewedSharedItemsPrefix$uid', keys.toList());
  }

  /// Xoá viewed item keys khi user đăng xuất
  static void clearViewedSharedItemKeys(String uid) {
    _box.remove('$_viewedSharedItemsPrefix$uid');
  }

  // ========== Pinned Category IDs ========== //
  static const String _pinnedCategoryIdsKey = 'pinned_category_ids';

  static Set<String> getPinnedCategoryIds() {
    final raw = _box.read<List>(_pinnedCategoryIdsKey);
    if (raw == null) return {};
    return raw.cast<String>().toSet();
  }

  static void setPinnedCategoryIds(Set<String> ids) {
    _box.write(_pinnedCategoryIdsKey, ids.toList());
  }

  // ========== Control size ========== //
  static int estimateCacheSize() {
    // ... (Giữ nguyên logic cũ)
    List<String> keys = _box.getKeys().toList();
    int totalSize = 0;
    for (String key in keys) {
      var value = _box.read(key);
      if (value is String) {
        totalSize += utf8.encode(value).length;
      } else if (value is int) {
        totalSize += 4;
      } else if (value is double) {
        totalSize += 8;
      } else if (value is bool) {
        totalSize += 1;
      } else {
        totalSize += utf8.encode(value.toString()).length;
      }
    }
    return totalSize;
  }
}
