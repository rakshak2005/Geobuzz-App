import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _customBaseUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl.endsWith('/api') ? _customBaseUrl : '$_customBaseUrl/api';
    }

    if (kReleaseMode) {
      return 'https://geobuzz-backend.onrender.com/api';
    }

    return kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  }
}
