import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';

class RefundRequestService {
  Future<RefundRequestResult> submit({
    required String orderId,
    required String shoeId,
    required int quantity,
    required String reason,
    String? detailReason,
  }) async {
    final session = await SessionService.instance.readSession();
    if (session == null) {
      throw const RefundRequestException('Sign in is required.');
    }
    final response = await http
        .post(
          Uri.parse('$customerApiBaseUrl/refund/request'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': session.userId,
            'order_id': orderId,
            'shoe_id': shoeId,
            'quantity': quantity,
            'reason': reason,
            'detail_reason': detailReason,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || body is! Map || body['result'] is! Map) {
      throw RefundRequestException(
        body is Map
            ? body['detail']?.toString() ?? 'Could not request a refund.'
            : 'Could not request a refund.',
      );
    }
    return RefundRequestResult.fromJson(
      Map<String, dynamic>.from(body['result'] as Map),
    );
  }
}

class RefundRequestResult {
  const RefundRequestResult({required this.id, required this.amount});
  final String id;
  final int amount;

  factory RefundRequestResult.fromJson(Map<String, dynamic> json) =>
      RefundRequestResult(
        id: json['refund_id']?.toString() ?? '',
        amount: int.tryParse(json['amount']?.toString() ?? '') ?? 0,
      );
}

class RefundRequestException implements Exception {
  const RefundRequestException(this.message);
  final String message;
}
