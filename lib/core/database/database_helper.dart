import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('crosscheck.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Upgraded version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Simplest way for this exercise is to drop and recreate, 
      // but in production we should use ALTER TABLE
      await db.execute('DROP TABLE IF EXISTS pending_details');
      await db.execute('DROP TABLE IF EXISTS pending_logs');
      await db.execute('DROP TABLE IF EXISTS task_types');
      await _createDB(db, newVersion);
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE pending_details ADD COLUMN nomor_baris TEXT');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE pending_details ADD COLUMN nama_anggota TEXT');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    // Table for caching TaskTypes
    await db.execute('''
      CREATE TABLE task_types (
        id $idType,
        name $textType,
        unit_measure $textNullable
      )
    ''');

    // Table for pending monitoring logs (header)
    // Matches tr_monitoring_log fields
    await db.execute('''
      CREATE TABLE pending_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_name $textType,
        mandor_id $textNullable,
        status_approval $textNullable,
        created_at $textNullable,
        updated_at $textNullable
      )
    ''');

    // Table for pending monitoring details
    // Matches tr_monitoring_detail fields
    await db.execute('''
      CREATE TABLE pending_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        log_local_id INTEGER NOT NULL,
        task_type_id $textType,
        quantity $textNullable,
        conditions $textNullable,
        photo_path $textNullable,
        descriptions $textNullable,
        nomor_baris $textNullable,
        locations $textNullable,
        status_task $textNullable,
        created_at $textNullable,
        local_image_path $textNullable,
        nama_anggota $textNullable,
        FOREIGN KEY (log_local_id) REFERENCES pending_logs (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
