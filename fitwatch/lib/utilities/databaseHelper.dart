import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//class to manage the creation, initialization and access to the SQLite database
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  //private constructor
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sensor_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  //defines the schema of the database by creating three tables
  Future _createDB(Database db, int version) async {
    // Raw logs table
    await db.execute('''
      CREATE TABLE raw_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        imu_timestamp INTEGER,
        label INTEGER,
        step_count INTEGER,
        distance REAL,
        speed REAL,
        accel_mag REAL,
        acc_x REAL,
        acc_y REAL,
        acc_z REAL,
        gyro_x REAL,
        gyro_y REAL,
        gyro_z REAL,
        activity TEXT,
        battery_percent INTEGER
      )
    ''');

    // Daily summary table
    await db.execute('''
      CREATE TABLE daily_summary (
        date TEXT NOT NULL,
        activity TEXT NOT NULL,
        duration INTEGER NOT NULL,
        PRIMARY KEY (date, activity)
      )
    ''');

    // Weekly summary table
    await db.execute('''
      CREATE TABLE weekly_summary (
        week_id TEXT NOT NULL,
        activity TEXT NOT NULL,
        duration INTEGER NOT NULL,
        PRIMARY KEY (week_id, activity)
      )
    ''');
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
