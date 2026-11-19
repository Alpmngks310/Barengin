import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../core/api_client.dart';
import '../core/token_store.dart';
import '../models/barengin_models.dart';

class SessionController extends ChangeNotifier {
  SessionController() : tokenStore = TokenStore(), api = ApiClient();

  final TokenStore tokenStore;
  final ApiClient api;
  AppUser? user;
  bool isBooting = true;
  bool isBusy = false;
  String? lastMessage;

  Future<void> restore() async {
    api.onUnauthorized = _expireSession;

    try {
      final token = await tokenStore.read();

      if (token != null && token.isNotEmpty) {
        try {
          final response = await api.get('/me');

          user = AppUser.fromJson(
            Map<String, dynamic>.from(response['data'] as Map),
          );
        } on ApiException catch (error) {
          user = null;

          if (error.statusCode == 401) {
            await tokenStore.clear();
          } else if (error.statusCode == null) {
            lastMessage =
                'Tidak dapat terhubung ke server. Periksa koneksi internet.';
          }
        } catch (_) {
          user = null;
        }
      }
    } catch (_) {
      user = null;
      lastMessage = 'Gagal memulihkan sesi pengguna.';
    } finally {
      isBooting = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    isBusy = true;
    lastMessage = null;
    notifyListeners();
    try {
      final response = await api.post(
        '/auth/login',
        auth: false,
        body: {
          'email': email.trim(),
          'password': password,
          'device_name': 'Barengin Flutter',
        },
      );
      await _saveSession(response);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String username,
    required String email,
    required String password,
    required bool adultConfirmed,
    required bool termsAccepted,
    required bool privacyAccepted,
  }) async {
    isBusy = true;
    lastMessage = null;
    notifyListeners();

    try {
      final response = await api.post(
        '/auth/register',
        auth: false,
        body: {
          'name': name.trim(),
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': password,
          'adult_confirmed': adultConfirmed,
          'terms_accepted': termsAccepted,
          'privacy_accepted': privacyAccepted,
          'device_name': 'Barengin Flutter',
        },
      );

      await _saveSession(response);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _saveSession(Map<String, dynamic> response) async {
    final data = Map<String, dynamic>.from(response['data'] as Map);
    final token = (data['token'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException('Token tidak ditemukan pada respons server.');
    }
    await tokenStore.write(token);
    user = AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  Future<void> reloadUser() async {
    final response = await api.get('/me');
    user = AppUser.fromJson(Map<String, dynamic>.from(response['data'] as Map));
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } finally {
      await tokenStore.clear();
      user = null;
      notifyListeners();
    }
  }

  void _expireSession() {
    user = null;
    notifyListeners();
  }

  Future<List<Category>> getCategories() async {
    final response = await api.get('/categories', auth: false);
    final list = response['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Activity>> getActivities({Map<String, dynamic>? query}) async {
    final response = await api.get(
      '/activities',
      query: query,
      auth: user != null,
    );
    final list = response['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Activity> getActivity(int id) async {
    final response = await api.get('/activities/$id', auth: user != null);
    return Activity.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<List<Activity>> getMyActivities({String role = 'all'}) async {
    final response = await api.get(
      '/my/activities',
      query: {'role': role, 'per_page': 30},
    );
    final list = response['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<JoinRequest>> getMyJoinRequests() async {
    final response = await api.get(
      '/my/join-requests',
      query: {'per_page': 30},
    );
    final list = response['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => JoinRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<JoinRequest>> getJoinRequests(int activityId) async {
    final response = await api.get(
      '/activities/$activityId/join-requests',
      query: {'per_page': 30},
    );
    final list = response['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => JoinRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> cancelMyJoinRequest(int requestId) async {
    await api.delete('/my/join-requests/$requestId');
  }

  Future<JoinRequest?> getLatestJoinRequestForActivity(int activityId) async {
    final requests = await getMyJoinRequests();
    for (final request in requests) {
      if (request.activityId == activityId) return request;
    }
    return null;
  }

  Future<JoinRequest> submitJoinRequest(int activityId, String message) async {
    final response = await api.post(
      '/activities/$activityId/join-requests',
      body: {'message': message},
    );
    return JoinRequest.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<void> decideJoinRequest(int requestId, String status) async {
    await api.patch(
      '/join-requests/$requestId/decision',
      body: {'status': status},
    );
  }

  Future<void> toggleFavorite(int activityId, bool currentlyFavorited) async {
    if (currentlyFavorited) {
      await api.delete('/activities/$activityId/favorite');
    } else {
      await api.post('/activities/$activityId/favorite');
    }
  }

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> body) async {
    final response = await api.post('/activities', body: body);
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<Map<String, dynamic>> updateActivity(
    int id,
    Map<String, dynamic> body,
  ) async {
    final response = await api.patch('/activities/$id', body: body);
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<void> publishActivity(int id) async {
    await api.post('/activities/$id/publish');
  }

  Future<void> startActivity(int id) async {
    await api.post('/activities/$id/start');
  }

  Future<void> completeActivity(int id) async {
    await api.post('/activities/$id/complete');
  }

  Future<void> cancelActivity(int id, {String? reason}) async {
    await api.post(
      '/activities/$id/cancel',
      body: {'cancellation_reason': reason},
    );
  }

  Future<void> leaveActivity(int id) async {
    await api.post('/activities/$id/leave');
  }

  Future<List<dynamic>> getParticipants(int activityId) async {
    final response = await api.get('/activities/$activityId/participants');
    return response['data'] as List? ?? const [];
  }

  Future<void> removeParticipant(int activityId, int userId) async {
    await api.delete('/activities/$activityId/participants/$userId');
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    await api.patch('/profile', body: body);
    await reloadUser();
  }

  Future<void> updateInterests(List<int> ids) async {
    await api.put('/profile/interests', body: {'category_ids': ids});
    await reloadUser();
  }

  Future<void> report({
    int? userId,
    int? activityId,
    required String reason,
    String? details,
  }) async {
    await api.post(
      '/reports',
      body: {
        'reported_user_id': ?userId,
        'activity_id': ?activityId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }

  Future<List<dynamic>> getBlockedUsers() async {
    final response = await api.get('/my/blocked-users');
    return response['data'] as List? ?? const [];
  }

  Future<void> blockUser(int userId) async {
    await api.post('/users/$userId/block');
  }

  Future<void> unblockUser(int userId) async {
    await api.delete('/users/$userId/block');
  }

  Future<List<Activity>> getMyFavorites() async {
    final response = await api.get('/my/favorites');
    final list = response['data'] as List? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Activity.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
