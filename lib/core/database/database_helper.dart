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
      version: 6, // Upgraded version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
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

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE pending_photos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          detail_local_id INTEGER NOT NULL,
          photo_path TEXT NOT NULL,
          caption TEXT,
          created_at TEXT,
          FOREIGN KEY (detail_local_id) REFERENCES pending_details (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE pending_logs ADD COLUMN server_log_id TEXT');
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
    await db.execute('''
      CREATE TABLE pending_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        worker_name $textType,
        mandor_id $textNullable,
        status_approval $textNullable,
        created_at $textNullable,
        updated_at $textNullable,
        server_log_id $textNullable
      )
    ''');

    // Table for pending monitoring details
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

    // Table for pending photos
    await db.execute('''
      CREATE TABLE pending_photos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        detail_local_id INTEGER NOT NULL,
        photo_path TEXT NOT NULL,
        caption TEXT,
        created_at TEXT,
        FOREIGN KEY (detail_local_id) REFERENCES pending_details (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
