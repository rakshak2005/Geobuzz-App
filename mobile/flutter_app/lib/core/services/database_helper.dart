import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../shared/models/rule_model.dart';
import '../../shared/models/geofence_state.dart';
import '../../shared/models/history_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Web in-memory fallback cache
  final List<RuleModel> _webRules = [];
  final Map<String, GeofenceState> _webStates = {};
  final List<HistoryItem> _webHistory = [];
  final Map<String, String> _webDeviceState = {};

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('geobuzz_local.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rules (
        id TEXT PRIMARY KEY,
        userId TEXT,
        name TEXT NOT NULL,
        location_json TEXT NOT NULL,
        radius REAL NOT NULL,
        trigger_json TEXT NOT NULL,
        action_json TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        isSynced INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE geofence_states (
        ruleId TEXT PRIMARY KEY,
        status TEXT NOT NULL,
        lastDistance REAL,
        lastEvaluatedAt TEXT NOT NULL,
        lastTriggeredAt TEXT,
        lastTriggeredEvent TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id TEXT PRIMARY KEY,
        ruleId TEXT,
        ruleName TEXT NOT NULL,
        locationName TEXT NOT NULL,
        triggerType TEXT NOT NULL,
        actionType TEXT NOT NULL,
        status TEXT NOT NULL,
        message TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE device_state (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // =================== RULES CRUD ===================
  Future<int> insertRule(RuleModel rule) async {
    if (kIsWeb) {
      _webRules.removeWhere((r) => r.id == rule.id);
      _webRules.insert(0, rule);
      return 1;
    }
    final db = (await database)!;
    return await db.insert(
      'rules',
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RuleModel>> getAllRules() async {
    if (kIsWeb) {
      return List.from(_webRules);
    }
    final db = (await database)!;
    final result = await db.query('rules', orderBy: 'createdAt DESC');
    return result.map((json) => RuleModel.fromMap(json)).toList();
  }

  Future<List<RuleModel>> getActiveRules() async {
    if (kIsWeb) {
      return _webRules.where((r) => r.isActive).toList();
    }
    final db = (await database)!;
    final result = await db.query(
      'rules',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => RuleModel.fromMap(json)).toList();
  }

  Future<RuleModel?> getRuleById(String id) async {
    if (kIsWeb) {
      try {
        return _webRules.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }
    final db = (await database)!;
    final maps = await db.query(
      'rules',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return RuleModel.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRule(RuleModel rule) async {
    if (kIsWeb) {
      final index = _webRules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _webRules[index] = rule;
        return 1;
      }
      return 0;
    }
    final db = (await database)!;
    return await db.update(
      'rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRule(String id) async {
    if (kIsWeb) {
      _webRules.removeWhere((r) => r.id == id);
      _webStates.remove(id);
      return 1;
    }
    final db = (await database)!;
    await db.delete('geofence_states', where: 'ruleId = ?', whereArgs: [id]);
    return await db.delete('rules', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> toggleRuleStatus(String id, bool isActive) async {
    if (kIsWeb) {
      final index = _webRules.indexWhere((r) => r.id == id);
      if (index != -1) {
        _webRules[index] = _webRules[index].copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
        return 1;
      }
      return 0;
    }
    final db = (await database)!;
    return await db.update(
      'rules',
      {'isActive': isActive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================== GEOFENCE STATE CRUD ===================
  Future<void> saveGeofenceState(GeofenceState state) async {
    if (kIsWeb) {
      _webStates[state.ruleId] = state;
      return;
    }
    final db = (await database)!;
    await db.insert(
      'geofence_states',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<GeofenceState?> getGeofenceState(String ruleId) async {
    if (kIsWeb) {
      return _webStates[ruleId];
    }
    final db = (await database)!;
    final maps = await db.query(
      'geofence_states',
      where: 'ruleId = ?',
      whereArgs: [ruleId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return GeofenceState.fromMap(maps.first);
    }
    return null;
  }

  Future<Map<String, GeofenceState>> getAllGeofenceStates() async {
    if (kIsWeb) {
      return Map.from(_webStates);
    }
    final db = (await database)!;
    final result = await db.query('geofence_states');
    final map = <String, GeofenceState>{};
    for (var row in result) {
      final state = GeofenceState.fromMap(row);
      map[state.ruleId] = state;
    }
    return map;
  }

  // =================== HISTORY CRUD ===================
  Future<int> insertHistory(HistoryItem item) async {
    if (kIsWeb) {
      _webHistory.insert(0, item);
      return 1;
    }
    final db = (await database)!;
    return await db.insert(
      'history',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HistoryItem>> getAllHistory({int limit = 50}) async {
    if (kIsWeb) {
      return _webHistory.take(limit).toList();
    }
    final db = (await database)!;
    final result = await db.query(
      'history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((json) => HistoryItem.fromMap(json)).toList();
  }

  Future<int> clearHistory() async {
    if (kIsWeb) {
      _webHistory.clear();
      return 1;
    }
    final db = (await database)!;
    return await db.delete('history');
  }

  // =================== KEY VALUE STORE ===================
  Future<void> setDeviceState(String key, String value) async {
    if (kIsWeb) {
      _webDeviceState[key] = value;
      return;
    }
    final db = (await database)!;
    await db.insert(
      'device_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getDeviceState(String key) async {
    if (kIsWeb) {
      return _webDeviceState[key];
    }
    final db = (await database)!;
    final maps = await db.query(
      'device_state',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }
}
