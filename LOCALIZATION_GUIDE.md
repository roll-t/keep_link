# 🌍 Multi-Language Setup Guide for Keep Link App

## ✅ Current Setup Status

Your app already has a complete localization system configured using **GetX Translations**!

### Supported Languages
- 🇺🇸 **English** (`en_US`)
- 🇻🇳 **Vietnamese** (`vi_VN`)

---

## 📂 Project Structure

```
lib/
├── core/
│   └── lang/
│       ├── translation_service.dart   ← Main localization service
│       ├── en.dart                    ← English translations
│       └── vi.dart                    ← Vietnamese translations
├── app.dart                           ← Configured with localization
└── main.dart
```

---

## 🚀 How to Use Translations in Code

### 1. **Using `.tr` Extension (Recommended)**

The simplest way to translate strings is using the `.tr` extension on any string:

```dart
// In any widget
Text("Search links".tr)
TextWidget(text: "Settings".tr)
```

**How it works:**
- GetX looks for "Search links" key in the current language's map
- If found, returns the translated value
- If not found, returns the original string as fallback

### 2. **Using `Get.locale` to Check Current Language**

```dart
if (Get.locale == const Locale('en', 'US')) {
  // Do something for English
} else if (Get.locale == const Locale('vi', 'VN')) {
  // Do something for Vietnamese
}
```

### 3. **Changing Language Dynamically**

```dart
// Change to English
LocalizationService.changeLocale('en');

// Change to Vietnamese
LocalizationService.changeLocale('vi');
```

---

## 📋 Translation Key Reference

### Settings & Security
| Key | English | Vietnamese |
|-----|---------|-----------|
| `"Settings"` | Settings | Cài đặt |
| `"Security"` | Security | Bảo mật |
| `"Security Methods"` | Security Methods | Phương thức bảo mật |
| `"App Security"` | App Security | Bảo mật ứng dụng |
| `"Category Security"` | Category Security | Bảo mật danh mục |
| `"PIN Code"` | PIN Code | Mã PIN |
| `"Fingerprint"` | Fingerprint | Vân tay |
| `"Set PIN"` | Set PIN | Đặt PIN |
| `"Change PIN"` | Change PIN | Đổi PIN |
| `"Enter PIN"` | Enter PIN | Nhập PIN |
| `"Confirm PIN"` | Confirm PIN | Xác nhận PIN |

### Search
| Key | English | Vietnamese |
|-----|---------|-----------|
| `"Search links"` | Search links | Tìm kiếm link |
| `"Browse by Category"` | Browse by Category | Duyệt theo Danh mục |
| `"Sort by"` | Sort by | Sắp xếp theo |
| `"Newest"` | Newest | Mới nhất |
| `"Oldest"` | Oldest | Cũ nhất |
| `"No matching results found"` | No matching results found | Không tìm thấy kết quả phù hợp |

### Collections
| Key | English | Vietnamese |
|-----|---------|-----------|
| `"No links yet"` | No links yet | Chưa có link nào |
| `"Save your favorite links"` | Save your favorite links | Hãy lưu những link bạn yêu thích |
| `"Add Link"` | Add Link | Thêm link |
| `"Search"` | Search | Tìm kiếm |

---

## 💡 Step-by-Step Implementation

### Step 1: Update Your Translation Files

When adding new strings, add them to **both** `en.dart` and `vi.dart`:

**en.dart:**
```dart
Map<String, String> en = {
  "New feature": "New feature description",
  // ... other translations
};
```

**vi.dart:**
```dart
Map<String, String> vi = {
  "New feature": "Mô tả tính năng mới",
  // ... other translations
};
```

### Step 2: Use `.tr` in Your Code

Replace hardcoded strings with `.tr`:

```dart
// ❌ Before
Text('Settings')

// ✅ After
Text('Settings'.tr)
```

### Step 3: Test Language Switching

```dart
// Test button to switch languages
ElevatedButton(
  onPressed: () => LocalizationService.changeLocale('en'),
  child: Text('Switch to English'),
),
ElevatedButton(
  onPressed: () => LocalizationService.changeLocale('vi'),
  child: Text('Chuyển sang Tiếng Việt'),
),
```

---

## 🔧 Configuration Files

### `lib/core/lang/translation_service.dart`

This file handles:
- Language codes: `['en', 'vi']`
- Supported locales: `[Locale('en', 'US'), Locale('vi', 'VN')]`
- Fallback locale: `Locale('vi', 'VN')`
- Language switching via `changeLocale()`

### `lib/app.dart`

Configured with GetMaterialApp:
```dart
GetMaterialApp(
  translations: LocalizationService(),
  locale: LocalizationService.locale,
  fallbackLocale: LocalizationService.fallbackLocale,
  supportedLocales: LocalizationService.locales,
  localizationsDelegates: LocalizationService.delegates,
  // ...
)
```

---

## 📝 Adding a New Language

To add a new language (e.g., Spanish - `es_ES`):

### 1. Create new file: `lib/core/lang/es.dart`
```dart
Map<String, String> es = {
  "Settings": "Configuración",
  "Security": "Seguridad",
  // ... add all translations
};
```

### 2. Update `translation_service.dart`
```dart
import 'package:keep_link/core/lang/es.dart';

class LocalizationService extends Translations {
  static final langCodes = ['en', 'vi', 'es'];
  
  static final locales = [
    const Locale('en', 'US'),
    const Locale('vi', 'VN'),
    const Locale('es', 'ES'),
  ];
  
  static final langs = LinkedHashMap.from({
    'en': 'English',
    'vi': 'Tiếng Việt',
    'es': 'Español',
  });
  
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': en,
    'vi_VN': vi,
    'es_ES': es,
  };
}
```

---

## 🎯 Best Practices

1. ✅ **Use `.tr` consistently** - Add `.tr` to all user-facing strings
2. ✅ **Keep translations organized** - Group related translations together
3. ✅ **Test both languages** - Always verify translations in both languages
4. ✅ **Use descriptive keys** - Make keys easy to understand
5. ✅ **Avoid hardcoded strings** - Use translation keys instead
6. ✅ **Handle special characters** - Some symbols may need escaping

### Example - Before & After

**❌ Before (Hardcoded):**
```dart
class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Cài đặt"),
      body: Column(
        children: [
          ItemSetting(title: "Bảo mật"),
          ItemSetting(title: "Lưu ý"),
        ],
      ),
    );
  }
}
```

**✅ After (Using Translations):**
```dart
class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Settings".tr),
      body: Column(
        children: [
          ItemSetting(title: "Security".tr),
          ItemSetting(title: "Warnings".tr),
        ],
      ),
    );
  }
}
```

---

## 🚨 Common Issues & Solutions

### Issue: Translation not showing
**Solution:** Make sure the key exists in both `en.dart` and `vi.dart`

### Issue: Special characters not displaying
**Solution:** Use Unicode escape sequences if needed
```dart
"Name A → Z": "Name A → Z",  // Keep as is
```

### Issue: Long translations causing layout issues
**Solution:** Test with longer text and adjust layout accordingly

---

## 📚 Useful Resources

- [GetX Documentation - Translations](https://github.com/jonataslaw/getx/blob/master/documentation/en_US/dependency_management.md)
- [Flutter Internationalization Guide](https://flutter.dev/docs/development/accessibility-and-localization/internationalization)

---

## ✨ Next Steps

1. **Update all hardcoded strings** in your UI pages to use `.tr`
2. **Ensure translations exist** for all strings in both language files
3. **Add a language switcher** in Settings page
4. **Test thoroughly** with both English and Vietnamese
5. **Consider adding more languages** as your app expands

---

**Your app is now ready for multi-language support! 🎉**
