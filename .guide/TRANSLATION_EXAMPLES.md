# 🎯 Quick Translation Implementation Examples

## Example 1: Using `.tr` in TextWidget

### ❌ Before (Hardcoded):
```dart
const TextWidget(
  text: "Settings",
  color: AppColors.white,
  size: 16,
  fontWeight: FontWeight.w600,
)
```

### ✅ After (Localized):
```dart
TextWidget(
  text: "Settings".tr,  // ← Add .tr here
  color: AppColors.white,
  size: 16,
  fontWeight: FontWeight.w600,
)
```

---

## Example 2: CustomAppBar with Translation

### ❌ Before:
```dart
appBar: CustomAppBar(title: "Cài đặt"),
```

### ✅ After:
```dart
appBar: CustomAppBar(title: "Settings".tr),
```

---

## Example 3: Conditional Text Based on Language

```dart
Obx(() {
  final isEnglish = Get.locale == const Locale('en', 'US');
  
  return Text(
    isEnglish ? "Search links".tr : "Tìm kiếm link".tr,
  );
})
```

Or simpler:
```dart
Text("Search links".tr)  // Automatically uses current language
```

---

## Example 4: Settings Page with Translations

```dart
class SettingPage extends StatelessWidget {
  static String routeName = "/SettingPage";
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Settings".tr),  // ✅ Localized
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12).copyWith(top: 16),
        child: Column(
          spacing: 16,
          children: [
            ItemSetting(
              title: "Security".tr,  // ✅ Localized
              onTap: () {
                Get.toNamed(SecurityMethodPage.routeName);
              },
            ),
            ItemSetting(
              title: "Warnings".tr,  // ✅ Localized
              onTap: () {
                Get.toNamed(WarningPage.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Example 5: Search Page with Multiple Translations

```dart
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _CategoryChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.bg500,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.white.withOpacityCompat(0.12),
        ),
      ),
      child: TextWidget(
        text: label.tr,  // ✅ Add .tr for translated category names
        color: selected ? AppColors.white : AppColors.white.withOpacityCompat(0.55),
        size: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
```

---

## Example 6: Language Switcher Widget

Create a simple language switcher in Settings:

```dart
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        TextWidget(text: "Language".tr),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => LocalizationService.changeLocale('en'),
                child: Text("English".tr),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => LocalizationService.changeLocale('vi'),
                child: Text("Vietnamese".tr),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Example 7: Using Translations in Controllers

```dart
class SearchLinkController extends GetxController {
  void showNoResultsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text("No Results".tr),  // ✅ Localized
        content: Text("No matching results found".tr),  // ✅ Localized
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("OK".tr),  // ✅ Localized
          ),
        ],
      ),
    );
  }
}
```

---

## Example 8: Ternary with Translation

```dart
// ❌ Avoid
Container(
  child: Text(
    selected 
      ? "Confirm PIN" 
      : "Enter PIN",
  ),
)

// ✅ Better
Container(
  child: Text(
    selected 
      ? "Confirm PIN".tr 
      : "Enter PIN".tr,
  ),
)
```

---

## Example 9: List Items with Translations

```dart
class _FilterSheet extends StatelessWidget {
  static const _sortOptions = [
    (SortOption.newest, "Newest", Icons.arrow_downward_rounded),
    (SortOption.oldest, "Oldest", Icons.arrow_upward_rounded),
    (SortOption.nameAZ, "Name A → Z", Icons.sort_by_alpha_rounded),
    (SortOption.nameZA, "Name Z → A", Icons.sort_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _sortOptions.map((opt) {
        final (value, label, icon) = opt;
        return ListTile(
          title: Text(label.tr),  // ✅ Localized
        );
      }).toList(),
    );
  }
}
```

---

## Example 10: Adding New Translations

### Step 1: Add to `en.dart`
```dart
Map<String, String> en = {
  // ... existing translations
  "New Feature": "New Feature description",
};
```

### Step 2: Add to `vi.dart`
```dart
Map<String, String> vi = {
  // ... existing translations
  "New Feature": "Mô tả tính năng mới",
};
```

### Step 3: Use in Code
```dart
Text("New Feature".tr)
```

---

## Testing Translations

### Manual Testing
```dart
// In any widget, add buttons to test language switching
Row(
  children: [
    ElevatedButton(
      onPressed: () => LocalizationService.changeLocale('en'),
      child: Text('EN'),
    ),
    ElevatedButton(
      onPressed: () => LocalizationService.changeLocale('vi'),
      child: Text('VI'),
    ),
  ],
)
```

### Verify translations exist
```dart
// Check if translation key exists
print(Get.find<LocalizationService>().keys['en_US']['Your Key']);
```

---

## Common Patterns

### Pattern 1: Static Text
```dart
Text("Settings".tr)
```

### Pattern 2: Dynamic Text from Variable
```dart
String dynamicText = getUserName();
Text(dynamicText)  // No .tr needed if not a hardcoded string
```

### Pattern 3: Formatted Text
```dart
Text("User: ${userName}".tr)  // Use if key exists in translation
// Or
Text("User: ") + Text(userName)  // Better for mixed content
```

### Pattern 4: Pluralization (Manual)
```dart
String itemText = items.length > 1 
  ? "Items".tr 
  : "Item".tr;
Text(itemText)
```

---

## 🎓 Summary

| What to Do | Example |
|-----------|---------|
| Add `.tr` to hardcoded strings | `"Text".tr` |
| Add translations to both files | `en.dart` and `vi.dart` |
| Change language | `LocalizationService.changeLocale('en')` |
| Check current locale | `Get.locale` |
| Use in any context | Works in Widgets, Controllers, Services |

**Remember:** Always add `.tr` to user-facing strings! 🚀
