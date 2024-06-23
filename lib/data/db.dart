import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'csv_data.dart';
import '../model/class.dart';
import '../model/student.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('student.db');
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

  // no INTEGER PRIMARY KEY,

  Future _createDB(Database db, int version) async {
    const studentTable = '''
    CREATE TABLE IF NOT EXISTS student (
      no INTEGER,
      name TEXT,
      id INTEGER PRIMARY KEY,
      class TEXT,
      gender TEXT,
      dob TEXT,
      attendanceStatus TEXT,
      sitUpReps INTEGER,
      broadJumpCm INTEGER,
      sitAndReachCm INTEGER,
      pullUpReps INTEGER,
      shuttleRunSec REAL,
      runTime INTEGER,
      pftTestDate TEXT
    );
    ''';
    const mockStudentTable = '''
    CREATE TABLE IF NOT EXISTS mock_student (
      no INTEGER,
      name TEXT,
      id INTEGER PRIMARY KEY,
      class TEXT,
      gender TEXT,
      dob TEXT,
      attendanceStatus TEXT,
      sitUpReps INTEGER,
      broadJumpCm INTEGER,
      sitAndReachCm INTEGER,
      pullUpReps INTEGER,
      shuttleRunSec REAL,
      runTime INTEGER,
      pftTestDate TEXT
    );
    ''';
    await db.execute(studentTable);
    await db.execute(mockStudentTable);
  }

  String _getTableName(int tableType) {
    return tableType == 1 ? 'student' : 'mock_student';
  }

  Future<void> insertCsvData(List<CsvData> dataList, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    for (var data in dataList) {
      await db.insert(
        tableName,
        data.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Method to fetch all CSV data from the database
  Future<List<CsvData>> getAllCsvData(int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return CsvData(
        no: maps[i]['no'],
        name: maps[i]['name'],
        id: maps[i]['id'],
        classVal: maps[i]['class'],
        gender: maps[i]['gender'],
        dob: maps[i]['dob'],
        attendanceStatus: maps[i]['attendanceStatus'],
        sitUpReps: maps[i]['sitUpReps'],
        broadJumpCm: maps[i]['broadJumpCm'],
        sitAndReachCm: maps[i]['sitAndReachCm'],
        pullUpReps: maps[i]['pullUpReps'],
        shuttleRunSec: maps[i]['shuttleRunSec'],
        runTime: maps[i]['runTime'],
        pftTestDate: maps[i]['pftTestDate'],
      );
    });
  }


  // Method to fetch specific CSV data by ID from the database
  Future<CsvData?> getCsvDataById(int id, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CsvData(
        no: maps[0]['no'],
        name: maps[0]['name'],
        id: maps[0]['id'],
        classVal: maps[0]['class'],
        gender: maps[0]['gender'],
        dob: maps[0]['dob'],
        attendanceStatus: maps[0]['attendanceStatus'],
        sitUpReps: maps[0]['sitUpReps'],
        broadJumpCm: maps[0]['broadJumpCm'],
        sitAndReachCm: maps[0]['sitAndReachCm'],
        pullUpReps: maps[0]['pullUpReps'],
        shuttleRunSec: maps[0]['shuttleRunSec'],
        runTime: maps[0]['runTime'],
        pftTestDate: maps[0]['pftTestDate'],
      );
    }
    return null;
  }


  Future<Map<String, List<CsvData>>> getCsvDataGroupedByClass(int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    final List<Map<String, dynamic>> maps = await db.query(tableName);

    Map<String, List<CsvData>> groupedData = {};

    for (var map in maps) {
      String classVal = map['class'];
      CsvData data = CsvData(
        no: map['no'],
        name: map['name'],
        id: map['id'],
        classVal: map['class'],
        gender: map['gender'],
        dob: map['dob'],
        attendanceStatus: map['attendanceStatus'],
        sitUpReps: map['sitUpReps'],
        broadJumpCm: map['broadJumpCm'],
        sitAndReachCm: map['sitAndReachCm'],
        pullUpReps: map['pullUpReps'],
        shuttleRunSec: map['shuttleRunSec'],
        runTime: map['runTime'],
        pftTestDate: map['pftTestDate'],
      );

      if (groupedData.containsKey(classVal)) {
        groupedData[classVal]!.add(data);
      } else {
        groupedData[classVal] = [data];
      }
    }

    return groupedData;
  }


  Future<bool> isTableEmpty(int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) FROM $tableName');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count == 0;
  }

  Future<int> updateSitUpReps(int regNo, int reps, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    return await db.update(
      tableName,
      {'sitUpReps': reps},
      where: 'id = ?',
      whereArgs: [regNo],
    );
  }

  Future<int> updateBroadJumpDistance(int regNo, int distance, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    return await db.update(
      tableName,
      {'broadJumpCm': distance},
      where: 'id = ?',
      whereArgs: [regNo],
    );
  }

  Future<int> updateSitAndReachReps(int regNo, int reps, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    return await db.update(
      tableName,
      {'sitAndReachCm': reps},
      where: 'id = ?',
      whereArgs: [regNo],
    );
  }

  Future<int> updatePullUpReps(int regNo, int reps, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    return await db.update(
      tableName,
      {'pullUpReps': reps},
      where: 'id = ?',
      whereArgs: [regNo],
    );
  }

  Future<int> updateShuttleRunSec(int regNo, double seconds, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    return await db.update(
      tableName,
      {'shuttleRunSec': seconds},
      where: 'id = ?',
      whereArgs: [regNo],
    );
  }

  Future<int> updateKmRun(int regNo, int seconds, int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    return await db.update(
      tableName,
      {'runTime': seconds},
      where: 'id = ?',
      whereArgs: [regNo],
    );
  }

  Future<void> saveStudents(List<Student> students,int tableType) async {
    final db = await instance.database;
    final tableName = _getTableName(tableType);
    for (var student in students) {
      await db.update(
        tableName,
        {
          'runTime': student.runTime,
        },
        where: 'id = ?',
        whereArgs: [student.regNo],
      );
    }
  }

  Future<bool> isDatabaseEmpty() async {
    final db = await instance.database;
    final tables = ['student', 'mock_student']; // Add other tables if any
    for (var table in tables) {
      final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) FROM $table');
      int count = Sqflite.firstIntValue(result) ?? 0;
      if (count > 0) {
        return false; // If any table has data, the database is not empty
      }
    }
    return true; // All tables are empty
  }

  // Method to clear the database
  Future<bool> clearDatabase() async {
    final db = await instance.database;
    final tables = ['student', 'mock_student']; // Add other tables if any
    for (var table in tables) {
      await db.delete(table);
    }
    return true;
  }
}
