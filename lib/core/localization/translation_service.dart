import 'dart:collection';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:keep_link/core/localization/vi.dart';

import 'en.dart';

class LocalizationService extends Translations {
  static const String _languageKey = 'selected_language';
  static const String _storageKey = 'keep_link_storage';

  // Fallback to user's saved language or default to 'en'
  static Locale? locale;

  // Default fallback locale if the chosen language isn't supported
  static const fallbackLocale = Locale('vi', 'VN');

  // Supported language codes
  static final langCodes = [
    'en',
    'vi',
  ];
  // Supported language codes
  static final delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  // Supported locales
  static final locales = [
    const Locale('en', 'US'),
    const Locale('vi', 'VN'),
  ];

  // Language options for display (e.g., for dropdown)
  static final langs = LinkedHashMap.from({
    'en': 'English',
    'vi': 'Tiếng Việt',
  });

  /// Initialize localization service
  /// Call this in app_config before runApp
  static Future<void> initialize() async {
    await GetStorage.init(_storageKey);
    _loadSavedLanguage();
  }

  /// Load saved language from storage
  static void _loadSavedLanguage() {
    final box = GetStorage(_storageKey);
    final savedLangCode = box.read(_languageKey) as String?;

    if (savedLangCode != null && langCodes.contains(savedLangCode)) {
      locale = _getLocaleFromLanguage(langCode: savedLangCode);
    } else {
      // If no saved preference, use device locale
      locale = _getLocaleFromLanguage();
    }
  }

  /// Change locale and save preference
  static Future<void> changeLocale(String langCode) async {
    final newLocale = _getLocaleFromLanguage(langCode: langCode);
    if (newLocale != null) {
      locale = newLocale;
      await Get.updateLocale(locale!);
      
      // Persist language preference
      final box = GetStorage(_storageKey);
      await box.write(_languageKey, langCode);
    }
  }

  /// Get current language code
  static String getCurrentLanguageCode() {
    return locale?.languageCode ?? 'vi';
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en,
        'vi_VN': vi,
      };

  // Private function to get locale from language code
  static Locale? _getLocaleFromLanguage({String? langCode}) {
    var lang = langCode ?? Get.deviceLocale?.languageCode ?? 'vi';
    for (int i = 0; i < langCodes.length; i++) {
      if (lang.trim() == langCodes[i].trim()) return locales[i];
    }
    return fallbackLocale;
  }
}
