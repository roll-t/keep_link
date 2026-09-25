import 'package:flutter_test/flutter_test.dart';
import 'package:keep_link/features/category/application/category_name_rules.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';

void main() {
  group('CategoryNameRules', () {
    test('trims and collapses whitespace before storing', () {
      expect(
        CategoryNameRules.clean('  Tài liệu   học tập  '),
        'Tài liệu học tập',
      );
    });

    test('detects duplicate names without case or spacing differences', () {
      final categories = [CategoryModel(id: '1', name: 'Phim  Hay')];

      expect(CategoryNameRules.isDuplicate('  phim hay ', categories), isTrue);
    });

    test('allows the current category name while editing', () {
      final categories = [CategoryModel(id: '1', name: 'Truyện ngắn')];

      expect(
        CategoryNameRules.isDuplicate(
          'truyện ngắn',
          categories,
          editingId: '1',
        ),
        isFalse,
      );
    });

    test('recognizes the localized aggregate category name as reserved', () {
      expect(CategoryNameRules.isReserved(' TẤT CẢ ', 'Tất cả'), isTrue);
      expect(CategoryNameRules.isReserved(' all ', 'All'), isTrue);
    });
  });
}
