import 'package:flutter/foundation.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/services/rule_engine.dart';
import '../../../shared/models/rule_model.dart';

class RuleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RuleEngine _engine = RuleEngine.instance;

  List<RuleModel> _rules = [];
  bool _isLoading = false;
  String? _error;

  List<RuleModel> get rules => _rules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCount => _rules.where((r) => r.isActive).length;

  Future<void> loadRules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rules = await _db.getAllRules();
      await _engine.reloadRules();
    } catch (e) {
      _error = 'Failed to load automations: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveRule(RuleModel rule) async {
    try {
      final existing = await _db.getRuleById(rule.id);
      if (existing != null) {
        await _db.updateRule(rule);
      } else {
        await _db.insertRule(rule);
      }
      await loadRules();
      return true;
    } catch (e) {
      _error = 'Failed to save automation: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleRule(String id, bool isActive) async {
    try {
      await _db.toggleRuleStatus(id, isActive);
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
      await _db.deleteRule(id);
      await loadRules();
      return true;
    } catch (e) {
      _error = 'Failed to delete automation: $e';
      notifyListeners();
      return false;
    }
  }
}
