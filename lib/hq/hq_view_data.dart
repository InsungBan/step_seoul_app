import 'hq_repository.dart';

const hqMissing = '데이터가 없습니다.';

class HqViewData {
  HqViewData(this.tables);
  final Map<String, List<HqRow>> tables;
  List<HqRow> rows(String table) => tables[table] ?? [];
  num? number(dynamic value) => num.tryParse('$value');
  String text(dynamic value) =>
      value == null || '$value'.isEmpty ? hqMissing : '$value';
  HqRow? find(String table, String key, dynamic id) {
    if (id == null) return null;
    for (final row in rows(table)) {
      if (row[key] == id) return row;
    }
    return null;
  }

  String name(String table, String key, dynamic id, String field) =>
      text(find(table, key, id)?[field] ?? id);
  Map<String, String>? shoeCodeOptions(dynamic code) {
    if (code is! String) return null;
    final parts = code.split('_');
    if (parts.length < 5 || parts.any((part) => part.isEmpty)) return null;
    final size = parts[parts.length - 2];
    if (num.tryParse(size) == null) return null;
    return {'color': parts[parts.length - 4], 'size': size};
  }

  HqRow? payment(HqRow order) =>
      find('payment', 'payment_id', order['payment_id']);
  HqRow? customer(HqRow order) =>
      find('user', 'user_id', order['user_user_id']);
  HqRow? receipt(HqRow order) {
    final matches = rows('receive')
        .where(
          (r) =>
              order['payment_id'] != null &&
              r['receive_payment_id'] == order['payment_id'] &&
              r['user_user_id'] == order['user_user_id'],
        )
        .toList();
    // Multiple receipts cannot safely be reduced to a single destination.
    return matches.length == 1 ? matches.single : null;
  }

  String deliveryStatus(HqRow order) {
    if (order['purchase_id'] == null) return hqMissing;
    final shipments = rows('shipment').where(
      (row) =>
          row['purchase_purchase_id'] == order['purchase_id'] &&
          row['shoe_shoe_id'] == order['shoe_shoe_id'] &&
          (order['store_store_id'] == null ||
              row['store_store_id'] == order['store_store_id']),
    );
    if (shipments.isEmpty) return '출고 대기중';
    final states = shipments.map((row) {
      final state = row['delivery_status'];
      return state == null ||
              state == '' ||
              ['Preparing pickup', '발송준비', '출고대기'].contains(state)
          ? '출고 대기중'
          : text(state);
    }).toSet();
    return states.join(', ');
  }

  String receiveStatus(HqRow order) {
    if (order['payment_id'] == null || order['user_user_id'] == null) {
      return hqMissing;
    }
    final receipts = rows('receive').where(
      (row) =>
          row['receive_payment_id'] == order['payment_id'] &&
          row['user_user_id'] == order['user_user_id'] &&
          (order['store_store_id'] == null ||
              row['store_store_id'] == order['store_store_id']),
    );
    if (receipts.isEmpty) return '미수령';
    final states = receipts.map((row) => text(row['receive_status'])).toSet();
    return states.length == 1 ? states.single : hqMissing;
  }

  HqRow? latestApproval(dynamic id) {
    final matches = rows(
      'approval_process',
    ).where((r) => r['approval_approval_id'] == id).toList();
    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.single;
    matches.sort(
      (a, b) => text(
        b['processed_at'] ?? b['approval_date'],
      ).compareTo(text(a['processed_at'] ?? a['approval_date'])),
    );
    final first = matches.first;
    final timestamp = first['processed_at'] ?? first['approval_date'];
    if (timestamp == null ||
        timestamp ==
            (matches[1]['processed_at'] ?? matches[1]['approval_date'])) {
      return null;
    }
    return first;
  }

  String receivedProducts(HqRow receipt) {
    if (receipt['receive_payment_id'] == null ||
        receipt['user_user_id'] == null) {
      return hqMissing;
    }
    final purchases = rows('purchase').where(
      (row) =>
          row['payment_id'] == receipt['receive_payment_id'] &&
          row['user_user_id'] == receipt['user_user_id'],
    );
    final names = purchases
        .where((row) => row['shoe_shoe_id'] != null)
        .map(
          (row) => name('shoe', 'shoe_id', row['shoe_shoe_id'], 'brand_name'),
        )
        .toSet();
    return names.isEmpty ? hqMissing : names.join(', ');
  }

  HqRow? shipmentOrder(HqRow shipment) {
    final id = shipment['purchase_purchase_id'];
    if (id == null) return null;
    final matches = rows('purchase')
        .where(
          (row) =>
              row['purchase_id'] == id &&
              row['shoe_shoe_id'] == shipment['shoe_shoe_id'],
        )
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  String returnRefundStatus(HqRow returned) {
    final id = returned['refund_refund_id'];
    if (id == null) return hqMissing;
    final matches = rows(
      'refund',
    ).where((row) => row['refund_id'] == id).toList();
    return matches.length == 1 ? '환불완료' : hqMissing;
  }

  num? sum(List<HqRow> source, String field) {
    if (source.isEmpty) return null;
    num total = 0;
    for (final row in source) {
      final value = number(row[field]);
      if (value == null) return null;
      total += value;
    }
    return total;
  }

  String count(String table) =>
      rows(table).isEmpty ? hqMissing : '${rows(table).length}건';
  double? ratio(HqRow row) {
    final current = number(row['stock_quantity']);
    final standard = number(row['standard_stock']);
    if (current == null || standard == null || standard <= 0) return null;
    return current / standard;
  }

  String stockStatus(HqRow row) {
    final r = ratio(row);
    return r == null
        ? hqMissing
        : r < .3
        ? '부족'
        : r < .7
        ? '주의'
        : '정상';
  }

  List<HqRow> get lowStock =>
      rows('shoe').where((r) => ratio(r) != null && ratio(r)! < .3).toList();
  List<HqRow> get paid =>
      rows('payment').where((r) => number(r['payment_status']) == 1).toList();
  DateTime? date(dynamic value) => DateTime.tryParse('$value');
  String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  List<HqRow> paymentsBetween(DateTime start, DateTime end) => paid.where((r) {
    final d = date(r['payment_date']);
    return d != null && !d.isBefore(start) && d.isBefore(end);
  }).toList();
  Map<String, num> salesDays(DateTime start, DateTime end) {
    final result = <String, num>{};
    for (final row in paymentsBetween(start, end)) {
      final amount = number(row['payment_amount']);
      if (amount == null) continue;
      final key = day(date(row['payment_date'])!);
      result[key] = (result[key] ?? 0) + amount;
    }
    return Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  List<HqRow> bestProducts(DateTime start, DateTime end) {
    final paidIds = paymentsBetween(
      start,
      end,
    ).map((r) => r['payment_id']).toSet();
    final result = <String, HqRow>{};
    for (final row in rows('purchase')) {
      if (!paidIds.contains(row['payment_id'])) continue;
      final quantity = number(row['quantity']);
      final price = number(row['sale_price']);
      if (quantity == null || price == null || row['shoe_shoe_id'] == null) {
        continue;
      }
      final id = '${row['shoe_shoe_id']}';
      final item = result.putIfAbsent(
        id,
        () => {'shoe_shoe_id': id, 'quantity': 0, 'amount': 0},
      );
      item['quantity'] = (item['quantity'] as num) + quantity;
      item['amount'] = (item['amount'] as num) + price * quantity;
    }
    return result.values.toList()
      ..sort((a, b) => (b['quantity'] as num).compareTo(a['quantity'] as num));
  }

  String manufacturerFor(dynamic shoeId) {
    final ids = rows('manufacturing')
        .where((r) => r['shoe_shoe_id'] == shoeId)
        .map((r) => r['shoe_manufacturer_manufacturer_id'])
        .where((id) => id != null)
        .toSet();
    return ids.isEmpty
        ? hqMissing
        : ids
              .map(
                (id) => name(
                  'shoe_manufacturer',
                  'manufacturer_id',
                  id,
                  'manufacturer_name',
                ),
              )
              .join(', ');
  }
}
