import 'package:keep_link/features/category/application/model/category_model.dart';

/// Pure naming rules shared by category create and edit flows.
class CategoryNameRules {
  CategoryNameRules._();

  static const int maxLength = 50;

  static String clean(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String comparisonKey(String value) => clean(value).toLowerCase();

  static bool isReserved(String value, String allLabel) =>
      comparisonKey(value) == comparisonKey(allLabel);

  static bool isDuplicate(
    String value,
    Iterable<CategoryModel> categories, {
    String? editingId,
  }) {
    final key = comparisonKey(value);
    return categories.any(
      (category) =>
          category.id != editingId && comparisonKey(category.name ?? '') == key,
    );
  }
}
