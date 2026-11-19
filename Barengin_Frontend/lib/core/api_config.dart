import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;

    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://192.168.1.10:8000/api';
      }
    }

    return 'http://127.0.0.1:8000/api';
  }
}
