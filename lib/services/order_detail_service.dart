import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';

class OrderDetailService {
  Future<Map<String, dynamic>> load(String orderId) async {
    final session = await SessionService.instance.readSession();
    if (session == null) {
      throw const OrderDetailException('Sign in is required.');
    }
    final response = await http
        .get(
          Uri.parse(
            '$customerApiBaseUrl/checkout/order/${session.userId}/$orderId',
          ),
        )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || body is! Map || body['result'] is! Map) {
      throw OrderDetailException(
        body is Map
            ? body['detail']?.toString() ?? 'Could not load order.'
            : 'Could not load order.',
      );
    }
    return Map<String, dynamic>.from(body['result'] as Map);
  }
}

class OrderDetailException implements Exception {
  const OrderDetailException(this.message);
  final String message;
}
