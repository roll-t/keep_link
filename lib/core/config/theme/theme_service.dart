import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/core/localization/theme_translations.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_mode';
  static const String _storageKey = 'keep_link_storage';

  static final _currentThemeMode = 'dark'.obs;

  static String get currentThemeMode => _currentThemeMode.value;

  static AppThemeMode get themeMode {
    return AppThemeModeExtension.fromString(_currentThemeMode.value);
  }

  /// Initialize theme service - load saved theme preference
  static Future<void> initialize() async {
    final box = GetStorage(_storageKey);
    final savedTheme = box.read(_themeKey) as String? ?? 'dark';
    _currentThemeMode.value = savedTheme;
  }

  /// Change theme and save preference
  static Future<void> changeTheme(AppThemeMode theme) async {
    _currentThemeMode.value = theme.displayName;
    final box = GetStorage(_storageKey);
    await box.write(_themeKey, theme.displayName);

    // Update GetX theme
    _updateGetXTheme(theme);
  }

  /// Update GetX theme
  static void _updateGetXTheme(AppThemeMode theme) {
    // Note: ThemeMode doesn't directly map to GetX, but we can update through app restart
    // For a more seamless experience, consider using a GetX controller pattern
  }

  /// Get all available themes
  static List<AppThemeMode> get availableThemes => [
    AppThemeMode.dark,
    AppThemeMode.light,
    AppThemeMode.system,
  ];

  /// Get display name for theme
  static String getThemeDisplayName(AppThemeMode theme) {
    return theme.displayName;
  }

  /// Check if dark theme is active
  static bool get isDarkTheme => themeMode == AppThemeMode.dark;

  /// Check if light theme is active
  static bool get isLightTheme => themeMode == AppThemeMode.light;
}
