import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static final DBHelper _instance = DBHelper._internal();

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'reminder.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      description TEXT,
      dateTime TEXT,
      isDaily INTEGER
    )
    ''');
  }

  Future<int> insertReminder(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('reminders', row);
  }

  Future<List<Map<String, dynamic>>> queryAllReminders() async {
    Database db = await database;
    return await db.query('reminders');
  }

  Future<int> updateReminder(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update('reminders', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReminder(int id) async {
    Database db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
