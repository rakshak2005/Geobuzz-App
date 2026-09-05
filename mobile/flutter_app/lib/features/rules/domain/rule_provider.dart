import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/services/database_helper.dart';
import '../../../core/services/rule_engine.dart';
import '../../../shared/models/rule_model.dart';

class RuleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RuleEngine _engine = RuleEngine.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late final Dio _dio;

  List<RuleModel> _rules = [];
  bool _isLoading = false;
  String? _error;

  List<RuleModel> get rules => _rules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCount => _rules.where((r) => r.isActive).length;

  RuleProvider() {
    final baseUrl = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<String?> _getToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString('jwt_auth_token');
      } else {
        return await _storage.read(key: 'jwt_auth_token');
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> loadRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Always load from persistent local storage first
      _rules = await _db.getAllRules();
      await _engine.reloadRules();
      notifyListeners();

      // 2. Sync with cloud Neon PostgreSQL if online & authenticated
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        try {
          final res = await _dio.get(
            '/rules',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (res.statusCode == 200 && res.data['data'] != null) {
            final List cloudList = res.data['data'];
            final cloudRules = cloudList.map((j) => RuleModel.fromJson(j)).toList();

            // Merge cloud rules into local storage
            for (final cr in cloudRules) {
              await _db.insertRule(cr);
            }

            _rules = await _db.getAllRules();
            await _engine.reloadRules();
          }
        } catch (cloudErr) {
          debugPrint('Cloud sync skipped (using local offline cache): $cloudErr');
        }
      }
    } catch (e) {
      _error = 'Failed to load automations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveRule(RuleModel rule) async {
    try {
      // 1. Immediately save locally to persistent storage
      final existing = await _db.getRuleById(rule.id);
      if (existing != null) {
        await _db.updateRule(rule);
      } else {
        await _db.insertRule(rule);
      }

      // Update in-memory state immediately so UI refreshes without waiting for cloud
      _rules = await _db.getAllRules();
      await _engine.reloadRules();
      notifyListeners();

      // 2. Sync with Neon PostgreSQL API asynchronously
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _dio.post(
            '/rules',
            data: rule.toJson(),
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } catch (syncErr) {
          debugPrint('Cloud rule save error (cached locally): $syncErr');
        }
      }

      return true;
    } catch (e) {
      _error = 'Failed to save automation: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleRule(String id, bool isActive) async {
    try {
      // 1. Toggle locally
      await _db.toggleRuleStatus(id, isActive);

      // 2. Sync with Neon PostgreSQL
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _dio.patch(
            '/rules/$id/toggle',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } catch (syncErr) {
          debugPrint('Cloud toggle sync error: $syncErr');
        }
      }

      await loadRules();
      return true;
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRule(String id) async {
    try {
      // 1. Delete locally
      await _db.deleteRule(id);

      // 2. Delete on cloud Neon PostgreSQL
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        try {
          await _dio.delete(
            '/rules/$id',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } catch (syncErr) {
          debugPrint('Cloud delete sync error: $syncErr');
        }
      }

      await loadRules();
      return true;
    } catch (e) {
      _error = 'Failed to delete automation: $e';
      notifyListeners();
      return false;
    }
  }
}
