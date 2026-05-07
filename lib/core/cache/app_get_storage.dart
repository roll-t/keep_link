import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:keep_link/core/lang/translation_service.dart';

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

  static void savePin(String pin) => _box.write(_pinKey, pin);
  static String? getPin() => _box.read(_pinKey);

  // ========== Category Security (New Logic) ========== //

  /// Bật/Tắt bảo mật riêng cho danh mục
  static void setCategorySecurity(bool value) => _box.write(_categorySecurityEnabledKey, value);

  /// Kiểm tra xem bảo mật danh mục có đang bật không
  /// Mặc định là TRUE (để an toàn, nếu user bật khóa app thì danh mục private cũng nên khóa)
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

  /// Lấy danh sách key đã mở chi tiết từng item (dạng "ownerUid/catId")
  static Set<String> getViewedSharedItemKeys(String uid) {
    final raw = _box.read<List>('$_viewedSharedItemsPrefix$uid');
    if (raw == null) return {};
    return raw.cast<String>().toSet();
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
