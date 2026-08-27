import 'package:flutter/foundation.dart';
import '../../../core/services/database_helper.dart';
import '../../../shared/models/history_item.dart';

class HistoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<HistoryItem> _history = [];
  bool _isLoading = false;
  String _filterType = 'ALL';

  List<HistoryItem> get history {
    if (_filterType == 'ALL') return _history;
    return _history.where((h) => h.actionType == _filterType).toList();
  }

  bool get isLoading => _isLoading;
  String get filterType => _filterType;

  void setFilter(String filter) {
    _filterType = filter;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _db.getAllHistory();
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAllHistory() async {
    await _db.clearHistory();
    await loadHistory();
  }
}
