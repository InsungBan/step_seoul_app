import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';

class CustomerCartService {
  CustomerCartService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  Future<CustomerCartData> loadCart() async {
    final userId = await _userId();
    final results = await Future.wait([
      _records('/cart/select/user/$userId'),
      _records('/shoe/select'),
      _records('/store/select'),
    ]);
    final shoes = {
      for (final shoe in results[1].map(CustomerShoe.fromJson)) shoe.id: shoe,
    };
    final stores = results[2].map(CustomerStore.fromJson).toList();
    final selectedStoreId = await SessionService.instance.readSelectedStoreId(
      userId,
    );
    CustomerStore? selectedStore;
    for (final store in stores) {
      if (store.id == selectedStoreId) {
        selectedStore = store;
        break;
      }
    }
    selectedStore ??= stores.isEmpty ? null : stores.first;
    final idsByShoe = <String, List<String>>{};
    for (final row in results[0]) {
      final shoeId = row['shoe_shoe_id']?.toString() ?? '';
      final cartId = row['cart_id']?.toString() ?? '';
      if (shoeId.isEmpty || cartId.isEmpty) continue;
      idsByShoe.putIfAbsent(shoeId, () => []).add(cartId);
    }
    final items = idsByShoe.entries
        .where((entry) => shoes.containsKey(entry.key))
        .map(
          (entry) =>
              CustomerCartItem(shoe: shoes[entry.key]!, cartIds: entry.value),
        )
        .toList();
    return CustomerCartData(
      userId: userId,
      items: items,
      stores: stores,
      selectedStore: selectedStore,
    );
  }

  Future<void> addShoe(CustomerShoe shoe, {int quantity = 1}) async {
    final userId = await _userId();
    for (var index = 0; index < quantity; index++) {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$customerApiBaseUrl/cart/upload'),
            )
            ..fields['user_user_id'] = userId
            ..fields['shoe_shoe_id'] = shoe.id
            ..fields['cart_id'] =
                'cart_' +
                DateTime.now().microsecondsSinceEpoch.toString() +
                '_' +
                index.toString();
      final response = await request.send().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        throw const CustomerCartException(
          'Could not add the product to the cart.',
        );
      }
    }
  }

  Future<void> removeOne(CustomerCartData data, CustomerCartItem item) async {
    if (item.cartIds.isEmpty) return;
    await _delete(data.userId, item.shoe.id, item.cartIds.last);
  }

  Future<void> removeAll(CustomerCartData data, CustomerCartItem item) async {
    for (final cartId in item.cartIds) {
      await _delete(data.userId, item.shoe.id, cartId);
    }
  }

  Future<void> _delete(String userId, String shoeId, String cartId) async {
    final response = await _client
        .delete(
          Uri.parse('$customerApiBaseUrl/cart/delete/$userId/$shoeId/$cartId'),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const CustomerCartException('Could not remove the cart item.');
    }
  }

  Future<String> _userId() async {
    final session = await SessionService.instance.readSession();
    if (session == null)
      throw const CustomerCartException('Sign in is required.');
    return session.userId;
  }

  Future<List<Map<String, dynamic>>> _records(String path) async {
    final response = await _client
        .get(Uri.parse('$customerApiBaseUrl$path'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const CustomerCartException('Could not load cart information.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final result = decoded is Map<String, dynamic> ? decoded['result'] : null;
    if (result is! List)
      throw const CustomerCartException('Invalid cart data.');
    return result
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class CustomerCartData {
  const CustomerCartData({
    required this.userId,
    required this.items,
    required this.stores,
    required this.selectedStore,
  });
  final String userId;
  final List<CustomerCartItem> items;
  final List<CustomerStore> stores;
  final CustomerStore? selectedStore;

  int get total => items.fold(0, (sum, item) => sum + item.total);
}

class CustomerCartItem {
  const CustomerCartItem({required this.shoe, required this.cartIds});
  final CustomerShoe shoe;
  final List<String> cartIds;
  int get quantity => cartIds.length;
  int get unitPrice =>
      int.tryParse(shoe.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get total => unitPrice * quantity;
}

class CustomerCartException implements Exception {
  const CustomerCartException(this.message);
  final String message;
}
