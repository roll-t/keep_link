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

  static final List<String> _tableCreators = [];

  static void registerModel(DbModel model) {
    final columnsSql = model.columns.entries.map((e) => '${e.key} ${e.value}').join(', ');
    final sql = 'CREATE TABLE IF NOT EXISTS ${model.tableName} ($columnsSql)';
    _tableCreators.add(sql);
  }

  // Insert or Update
  static Future<void> upsert(DbModel model) async {
    final db = await database;
    await db.insert(model.tableName, model.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get all
  static Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    final db = await database;
    return await db.query(tableName);
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
