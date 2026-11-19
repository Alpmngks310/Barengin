import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_config.dart';
import 'token_store.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors});
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  String get firstFieldError {
    if (errors == null || errors!.isEmpty) return message;
    final first = errors!.values.first;
    if (first is List && first.isNotEmpty) return first.first.toString();
    return first.toString();
  }

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({TokenStore? tokenStore, http.Client? client})
    : tokenStore = tokenStore ?? TokenStore(),
      _client = client ?? http.Client();

  final TokenStore tokenStore;
  final http.Client _client;
  VoidCallback? onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query == null || query.isEmpty) return base;
    final values = <String, String>{};
    query.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        values[key] = value.toString();
      }
    });
    return base.replace(queryParameters: values);
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await tokenStore.read();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) {
    return _send('GET', path, query: query, auth: auth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send('PUT', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) {
    return _send('DELETE', path, body: body, auth: auth);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    try {
      final uri = _uri(path, query);
      final headers = await _headers(auth: auth);
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 25));
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 25));
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 25));
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: jsonEncode(body ?? {}))
              .timeout(const Duration(seconds: 25));
          break;
        case 'DELETE':
          response = await _client
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(const Duration(seconds: 25));
          break;
        default:
          throw ApiException('Metode request tidak didukung.');
      }
      return await _decode(response, auth: auth);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Server terlalu lama merespons. Coba lagi.');
    } on http.ClientException {
      throw ApiException(
        'Koneksi ke server gagal. Periksa jaringan dan konfigurasi API.',
      );
    } on FormatException {
      throw ApiException('Respons server tidak dapat dibaca.');
    } on Exception catch (error) {
      throw ApiException('Koneksi ke server gagal: $error');
    }
  }

  Future<Map<String, dynamic>> _decode(
    http.Response response, {
    required bool auth,
  }) async {
    dynamic decoded;

    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = <String, dynamic>{'message': 'Respons server bukan JSON.'};
    }

    final map = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode == 401 && auth) {
      await tokenStore.clear();
      onUnauthorized?.call();
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        map['success'] == false) {
      final errors = map['errors'] is Map<String, dynamic>
          ? map['errors'] as Map<String, dynamic>
          : null;

      throw ApiException(
        (map['message'] ?? 'Terjadi kesalahan pada server.').toString(),
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    return map;
  }

  Future<Map<String, dynamic>> uploadAvatar(
    XFile file, {
    required Map<String, String> fields,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw ApiException('File foto kosong atau tidak valid.');
      }

      if (bytes.length > 5 * 1024 * 1024) {
        throw ApiException('Ukuran foto maksimal 5 MB.');
      }
      final request = http.MultipartRequest('POST', _uri('/profile'));
      request.headers['Accept'] = 'application/json';
      final token = await tokenStore.read();
      if (token == null || token.isEmpty) {
        throw ApiException('Sesi pengguna berakhir. Silakan login kembali.');
      }

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['_method'] = 'PATCH';
      request.fields.addAll(fields);
      request.files.add(
        http.MultipartFile.fromBytes('avatar', bytes, filename: file.name),
      );
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamed);
      return await _decode(response, auth: true);
    } on TimeoutException {
      throw ApiException('Upload foto terlalu lama. Coba lagi.');
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException('Upload foto gagal: $error');
    }
  }
}
