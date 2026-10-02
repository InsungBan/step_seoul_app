import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';

class CheckoutService {
  CheckoutService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<CheckoutReceipt> complete({
    required List<CheckoutLineItem> items,
    required CustomerStore store,
    required String paymentMethod,
    required bool clearCart,
  }) async {
    final session = await SessionService.instance.readSession();
    if (session == null) throw const CheckoutException('Sign in is required.');
    final response = await _client
        .post(
          Uri.parse('$customerApiBaseUrl/checkout/complete'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': session.userId,
            'store_id': store.id,
            'payment_method': paymentMethod,
            'clear_cart': clearCart,
            'items': items
                .map(
                  (item) => {
                    'shoe_id': item.shoe.id,
                    'quantity': item.quantity,
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 15));
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || decoded is! Map<String, dynamic>) {
      final detail = decoded is Map ? decoded['detail']?.toString() : null;
      throw CheckoutException(detail ?? 'Payment could not be completed.');
    }
    final result = decoded['result'];
    if (result is! Map) {
      throw const CheckoutException('Invalid checkout response.');
    }
    return CheckoutReceipt.fromJson(Map<String, dynamic>.from(result));
  }
}

class CheckoutReceipt {
  const CheckoutReceipt({
    required this.orderId,
    required this.paidAt,
    required this.total,
    required this.store,
    required this.items,
  });
  final String orderId;
  final String paidAt;
  final int total;
  final CustomerStore store;
  final List<CheckoutReceiptItem> items;

  factory CheckoutReceipt.fromJson(Map<String, dynamic> json) {
    final storeJson = json['store'] is Map
        ? Map<String, dynamic>.from(json['store'] as Map)
        : <String, dynamic>{};
    final itemRows = json['items'] is List ? json['items'] as List : const [];
    return CheckoutReceipt(
      orderId: json['order_id']?.toString() ?? '',
      paidAt: json['paid_at']?.toString() ?? '',
      total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      store: CustomerStore(
        id: storeJson['store_id']?.toString() ?? '',
        name: storeJson['name']?.toString() ?? '',
        district: storeJson['district']?.toString() ?? '',
        phone: '',
        latitude: null,
        longitude: null,
      ),
      items: itemRows
          .whereType<Map>()
          .map(
            (row) =>
                CheckoutReceiptItem.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList(),
    );
  }
}

class CheckoutReceiptItem {
  const CheckoutReceiptItem({
    required this.shoeId,
    required this.name,
    required this.quantity,
    required this.price,
  });
  final String shoeId;
  final String name;
  final int quantity;
  final int price;

  factory CheckoutReceiptItem.fromJson(Map<String, dynamic> json) =>
      CheckoutReceiptItem(
        shoeId: json['shoe_id']?.toString() ?? '',
        name: json['shoe_name']?.toString() ?? '',
        quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
        price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
      );
}

class CheckoutException implements Exception {
  const CheckoutException(this.message);
  final String message;
}
