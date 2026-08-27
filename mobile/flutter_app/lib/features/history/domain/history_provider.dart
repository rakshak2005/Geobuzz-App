import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/services/database_helper.dart';
import '../../../shared/models/history_item.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  List<HistoryItem> _history = [];
  bool _isLoading = false;
  String _filterType = 'ALL';

  List<HistoryItem> get history {
    if (_filterType == 'ALL') return _history;
    return _history.where((h) => h.actionType == _filterType).toList();
  }

  bool get isLoading => _isLoading;
  String get filterType => _filterType;

  HistoryProvider() {
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

  void setFilter(String filter) {
    _filterType = filter;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load local history
      _history = await _db.getAllHistory();

      // 2. Sync from Neon PostgreSQL
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        try {
          final res = await _dio.get(
            '/history',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

          if (res.statusCode == 200 && res.data['data'] != null) {
            final List cloudList = res.data['data'];
            for (final item in cloudList) {
              await _db.insertHistory(HistoryItem(
                id: item['id'] ?? '',
                ruleId: item['rule_id'],
                ruleName: item['rule_name'] ?? 'Unnamed',
                locationName: item['location_name'] ?? '',
                triggerType: item['trigger_type'] ?? 'ENTER',
                actionType: item['action_type'] ?? 'ALARM',
                status: item['status'] ?? 'SUCCESS',
                message: item['message'] ?? '',
                timestamp: DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
              ));
            }
            _history = await _db.getAllHistory();
          }
        } catch (cloudErr) {
          debugPrint('Cloud history sync skipped: $cloudErr');
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAllHistory() async {
    await _db.clearHistory();

    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _dio.delete(
          '/history',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}
    }

    await loadHistory();
  }
}
