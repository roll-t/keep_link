import 'package:keep_link/core/data/models/db_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static Database? _db;
  static const int _version = 3;

  // Cache schema info để tránh query PRAGMA mỗi lần
  static final Map<String, List<String>> _columnCache = {};

  // Dùng Map thay List để tránh duplicate theo tableName
  static final Map<String, String> _tableSchemas = {};

  // ─── Khởi tạo ───────────────────────────────────────────────────────────────

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(path, version: _version, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    for (final sql in _tableSchemas.values) {
      batch.execute(sql);
    }
    await batch.commit(noResult: true);
  }

  /// Placeholder migration — thêm case khi tăng _version
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final batch = db.batch();
    if (oldVersion < 3) {
      batch.execute('DROP TABLE IF EXISTS friends');
    }
    for (final sql in _tableSchemas.values) {
      batch.execute(sql);
    }
    await batch.commit(noResult: true);
  }

  // ─── Đăng ký model ──────────────────────────────────────────────────────────

  /// Gọi trước khi mở DB. Chỉ lưu schema, không tạo instance thừa.
  static void registerModel(DbModel model) {
    if (_tableSchemas.containsKey(model.tableName)) return;

    final columnsSql = model.columns.entries.map((e) => '${e.key} ${e.value}').join(', ');

    final fkSql = model.foreignKeys.isNotEmpty ? ', ${model.foreignKeys.join(', ')}' : '';

    _tableSchemas[model.tableName] =
        '''
      CREATE TABLE IF NOT EXISTS ${model.tableName} (
        $columnsSql
        $fkSql
      )
    ''';
  }

  // ─── Quản lý database ───────────────────────────────────────────────────────

  static Future<void> deleteDatabaseFile() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    await deleteDatabase(path);
    _db = null;
    _columnCache.clear();
  }

  /// Xoá và tạo lại database (dùng khi debug / logout)
  static Future<void> resetDatabase() async {
    await deleteDatabaseFile();
    await database; // onCreate sẽ tự chạy, không cần gọi lại thủ công
  }

  // ─── CRUD ───────────────────────────────────────────────────────────────────

  /// Insert hoặc replace nếu trùng primary key
  static Future<void> upsert(DbModel model) async {
    final db = await database;
    await db.insert(model.tableName, model.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Batch upsert — hiệu quả hơn khi insert nhiều record
  static Future<void> upsertAll(List<DbModel> models) async {
    if (models.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final model in models) {
      batch.insert(model.tableName, model.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Cập nhật các field theo id
  static Future<void> update(String tableName, String id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update(tableName, data, where: 'id = ?', whereArgs: [id]);
  }

  /// Lấy danh sách có hỗ trợ filter, sắp xếp, phân trang
  static Future<List<Map<String, dynamic>>> getAll(
    String tableName, {
    String? orderByColumn,
    bool descending = true,
    int? limit,
    int? offset,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;

    final orderBy = await _resolveOrderBy(db, tableName, orderByColumn, descending);

    return db.query(
      tableName,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
      where: where,
      whereArgs: whereArgs,
    );
  }

  /// Đếm số record — dùng cho phân trang
  static Future<int> count(String tableName, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableName'
      '${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Lấy 1 record theo id, trả null nếu không tìm thấy
  static Future<Map<String, dynamic>?> getById(String tableName, String id) async {
    final db = await database;
    final res = await db.query(tableName, where: 'id = ?', whereArgs: [id], limit: 1);
    return res.firstOrNull;
  }

  static Future<void> delete(String tableName, String id) async {
    final db = await database;
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearTable(String tableName) async {
    final db = await database;
    await db.delete(tableName);
    _columnCache.remove(tableName);
  }

  // ─── Helper nội bộ ──────────────────────────────────────────────────────────

  /// Resolve orderBy và cache danh sách cột để tránh query PRAGMA lặp lại
  static Future<String?> _resolveOrderBy(
    Database db,
    String tableName,
    String? preferredColumn,
    bool descending,
  ) async {
    final direction = descending ? 'DESC' : 'ASC';

    // Lấy từ cache nếu đã có
    final columns = _columnCache[tableName] ?? await _fetchColumns(db, tableName);

    if (preferredColumn != null && columns.contains(preferredColumn)) {
      return '$preferredColumn $direction';
    }
    if (columns.contains('created_at')) return 'created_at $direction';
    if (columns.contains('createdAt')) return 'createdAt $direction';
    return null;
  }

  static Future<List<String>> _fetchColumns(Database db, String tableName) async {
    final pragma = await db.rawQuery('PRAGMA table_info($tableName)');
    final columns = pragma.map((e) => e['name'] as String).toList();
    _columnCache[tableName] = columns; // lưu cache
    return columns;
  }
}
