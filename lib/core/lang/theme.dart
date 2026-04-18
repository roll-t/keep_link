// App theme translation keys
const Map<String, Map<String, String>> themeTranslations = {
  'en': {'dark': 'Dark', 'light': 'Light', 'system': 'System'},
  'vi': {'dark': 'Tối', 'light': 'Sáng', 'system': 'Hệ thống'},
};

enum AppThemeMode { dark, light, system }

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.system:
        return 'system';
    }
  }

  static AppThemeMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return AppThemeMode.light;
      case 'system':
        return AppThemeMode.system;
      case 'dark':
      default:
        return AppThemeMode.dark;
    }
  }
}
