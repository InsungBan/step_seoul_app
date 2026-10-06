import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/session_service.dart';

const customerApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.10.40:8000',
);

final _listingVariantSuffix = RegExp(
  r'_(m|f|u)_([0-9]+)_([0-9]+)$',
  caseSensitive: false,
);

List<CustomerShoe> groupShoeSizeVariants(Iterable<CustomerShoe> shoes) {
  final grouped = <String, CustomerShoe>{};
  for (final shoe in shoes) {
    final key = _listingGroupKey(shoe.id);
    final current = grouped[key];
    if (current == null ||
        _listingRepresentativeRank(shoe) >
            _listingRepresentativeRank(current)) {
      grouped[key] = shoe;
    }
  }
  return grouped.values.toList();
}

String _listingGroupKey(String shoeId) {
  final suffix = _listingVariantSuffix.firstMatch(shoeId);
  if (suffix == null) return shoeId.toLowerCase();
  final productAndColor = shoeId.substring(0, suffix.start);
  final gender = suffix.group(1)!.toLowerCase();
  return '${productAndColor}_$gender'.toLowerCase();
}

int _listingRepresentativeRank(CustomerShoe shoe) {
  final suffix = _listingVariantSuffix.firstMatch(shoe.id);
  final size = int.tryParse(suffix?.group(2) ?? '');
  return (shoe.stock > 0 ? 2 : 0) + (size == 280 ? 1 : 0);
}

class CustomerHomeService {
  CustomerHomeService({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  Future<CustomerHomeData> loadHome({
    String query = '',
    String? category,
  }) async {
    final userId = await _currentUserId();
    final selectedStoreId = await SessionService.instance.readSelectedStoreId(
      userId,
    );
    final results = await Future.wait([
      _searchShoes(query: query, category: category),
      _records('/shoe/select'),
      _records('/store/select'),
      _records('/cart/select/user/$userId'),
      _records('/purchase/select/user/$userId'),
    ]);

    final shoes = groupShoeSizeVariants(results[0].map(CustomerShoe.fromJson));
    final allShoes = results[1].map(CustomerShoe.fromJson).toList();
    final stores = results[2].map(CustomerStore.fromJson).toList();
    final selectedStore =
        _storeById(stores, selectedStoreId) ??
        (stores.isEmpty ? null : stores.first);
    final purchases = results[4];
    final shipments = await Future.wait(
      purchases.map((purchase) {
        final shoeId = purchase['shoe_shoe_id']?.toString() ?? '';
        return shoeId.isEmpty
            ? Future.value(<Map<String, dynamic>>[])
            : _records('/shipment/select/shoe/$shoeId');
      }),
    );

    // Order information must remain complete even while the recommendation
    // section is filtered by a search word or category.
    final shoeById = {for (final shoe in allShoes) shoe.id: shoe};
    final storeById = {for (final store in stores) store.id: store};
    final orders = <CustomerOrder>[];
    for (var index = 0; index < purchases.length; index++) {
      orders.add(
        CustomerOrder.fromJson(
          purchases[index],
          shoe: shoeById[purchases[index]['shoe_shoe_id']?.toString()],
          shipment: shipments[index].isEmpty ? null : shipments[index].last,
          stores: storeById,
        ),
      );
    }
    return CustomerHomeData(
      userId: userId,
      shoes: shoes,
      stores: stores,
      selectedStore: selectedStore,
      cartCount: results[3].length,
      orders: orders,
    );
  }

  Future<List<CustomerStore>> loadStores() async =>
      (await _records('/store/select')).map(CustomerStore.fromJson).toList();

  Future<List<CustomerOrder>> loadOrders() async => (await loadHome()).orders;

  Future<List<Map<String, dynamic>>> _searchShoes({
    required String query,
    String? category,
  }) {
    final parameters = <String, String>{};
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) parameters['query'] = trimmedQuery;
    if (category != null && category.trim().isNotEmpty) {
      parameters['category'] = category.trim();
    }
    final uri = Uri.parse(
      '$customerApiBaseUrl/shoe/search',
    ).replace(queryParameters: parameters.isEmpty ? null : parameters);
    return _recordsUri(uri);
  }

  Future<String> _currentUserId() async {
    final session = await SessionService.instance.readSession();
    if (session == null)
      throw const CustomerHomeException('Sign in is required.');
    return session.userId;
  }

  CustomerStore? _storeById(List<CustomerStore> stores, String? storeId) {
    if (storeId == null) return null;
    for (final store in stores) {
      if (store.id == storeId) return store;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _records(String path) async {
    return _recordsUri(Uri.parse('$customerApiBaseUrl$path'));
  }

  Future<List<Map<String, dynamic>>> _recordsUri(Uri uri) async {
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const CustomerHomeException('Could not load information.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final result = decoded is Map<String, dynamic> ? decoded['result'] : null;
    if (result is! List) {
      throw const CustomerHomeException('The server returned invalid data.');
    }
    return result
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}

class CustomerHomeData {
  const CustomerHomeData({
    required this.userId,
    required this.shoes,
    required this.stores,
    required this.selectedStore,
    required this.cartCount,
    required this.orders,
  });
  final String userId;
  final List<CustomerShoe> shoes;
  final List<CustomerStore> stores;
  final CustomerStore? selectedStore;
  final int cartCount;
  final List<CustomerOrder> orders;
}

class CustomerShoe {
  const CustomerShoe({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.price,
    required this.stock,
  });
  final String id;
  final String name;
  final String category;
  final String? imageUrl;
  final String price;
  final int stock;

  factory CustomerShoe.fromJson(Map<String, dynamic> json) => CustomerShoe(
    id: json['shoe_id']?.toString() ?? '',
    name: json['shoe_name']?.toString().trim().isNotEmpty == true
        ? json['shoe_name'].toString()
        : json['brand_name']?.toString().trim().isNotEmpty == true
        ? json['brand_name'].toString()
        : 'STEP SEOUL',
    category: json['shoe_category']?.toString() ?? '',
    imageUrl: json['shoe_img_url']?.toString().trim().isNotEmpty == true
        ? json['shoe_img_url'].toString()
        : json['shoe_image_url']?.toString(),
    price: json['shoe_price']?.toString() ?? '0',
    stock: int.tryParse(json['stock_quantity']?.toString() ?? '') ?? 0,
  );
}

class CustomerStore {
  const CustomerStore({
    required this.id,
    required this.name,
    required this.district,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });
  final String id;
  final String name;
  final String district;
  final String phone;
  final double? latitude;
  final double? longitude;

  factory CustomerStore.fromJson(Map<String, dynamic> json) => CustomerStore(
    id: json['store_id']?.toString() ?? '',
    name: json['agency_name']?.toString() ?? '',
    district: json['district_name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    latitude: double.tryParse(json['latitude']?.toString() ?? ''),
    longitude: double.tryParse(json['longitude']?.toString() ?? ''),
  );
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.shoe,
    required this.quantity,
    required this.status,
    required this.store,
  });
  final String id;
  final CustomerShoe? shoe;
  final String quantity;
  final String status;
  final CustomerStore? store;

  factory CustomerOrder.fromJson(
    Map<String, dynamic> json, {
    required CustomerShoe? shoe,
    required Map<String, dynamic>? shipment,
    required Map<String, CustomerStore> stores,
  }) {
    final storeId = shipment?['store_store_id']?.toString();
    return CustomerOrder(
      id: json['purchase_id']?.toString() ?? '',
      shoe: shoe,
      quantity: json['quantity']?.toString() ?? '1',
      status: shipment?['delivery_status']?.toString() ?? 'Preparing pickup',
      store: storeId == null ? null : stores[storeId],
    );
  }
}

class CustomerHomeException implements Exception {
  const CustomerHomeException(this.message);
  final String message;
}
