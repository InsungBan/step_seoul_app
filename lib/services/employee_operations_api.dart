import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:step_seoul_app/services/api_config.dart';

class EmployeeOperationsApi {
  EmployeeOperationsApi._();
  static final instance = EmployeeOperationsApi._();

  static const _scopeId = 'step-pickup-mysql-v1';
  final http.Client _client = http.Client();

  Uri get _stateUri => Uri.parse(
    ApiConfig.baseUrl + '/employee-operations/state',
  ).replace(queryParameters: {'scope_id': _scopeId});

  Uri get _mysqlSourceUri =>
      Uri.parse(ApiConfig.baseUrl + '/employee-operations/mysql-source');

  Future<Map<String, dynamic>> readState() async {
    final response = await _client
        .get(_mysqlSourceUri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception(
        'MySQL source read failed (' + response.statusCode.toString() + ')',
      );
    }
    final source =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return _buildStateFromMysql(source);
  }

  Future<void> writeState(Map<String, dynamic> state) async {
    final response = await _client
        .put(
          _stateUri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'scope_id': _scopeId, 'state': state}),
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'API state save failed (' + response.statusCode.toString() + ')',
      );
    }
  }

  String _shoeImageValue(Map<String, dynamic> row) {
    final known = _value(row, 'shoe_image_url', 'shoe_image', 'image_url');
    if (known.isNotEmpty) return known;
    for (final entry in row.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value?.toString().trim() ?? '';
      if ((key.contains('image') || key.contains('img')) && value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String _resolveImageUrl(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('//')) return 'https:' + raw;
    final normalized = raw.startsWith('www.') ? 'https://' + raw : raw;
    final parsed = Uri.tryParse(normalized);
    if (parsed == null) return '';
    final base = Uri.parse(ApiConfig.baseUrl);
    if (parsed.hasScheme) {
      if (parsed.scheme != 'http' && parsed.scheme != 'https') return '';
      final host = parsed.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return base
            .replace(
              path: parsed.path,
              query: parsed.hasQuery ? parsed.query : null,
              fragment: parsed.hasFragment ? parsed.fragment : null,
            )
            .toString();
      }
      return parsed.toString();
    }
    return base.resolve(raw.startsWith('/') ? raw : '/$raw').toString();
  }

  Map<String, dynamic> _buildStateFromMysql(Map<String, dynamic> source) {
    final shoeRows = _rows(source, 'products');
    final shipmentRows = _rows(source, 'shipments');
    final receiveRows = _rows(source, 'receipts');
    final returnRows = _rows(source, 'returns');
    final purchaseRows = _rows(source, 'purchases');
    final userRows = _rows(source, 'users');
    final employeeRows = _rows(source, 'employees');
    final storeRows = _rows(source, 'stores');
    final shoesById = <String, Map<String, dynamic>>{
      for (final row in shoeRows) _value(row, 'shoe_id', 'id'): row,
    };
    final usersById = <String, Map<String, dynamic>>{
      for (final row in userRows) _value(row, 'user_id', 'id'): row,
    };
    final employeesById = <String, Map<String, dynamic>>{
      for (final row in employeeRows) _value(row, 'employee_id', 'id'): row,
    };
    final storesById = <String, Map<String, dynamic>>{
      for (final row in storeRows) _value(row, 'store_id', 'id'): row,
    };
    final purchasesByPayment = <String, Map<String, dynamic>>{
      for (final row in purchaseRows)
        if (_value(row, 'payment_id').isNotEmpty)
          _value(row, 'payment_id'): row,
    };
    final soldByShoe = <String, int>{};
    final todaySoldByShoe = <String, int>{};
    for (final row in purchaseRows) {
      final shoeId = _value(row, 'shoe_shoe_id', 'shoe_id');
      final quantity = _intValue(row, 'quantity');
      soldByShoe[shoeId] = (soldByShoe[shoeId] ?? 0) + quantity;
      final date = _dateValue(
        row,
        'purchase_date',
        'payment_date',
        'created_at',
      );
      if (_isToday(date))
        todaySoldByShoe[shoeId] = (todaySoldByShoe[shoeId] ?? 0) + quantity;
    }

    final products = shoeRows.map((row) {
      final id = _value(row, 'shoe_id', 'id');
      final stock = _intValue(row, 'stock_quantity', 'stock');
      final target = _intValue(row, 'standard_stock', 'target_stock');
      final status = stock <= 0
          ? 'outOfStock'
          : target > 0 && stock < target
          ? 'warning'
          : target > 0 && stock > target
          ? 'surplus'
          : 'normal';
      final brand = _value(row, 'shoe_category', 'brand_name', 'category');
      return <String, dynamic>{
        'id': id,
        'name': _value(row, 'shoe_name', 'product_name', 'name').isNotEmpty
            ? _value(row, 'shoe_name', 'product_name', 'name')
            : brand.isNotEmpty
            ? brand
            : id,
        'option': _value(row, 'shoe_option', 'option', 'size', '-'),
        'code': id,
        'category': brand.isEmpty ? '-' : brand,
        'imageUrl': _resolveImageUrl(_shoeImageValue(row)),
        'stock': stock,
        'target': target,
        'sold': soldByShoe[id] ?? 0,
        'todaySold': todaySoldByShoe[id] ?? 0,
        'safetyStock': target,
        'status': status,
        'lastInbound': _dateValue(
          row,
          'last_inbound',
          'receive_date',
        )?.toIso8601String(),
      };
    }).toList();
    final productIds = shoesById.keys.toSet();
    final orders = <Map<String, dynamic>>[];
    final inboundDates = <String>[];
    final receiptLogs = <Map<String, dynamic>>[];
    for (final row in shipmentRows) {
      final shipmentId = _value(row, 'shipment_id', 'order_id');
      final shoeId = _value(row, 'shoe_shoe_id', 'shoe_id');
      final userId = _value(row, 'user_user_id', 'user_id');
      final storeId = _value(row, 'store_store_id', 'store_id');
      final user = usersById[userId];
      final store = storesById[storeId];
      final deliveryDate = _dateValue(
        row,
        'expected_at',
        'arrival_date',
        'delivery_date',
        'shipment_date',
      );
      final status = _deliveryStatus(
        _value(row, 'delivery_status', 'shipment_status'),
      );
      final id = 'shipment:' + shipmentId;
      orders.add({
        'id': id,
        'orderCode': shipmentId,
        'customer': _personName(user, userId),
        'phone': _value(user ?? <String, dynamic>{}, 'user_phone', 'phone'),
        'productId': productIds.contains(shoeId) ? shoeId : '',
        'orderedAt': (_dateValue(row, 'order_date', 'created_at') ?? _epoch)
            .toIso8601String(),
        'expectedAt': (deliveryDate ?? _epoch).toIso8601String(),
        'status': status,
        'quantity': _intValue(row, 'delivery_quantity', 'quantity'),
        'address': _value(
          row,
          'address',
          'delivery_address',
          store == null ? '' : _value(store, 'district_name', 'agency_name'),
        ),
      });
    }

    final pickups = <Map<String, dynamic>>[];
    final pickupOrders = <Map<String, dynamic>>[];
    for (final row in receiveRows) {
      final receiveId = _value(row, 'receive_id', 'id');
      final paymentId = _value(row, 'receive_payment_id', 'payment_id');
      final purchase = purchasesByPayment[paymentId];
      final shoeId = _value(row, 'shoe_shoe_id', 'shoe_id').isNotEmpty
          ? _value(row, 'shoe_shoe_id', 'shoe_id')
          : _value(purchase ?? const {}, 'shoe_shoe_id', 'shoe_id');
      final userId = _value(row, 'user_user_id', 'user_id').isNotEmpty
          ? _value(row, 'user_user_id', 'user_id')
          : _value(purchase ?? const {}, 'user_user_id', 'user_id');
      final user = usersById[userId];
      final receiveDate = _dateValue(
        row,
        'receive_date',
        'arrived_at',
        'created_at',
      );
      final completed =
          _pickupStatus(_value(row, 'receive_status', 'status')) == 'completed';
      final pickupOrderId = 'receive:' + receiveId;
      pickupOrders.add({
        'id': pickupOrderId,
        'orderCode': _value(purchase ?? const {}, 'purchase_id', receiveId),
        'customer': _personName(user, userId),
        'phone': _value(user ?? const {}, 'user_phone', 'phone'),
        'productId': productIds.contains(shoeId) ? shoeId : '',
        'orderedAt':
            (_dateValue(purchase ?? const {}, 'purchase_date', 'created_at') ??
                    _epoch)
                .toIso8601String(),
        'expectedAt': (receiveDate ?? _epoch).toIso8601String(),
        'status': 'unknown',
        'quantity': _intValue(
          row,
          'receive_quantity',
          _intValue(purchase ?? const {}, 'quantity'),
        ),
        'address': '',
      });
      if (receiveDate != null) {
        final employeeId = _value(row, 'employee_employee_id', 'employee_id');
        final product = shoesById[shoeId];
        final customerName = _personName(user, userId);
        final receivedQuantity = _intValue(
          row,
          'receive_quantity',
          _intValue(purchase ?? const {}, 'quantity'),
        );
        receiptLogs.add({
          'id': receiptLogs.length + 1,
          'type': completed ? '고객 수령' : '수령 대기',
          'message': completed ? '고객 수령 완료' : '상품 수령 대기 등록',
          'customer': customerName,
          'product': product == null ? '-' : _productName(product),
          'option': product == null
              ? '-'
              : _value(product, 'shoe_option', 'option', 'size'),
          'phone': _value(user ?? const {}, 'user_phone', 'phone'),
          'code': _value(purchase ?? const {}, 'purchase_id', receiveId),
          'quantity': receivedQuantity,
          'staff': _personName(employeesById[employeeId], employeeId),
          'amount': 0,
          'note': '',
          'createdAt': receiveDate.toIso8601String(),
        });
      }
      pickups.add({
        'id': receiveId,
        'orderId': pickupOrderId,
        'arrivedAt': (receiveDate ?? _epoch).toIso8601String(),
        'status': _pickupStatus(_value(row, 'receive_status', 'status')),
        'contacted': _boolValue(row, 'contacted', 'notice_sent', true),
        'quantity': _intValue(
          row,
          'receive_quantity',
          _intValue(purchase ?? const {}, 'quantity'),
        ),
        'completedAt': completed ? receiveDate?.toIso8601String() : null,
        'location': _value(row, 'storage_location', 'location'),
      });
      if (completed && receiveDate != null)
        inboundDates.add(receiveDate.toIso8601String());
    }

    final returnObjects = <Map<String, dynamic>>[];
    final returnOrders = <Map<String, dynamic>>[];
    for (final row in returnRows) {
      final returnId = _value(row, 'return_id', 'id');
      final shoeId = _value(row, 'shoe_shoe_id', 'shoe_id');
      final userId = _value(row, 'user_user_id', 'user_id');
      final user = usersById[userId];
      final matchedPurchase = purchaseRows
          .where((item) => _value(item, 'purchase_id') == returnId)
          .firstOrNull;
      final returnDate = _dateValue(
        row,
        'return_date',
        'requested_at',
        'created_at',
      );
      final returnOrderId = 'return:' + returnId;
      returnOrders.add({
        'id': returnOrderId,
        'orderCode': returnId,
        'customer': _personName(user, userId),
        'phone': _value(user ?? const {}, 'user_phone', 'phone'),
        'productId': productIds.contains(shoeId) ? shoeId : '',
        'orderedAt':
            (_dateValue(
                      matchedPurchase ?? const {},
                      'purchase_date',
                      'created_at',
                    ) ??
                    _epoch)
                .toIso8601String(),
        'expectedAt': (returnDate ?? _epoch).toIso8601String(),
        'status': 'unknown',
        'quantity': _intValue(matchedPurchase ?? const {}, 'quantity', 1),
        'address': '',
      });
      returnObjects.add({
        'id': returnId,
        'orderId': returnId,
        'reason': _value(row, 'return_reason', 'reason'),
        'detailReason': _value(row, 'return_detail', 'detail_reason'),
        'note': _value(row, 'return_note', 'note'),
        'status': _returnStatus(_value(row, 'return_status', 'status')),
        'requestedAt': (returnDate ?? _epoch).toIso8601String(),
        'inspectionResult': _value(row, 'inspection_result'),
        'recallRequested': _boolValue(row, 'recall_requested'),
        'contacted': _boolValue(row, 'contacted', 'notice_sent', true),
      });
    }

    final allOrders = [...orders, ...pickupOrders, ...returnOrders];
    final logs = <Map<String, dynamic>>[...receiptLogs];
    var logId = receiptLogs.length + 1;
    for (final row in purchaseRows) {
      final shoeId = _value(row, 'shoe_shoe_id', 'shoe_id');
      final userId = _value(row, 'user_user_id', 'user_id');
      final employeeId = _value(row, 'employee_employee_id', 'employee_id');
      final product = shoesById[shoeId];
      final user = usersById[userId];
      final employee = employeesById[employeeId];
      final date =
          _dateValue(row, 'purchase_date', 'payment_date', 'created_at') ??
          _epoch;
      final itemName = product == null ? '-' : _productName(product);
      final code = _value(row, 'purchase_id', 'payment_id');
      logs.add({
        'id': logId++,
        'type': '판매',
        'message': _personName(user, userId) + ' 고객 구매 처리',
        'customer': _personName(user, userId),
        'product': itemName,
        'option': _value(
          product ?? const {},
          'shoe_option',
          'option',
          'size',
          '-',
        ),
        'phone': _value(user ?? const {}, 'user_phone', 'phone'),
        'code': code,
        'quantity': _intValue(row, 'quantity'),
        'staff': _personName(employee, employeeId),
        'amount': _intValue(row, 'sale_price', 'payment_amount'),
        'note': '',
        'createdAt': date.toIso8601String(),
      });
    }
    for (final row in returnRows) {
      final returnDate = _dateValue(
        row,
        'return_date',
        'requested_at',
        'created_at',
      );
      if (returnDate == null) continue;
      final returnId = _value(row, 'return_id', 'id');
      final shoeId = _value(row, 'shoe_shoe_id', 'shoe_id');
      final product = shoesById[shoeId];
      final matchedPurchase = purchaseRows
          .where((item) => _value(item, 'purchase_id') == returnId)
          .firstOrNull;
      final userId = _value(
        matchedPurchase ?? const {},
        'user_user_id',
        'user_id',
      );
      final user = usersById[userId];
      logs.add({
        'id': logId++,
        'type': '반품 요청',
        'message': '반품 요청 접수: ' + returnId,
        'customer': _personName(user, userId),
        'product': product == null ? '-' : _productName(product),
        'option': _value(
          product ?? const {},
          'shoe_option',
          'option',
          'size',
          '-',
        ),
        'phone': _value(user ?? const {}, 'user_phone', 'phone'),
        'code': returnId,
        'quantity': 1,
        'staff': _personName(
          employeesById[_value(row, 'employee_employee_id')],
          _value(row, 'employee_employee_id'),
        ),
        'amount': 0,
        'note': _value(row, 'return_reason', 'reason'),
        'createdAt': returnDate.toIso8601String(),
      });
    }
    logs.sort(
      (a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String),
    );
    return {
      'schemaVersion': 2,
      'unreadCount': 0,
      'products': products,
      'orders': allOrders,
      'pickups': pickups,
      'returns': returnObjects,
      'inboundReceipts': inboundDates,
      'logs': logs,
      'employees': employeeRows
          .map(
            (row) => {
              'id': _value(row, 'employee_id'),
              'name': _value(row, 'employee_name'),
              'position': _value(row, 'employee_position'),
              'department': _value(row, 'employee_department'),
            },
          )
          .toList(),
      'stores': storeRows
          .map(
            (row) => {
              'id': _value(row, 'store_id'),
              'agencyName': _value(row, 'agency_name'),
              'districtName': _value(row, 'district_name'),
              'phone': _value(row, 'phone'),
            },
          )
          .toList(),
    };
  }

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);
  List<Map<String, dynamic>> _rows(Map<String, dynamic> source, String key) =>
      (source[key] as List<dynamic>? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

  String _value(
    Map<String, dynamic> row,
    String key1, [
    String? key2,
    String? key3,
    String fallback = '',
  ]) {
    for (final key in [key1, key2, key3]) {
      if (key == null) continue;
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty)
        return value.toString();
    }
    return fallback;
  }

  int _intValue(
    Map<String, dynamic> row,
    String key1, [
    Object? key2OrFallback,
    int fallback = 0,
  ]) {
    final key2 = key2OrFallback is String ? key2OrFallback : null;
    if (key2OrFallback is num) fallback = key2OrFallback.toInt();
    for (final key in [key1, key2]) {
      if (key == null) continue;
      final value = row[key];
      if (value is num) return value.toInt();
      if (value != null)
        return int.tryParse(
              value.toString().replaceAll(RegExp(r'[^0-9-]'), ''),
            ) ??
            fallback;
    }
    return fallback;
  }

  bool _boolValue(
    Map<String, dynamic> row,
    String key1, [
    String? key2,
    Object? key3OrFallback,
    bool fallback = false,
  ]) {
    final key3 = key3OrFallback is String ? key3OrFallback : null;
    if (key3OrFallback is bool) fallback = key3OrFallback;
    for (final key in [key1, key2, key3]) {
      if (key == null || row[key] == null) continue;
      final value = row[key];
      if (value is bool) return value;
      return const {
        '1',
        'true',
        'yes',
        'y',
        '발송',
        '완료',
      }.contains(value.toString().toLowerCase());
    }
    return fallback;
  }

  DateTime? _dateValue(
    Map<String, dynamic> row,
    String key1, [
    String? key2,
    String? key3,
    String? key4,
  ]) {
    for (final key in [key1, key2, key3, key4]) {
      if (key == null || row[key] == null) continue;
      final value = row[key];
      if (value is DateTime) return value;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  bool _isToday(DateTime? value) {
    if (value == null) return false;
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  String _personName(Map<String, dynamic>? row, String id) {
    if (row == null) return id.isEmpty ? '-' : id;
    return _value(
      row,
      'user_name',
      'employee_name',
      'name',
      id.isEmpty ? '-' : id,
    );
  }

  String _productName(Map<String, dynamic> row) {
    final brand = _value(row, 'shoe_category', 'brand_name', 'category');
    return _value(
      row,
      'shoe_name',
      'product_name',
      'name',
      brand.isEmpty ? _value(row, 'shoe_id', '-') : brand,
    );
  }

  String _token(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');

  String _deliveryStatus(String value) {
    final status = _token(value);
    if (status.contains('delay') || status.contains('지연')) return 'delayed';
    if (status.contains('transit') ||
        status.contains('배송중') ||
        status.contains('이동중'))
      return 'inTransit';
    if (status.contains('arrivedtoday') || status.contains('센터도착'))
      return 'arrivedToday';
    if (status.contains('deliveredcompleted') ||
        status.contains('도착완료') ||
        status.contains('배송완료'))
      return 'deliveredCompleted';
    return 'unknown';
  }

  String _pickupStatus(String value) {
    final status = _token(value);
    if (status.contains('contact') || status.contains('연락필요'))
      return 'contactNeeded';
    if (status.contains('delay') || status.contains('지연')) return 'delayed';
    if (status.contains('complete') || status.contains('수령완료'))
      return 'completed';
    if (status.contains('waiting') ||
        status.contains('pending') ||
        status.contains('대기'))
      return 'waiting';
    return 'unknown';
  }

  String _returnStatus(String value) {
    final status = _token(value);
    if (status.contains('refunded') || status.contains('환불')) return 'refunded';
    if (status.contains('recallcompleted') || status.contains('회수완료'))
      return 'recallCompleted';
    if (status.contains('recall') || status.contains('회수진행'))
      return 'recallRequested';
    if (status.contains('approved') || status.contains('승인완료'))
      return 'approved';
    if (status.contains('inspect') || status.contains('검수대기'))
      return 'inspectWaiting';
    if (status.contains('request') || status.contains('반품요청'))
      return 'requested';
    return 'unknown';
  }
}
