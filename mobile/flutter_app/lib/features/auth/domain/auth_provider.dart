import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'jwt_auth_token';
  static const String _userKey = 'auth_user_name';
  static const String _emailKey = 'auth_user_email';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final Dio _dio;

  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  String? _token;
  bool _isLoading = false;
  String? _authError;

  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get authError => _authError;

  AuthProvider() {
    final baseUrl = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
  }

  Future<void> checkAuthStatus() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(_tokenKey);
        _userName = prefs.getString(_userKey);
        _userEmail = prefs.getString(_emailKey);
      } else {
        _token = await _storage.read(key: _tokenKey);
        _userName = await _storage.read(key: _userKey);
        _userEmail = await _storage.read(key: _emailKey);
      }
      _isAuthenticated = _token != null && _token!.isNotEmpty;
    } catch (_) {
      _token = null;
      _userName = null;
      _userEmail = null;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> _persistAuth(String token, String userName, String email) async {
    _token = token;
    _userName = userName;
    _userEmail = email;
    _isAuthenticated = true;

    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userKey, userName);
        await prefs.setString(_emailKey, email);
      } else {
        await _storage.write(key: _tokenKey, value: token);
        await _storage.write(key: _userKey, value: userName);
        await _storage.write(key: _emailKey, value: email);
      }
    } catch (_) {}
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'];
        final user = response.data['user'];
        final name = user?['name'] ?? email.split('@').first;
        final userEmail = user?['email'] ?? email;

        await _persistAuth(token, name, userEmail);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = response.data['message'] ?? 'Invalid credentials';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        _authError = e.response?.data['message'] ?? 'Invalid email or password';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        _authError = 'Cannot connect to authentication server. Please check connection.';
      } else {
        _authError = 'Authentication failed. Please check credentials.';
      }
    } catch (e) {
      _authError = 'An error occurred: $e';
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
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });

      if (response.statusCode == 201 && response.data['token'] != null) {
        final token = response.data['token'];
        final user = response.data['user'];
        final userName = user?['name'] ?? name;
        final userEmail = user?['email'] ?? email;

        await _persistAuth(token, userName, userEmail);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _authError = response.data['message'] ?? 'Failed to register account';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        _authError = e.response?.data['message'] ?? 'Registration failed';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.connectionError) {
        _authError = 'Cannot connect to authentication server. Please try again.';
      } else {
        _authError = 'Failed to register account. Please try again.';
      }
    } catch (e) {
      _authError = 'An error occurred during registration: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_tokenKey);
        await prefs.remove(_userKey);
        await prefs.remove(_emailKey);
      } else {
        await _storage.delete(key: _tokenKey);
        await _storage.delete(key: _userKey);
        await _storage.delete(key: _emailKey);
      }
    } catch (_) {}
    _token = null;
    _userName = null;
    _userEmail = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
