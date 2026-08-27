import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'jwt_auth_token';
  static const String _userKey = 'auth_user_name';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:5000/api', // Local Android emulator or backend host
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  bool _isAuthenticated = false;
  String? _userName;
  String? _token;
  bool _isLoading = false;
  String? _authError;

  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  Future<void> checkAuthStatus() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(_tokenKey);
        _userName = prefs.getString(_userKey);
      } else {
        _token = await _storage.read(key: _tokenKey);
        _userName = await _storage.read(key: _userKey);
      }
      _isAuthenticated = _token != null && _token!.isNotEmpty;
    } catch (_) {
      _token = null;
      _userName = null;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> _persistAuth(String token, String userName) async {
    _token = token;
    _userName = userName;
    _isAuthenticated = true;

    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, userName);
      } else {
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: userName);
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final name = response.data['user']?['name'] ?? email.split('@').first;
        await _persistAuth(token, name);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Offline fallback: allow offline local usage
      if (email.isNotEmpty && password.length >= 6) {
        final name = email.split('@').first;
        final token = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
        await _persistAuth(token, name);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _authError = 'Authentication failed. Please check credentials.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 && response.data['token'] != null) {
        final token = response.data['token'];
        await _persistAuth(token, name);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Offline fallback
      final token = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
      await _persistAuth(token, name);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> continueAsGuest() async {
    await _persistAuth('guest_session_${DateTime.now().millisecondsSinceEpoch}', 'Explorer');
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_userKey);
      } else {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _userKey);
      }
    } catch (_) {}
    _token = null;
    _userName = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
