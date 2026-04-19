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

  static void clearSearchHistory() {
    _box.remove(_searchHistoryKey);
  }

  static int get maxSearchHistory => _maxSearchHistory;

  // ========== Custom Data ========== //
  static void write<T>(String key, T value) => _box.write(key, value);
  static T? read<T>(String key) => _box.read<T>(key);
  static void remove(String key) => _box.remove(key);
  static void clear() => _box.erase();

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
