import 'package:keep_link/core/cache/app_cache.dart';
import 'package:keep_link/core/cache/sql_lite.dart';
import 'package:keep_link/features/category/application/model/category_model.dart';

/// Data-access layer for [CategoryModel].
///
/// All reads are served from [AppCache] (in-memory).
/// All writes go to SQLite first, then update the cache in-place.
class CategoryRepository {
  CategoryRepository._();

  // ── Bootstrap ─────────────────────────────────────────────────────────────

  /// Loads all categories from SQLite into [AppCache] exactly **once**.
  /// Subsequent calls return immediately without touching the DB.
  static Future<void> ensureLoaded() async {
    if (AppCache.categoriesLoaded) return;

    final db = await DbHelper.database;
    final rows = await db.rawQuery('''
      SELECT c.*, COUNT(l.id) AS children_count
      FROM categories c
      LEFT JOIN links l ON l.categoryId = c.id
      GROUP BY c.id
      ORDER BY c.created_at DESC
    ''');
    final list = rows.map((r) => CategoryModel.fromJson(Map<String, dynamic>.from(r))).toList();
    AppCache.setCategories(list);
  }

  // ── Reads (in-memory, no I/O) ─────────────────────────────────────────────

  /// Snapshot of all cached categories (unmodifiable).
  static List<CategoryModel> getAll() => List.unmodifiable(AppCache.categories);

  // ── Writes (write-through) ────────────────────────────────────────────────

  /// Insert a new category.  Writes to DB then prepends to cache.
  static Future<void> insert(CategoryModel category) async {
    await DbHelper.upsert(category);
    AppCache.addCategory(category);
  }

  /// Update an existing category.  Writes to DB then updates cache in-place.
  static Future<void> update(CategoryModel category) async {
    await DbHelper.upsert(category);
    AppCache.updateCategory(category);
  }

  /// Delete a category by id.  Removes from DB then from cache.
  static Future<void> delete(String id) async {
    await DbHelper.delete(CategoryModel().tableName, id);
    AppCache.removeCategory(id);
  }

  /// Clear all categories (used during debug/reset flows).
  static Future<void> clearAll() async {
    await DbHelper.clearTable(CategoryModel().tableName);
    AppCache.categories.clear();
  }
}
