import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();

  static Future<DatabaseHelper> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseHelper._();
      await _instance!._init();
    }
    return _instance!;
  }

  Database get db => _db!;

  Future<void> _init() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    } catch (_) {}
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'space_game.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        story_progress INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE ranking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        minigame TEXT NOT NULL,
        played_at TEXT NOT NULL,
        result TEXT NOT NULL,
        score INTEGER DEFAULT 0,
        difficulty TEXT DEFAULT 'easy',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  // --- Users ---
  Future<int> insertUser(String name) async {
    return _db!.insert('users', {'name': name, 'story_progress': 0});
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return _db!.query('users');
  }

  Future<void> updateStoryProgress(int userId, int progress) async {
    await _db!.update('users', {'story_progress': progress}, where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> deleteUser(int userId) async {
    await _db!.delete('ranking', where: 'user_id = ?', whereArgs: [userId]);
    await _db!.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  // --- Ranking ---
  Future<int> insertRanking({
    required int userId,
    required String minigame,
    required String result,
    required int score,
    required String difficulty,
  }) async {
    return _db!.insert('ranking', {
      'user_id': userId,
      'minigame': minigame,
      'played_at': DateTime.now().toIso8601String(),
      'result': result,
      'score': score,
      'difficulty': difficulty,
    });
  }

  Future<List<Map<String, dynamic>>> getRanking(String minigame) async {
    return _db!.rawQuery('''
      SELECT r.*, u.name as user_name
      FROM ranking r
      INNER JOIN users u ON r.user_id = u.id
      WHERE r.minigame = ?
      ORDER BY r.played_at DESC
    ''', [minigame]);
  }
}
