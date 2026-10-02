import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';

class ProfileService {
  Future<CustomerProfile> load() async {
    final session = await _session();
    final response = await http
        .get(Uri.parse('$customerApiBaseUrl/user/profile/${session.userId}'))
        .timeout(const Duration(seconds: 10));
    return _profileFrom(response);
  }

  Future<CustomerProfile> save({
    required String name,
    required String phone,
    String? currentPassword,
    String? newPassword,
  }) async {
    final session = await _session();
    final response = await http
        .put(
          Uri.parse('$customerApiBaseUrl/user/profile/${session.userId}'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_name': name,
            'user_phone': phone,
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return _profileFrom(response);
  }

  Future<AppSession> _session() async {
    final session = await SessionService.instance.readSession();
    if (session == null) throw const ProfileException('Sign in is required.');
    return session;
  }

  CustomerProfile _profileFrom(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || body is! Map || body['result'] is! Map) {
      throw ProfileException(
        body is Map
            ? body['detail']?.toString() ?? 'Could not update profile.'
            : 'Could not update profile.',
      );
    }
    return CustomerProfile.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.joinedAt,
  });
  final String id, name, phone, joinedAt;
  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      CustomerProfile(
        id: json['user_id']?.toString() ?? '',
        name: json['user_name']?.toString() ?? '',
        phone: json['user_phone']?.toString() ?? '',
        joinedAt: json['join_date']?.toString() ?? '',
      );
}

class ProfileException implements Exception {
  const ProfileException(this.message);
  final String message;
}
