import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/models/rule_model.dart';
import '../../shared/models/geofence_state.dart';
import '../../shared/models/history_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const String _webRulesKey = 'geobuzz_web_rules_v1';
  static const String _webHistoryKey = 'geobuzz_web_history_v1';
  static const String _webStatesKey = 'geobuzz_web_states_v1';

  // Web in-memory fallback cache
  final List<RuleModel> _webRules = [];
  final Map<String, GeofenceState> _webStates = {};
  final List<HistoryItem> _webHistory = [];
  final Map<String, String> _webDeviceState = {};
  bool _webLoaded = false;

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

  // =================== WEB PERSISTENCE HELPERS ===================
  Future<void> _ensureWebLoaded() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesStr = prefs.getString(_webRulesKey);
      if (rulesStr != null && rulesStr.isNotEmpty) {
        final list = jsonDecode(rulesStr) as List;
        _webRules.clear();
        for (final item in list) {
          try {
            _webRules.add(RuleModel.fromMap(Map<String, dynamic>.from(item)));
          } catch (itemErr) {
            debugPrint('Failed to parse cached rule: $itemErr');
          }
        }
      }

      final historyStr = prefs.getString(_webHistoryKey);
      if (historyStr != null && historyStr.isNotEmpty) {
        final list = jsonDecode(historyStr) as List;
        _webHistory.clear();
        for (final item in list) {
          try {
            _webHistory.add(HistoryItem.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      _webLoaded = true;
    } catch (e) {
      debugPrint('Error loading web storage: $e');
    }
  }

  Future<void> _persistWebRules() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webRules.map((r) => r.toMap()).toList();
      await prefs.setString(_webRulesKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting web rules: $e');
    }
  }

  Future<void> _persistWebHistory() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webHistory.map((h) => h.toMap()).toList();
      await prefs.setString(_webHistoryKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Error persisting web history: $e');
    }
  }

  // =================== RULES CRUD ===================
  Future<int> insertRule(RuleModel rule) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webRules.removeWhere((r) => r.id == rule.id);
      _webRules.insert(0, rule);
      await _persistWebRules();
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
      await _ensureWebLoaded();
      return List.from(_webRules);
    }
    final db = (await database)!;
    final result = await db.query('rules', orderBy: 'createdAt DESC');
    return result.map((json) => RuleModel.fromMap(json)).toList();
  }

  Future<List<RuleModel>> getActiveRules() async {
    if (kIsWeb) {
      await _ensureWebLoaded();
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
      await _ensureWebLoaded();
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
      await _ensureWebLoaded();
      final index = _webRules.indexWhere((r) => r.id == rule.id);
      if (index != -1) {
        _webRules[index] = rule;
      } else {
        _webRules.insert(0, rule);
      }
      await _persistWebRules();
      return 1;
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
      await _ensureWebLoaded();
      _webRules.removeWhere((r) => r.id == id);
      _webStates.remove(id);
      await _persistWebRules();
      return 1;
    }
    final db = (await database)!;
    await deleteGeofenceState(id);
    return await db.delete(
      'rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleRuleStatus(String id, bool isActive) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      final index = _webRules.indexWhere((r) => r.id == id);
      if (index != -1) {
        final r = _webRules[index];
        _webRules[index] = r.copyWith(isActive: isActive, updatedAt: DateTime.now());
        await _persistWebRules();
      }
      return 1;
    }
    final db = (await database)!;
    return await db.update(
      'rules',
      {'isActive': isActive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =================== GEOFENCE STATES ===================
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
    final maps = await db.query('geofence_states');
    final result = <String, GeofenceState>{};
    for (final map in maps) {
      final state = GeofenceState.fromMap(map);
      result[state.ruleId] = state;
    }
    return result;
  }

  Future<int> deleteGeofenceState(String ruleId) async {
    if (kIsWeb) {
      _webStates.remove(ruleId);
      return 1;
    }
    final db = (await database)!;
    return await db.delete(
      'geofence_states',
      where: 'ruleId = ?',
      whereArgs: [ruleId],
    );
  }

  // =================== HISTORY CRUD ===================
  Future<int> insertHistory(HistoryItem item) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      _webHistory.insert(0, item);
      await _persistWebHistory();
      return 1;
    }
    final db = (await database)!;
    return await db.insert('history', item.toMap());
  }

  Future<List<HistoryItem>> getAllHistory({int limit = 50, int offset = 0}) async {
    if (kIsWeb) {
      await _ensureWebLoaded();
      return _webHistory.skip(offset).take(limit).toList();
    }
    final db = (await database)!;
    final result = await db.query(
      'history',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => HistoryItem.fromMap(json)).toList();
  }

  Future<int> clearHistory() async {
    if (kIsWeb) {
      _webHistory.clear();
      await _persistWebHistory();
      return 1;
    }
    final db = (await database)!;
    return await db.delete('history');
  }

  // =================== DEVICE STATE KV ===================
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
