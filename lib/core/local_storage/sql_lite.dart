import 'package:keep_link/core/model/db_model.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _db;
  static const int _version = 1;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        for (var tableCreator in _tableCreators) {
          await db.execute(tableCreator);
        }
      },
    );
  }

  // Delete whole database file
  static Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    await deleteDatabase(path);
    _db = null; // reset instance
  }

  // Delete DB then recreate new one
  static Future<void> resetDatabase() async {
    await deleteDatabaseFile();

    // Recreate DB by calling getter
    await database;

    // Re-create tables using stored table creators
    final db = await database;
    for (var tableCreator in _tableCreators) {
      await db.execute(tableCreator);
    }
  }

  static final List<String> _tableCreators = [];

  static void registerModel(DbModel model) {
    final exists = _tableCreators.any((sql) => sql.contains(model.tableName));
    if (exists) return;

    // 1. Tạo cột
    final columnsSql = model.columns.entries.map((e) => '${e.key} ${e.value}').join(', ');

    // 2. Thêm foreign keys nếu có
    final fkSql = model.foreignKeys.isNotEmpty ? ', ${model.foreignKeys.join(', ')}' : '';

    // 3. Gộp lại thành CREATE TABLE
    final sql =
        '''
    CREATE TABLE IF NOT EXISTS ${model.tableName} (
      $columnsSql
      $fkSql
    )
  ''';

    _tableCreators.add(sql);
  }

  // Insert or Update
  static Future<void> upsert(DbModel model) async {
    final db = await database;
    await db.insert(model.tableName, model.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Update row by id
  static Future<void> update(String tableName, String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(tableName, data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAll(
    String tableName, {
    String? orderByColumn,
    bool descending = true,
  }) async {
    final db = await database;

    final pragma = await db.rawQuery("PRAGMA table_info($tableName)");
    final columns = pragma.map((e) => e['name'] as String).toList();

    String? orderBy;
    if (orderByColumn != null && columns.contains(orderByColumn)) {
      orderBy = '$orderByColumn ${descending ? 'DESC' : 'ASC'}';
    } else if (columns.contains('created_at')) {
      orderBy = 'created_at ${descending ? 'DESC' : 'ASC'}';
    } else if (columns.contains('createdAt')) {
      orderBy = 'createdAt ${descending ? 'DESC' : 'ASC'}';
    }

    return await db.query(tableName, orderBy: orderBy);
  }

  // Get by id
  static Future<Map<String, dynamic>?> getById(String tableName, String id) async {
    final db = await database;
    final res = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // Delete
  static Future<void> delete(String tableName, String id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Clear table
  static Future<void> clearTable(String tableName) async {
    final db = await database;
    await db.delete(tableName);
  }
}
