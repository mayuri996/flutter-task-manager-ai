import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class TaskDatabase {
  static final TaskDatabase instance = TaskDatabase._init();

  static Database? _database;

  TaskDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        status TEXT,
        lastModified INTEGER NOT NULL,
        sentiment TEXT
      )
    ''');
    await db.execute('''
    CREATE TABLE deleted_tasks (
      id INTEGER PRIMARY KEY
    )
    ''');
  }

  // Add deleted task id to deleted_tasks table
  Future<void> addDeletedTaskId(int id) async {
    final db = await instance.database;
    await db.insert(
        'deleted_tasks',
        {
          'id': id,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get list of deleted task IDs
  Future<List<int>> getDeletedTaskIds() async {
    final db = await instance.database;
    final result = await db.query('deleted_tasks');
    return result.map((e) => e['id'] as int).toList();
  }

  // Remove deleted task id after sync
  Future<void> removeDeletedTaskId(int id) async {
    final db = await instance.database;
    await db.delete('deleted_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Task> create(Task task) async {
    final db = await instance.database;
    final taskWithTimestamp = task.copyWith(
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    final id = await db.insert('tasks', taskWithTimestamp.toMap());
    return taskWithTimestamp.copyWith(id: id);
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final result = await db.query('tasks');
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> update(Task task) async {
    final db = await instance.database;
    final taskWithTimestamp = task.copyWith(
      lastModified: DateTime.now().millisecondsSinceEpoch,
    );
    return await db.update(
      'tasks',
      taskWithTimestamp.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
