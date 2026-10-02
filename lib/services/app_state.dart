import 'package:flutter/foundation.dart';

enum ProductStatus { normal, warning, outOfStock, surplus }

enum DeliveryStatus {
  unknown,
  inTransit,
  arrivedToday,
  deliveredCompleted,
  delayed,
}

enum PickupStatus { unknown, waiting, completed, contactNeeded, delayed }

enum ReturnStatus {
  unknown,
  requested,
  inspectWaiting,
  approved,
  recallRequested,
  recalling,
  recallCompleted,
  refunded,
}

String productStatusLabel(ProductStatus value) => switch (value) {
  ProductStatus.normal => '정상',
  ProductStatus.warning => '주의',
  ProductStatus.outOfStock => '재고부족',
  ProductStatus.surplus => '과잉 재고',
};
String deliveryStatusLabel(DeliveryStatus value) => switch (value) {
  DeliveryStatus.unknown => '상태 미등록',
  DeliveryStatus.inTransit => '매장으로 배송 중',
  DeliveryStatus.arrivedToday => '지역 센터 도착',
  DeliveryStatus.deliveredCompleted => '도착 완료',
  DeliveryStatus.delayed => '배송 지연',
};
String pickupStatusLabel(PickupStatus value) => switch (value) {
  PickupStatus.unknown => '상태 미등록',
  PickupStatus.waiting => '수령 대기',
  PickupStatus.completed => '수령 완료',
  PickupStatus.contactNeeded => '연락 필요',
  PickupStatus.delayed => '지연',
};
String returnStatusLabel(ReturnStatus value) => switch (value) {
  ReturnStatus.unknown => '상태 미등록',
  ReturnStatus.requested => '반품 요청',
  ReturnStatus.inspectWaiting => '검수 대기',
  ReturnStatus.approved => '승인 완료',
  ReturnStatus.recallRequested => '회수 진행 중',
  ReturnStatus.recalling => '회수 진행 중',
  ReturnStatus.recallCompleted => '회수 완료',
  ReturnStatus.refunded => '환불 완료',
};

class MockProduct {
  MockProduct({
    required this.id,
    required this.name,
    required this.option,
    required this.code,
    required this.category,
    required this.stock,
    required this.target,
    required this.sold,
    required this.todaySold,
    required this.safetyStock,
    required this.status,
    required this.lastInbound,
  });
  final String id, name, option, code, category;
  int stock;
  final int target, safetyStock;
  int sold, todaySold;
  ProductStatus status;
  DateTime? lastInbound;
  String get brand => category;
  int get today => todaySold;
  int get threshold => safetyStock;
  void recalculateStatus() {
    status = stock <= 0
        ? ProductStatus.outOfStock
        : stock < safetyStock
        ? ProductStatus.warning
        : stock > target
        ? ProductStatus.surplus
        : ProductStatus.normal;
  }
}

class MockOrder {
  MockOrder({
    required this.id,
    required this.orderCode,
    required this.customer,
    required this.phone,
    required this.productId,
    required this.orderedAt,
    required this.expectedAt,
    required this.status,
    required this.quantity,
    required this.address,
  });
  final String id, orderCode, customer, phone, productId, address;
  final DateTime orderedAt;
  DateTime expectedAt;
  DeliveryStatus status;
  final int quantity;
}

class MockPickup {
  MockPickup({
    required this.id,
    required this.orderId,
    required this.arrivedAt,
    required this.status,
    required this.contacted,
    required this.quantity,
    this.completedAt,
    this.location = '',
  });
  final String id, orderId, location;
  final DateTime arrivedAt;
  PickupStatus status;
  bool contacted;
  final int quantity;
  DateTime? completedAt;
  int get waitingDays =>
      arrivedAt.year <= 1970 ||
          status == PickupStatus.completed ||
          status == PickupStatus.waiting && completedAt != null
      ? 0
      : DateTime.now().difference(arrivedAt).inDays;
}

class MockReturn {
  MockReturn({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.detailReason,
    required this.note,
    required this.status,
    required this.requestedAt,
    required this.inspectionResult,
    required this.recallRequested,
    this.contacted = false,
  });
  final String id, orderId, reason, detailReason, note;
  ReturnStatus status;
  final DateTime requestedAt;
  String inspectionResult;
  bool recallRequested;
  bool contacted;
}

class WorkActivity {
  const WorkActivity({
    required this.id,
    required this.type,
    required this.message,
    required this.customer,
    required this.product,
    required this.option,
    required this.phone,
    required this.code,
    required this.quantity,
    required this.staff,
    required this.amount,
    required this.note,
    required this.createdAt,
  });
  final int id, quantity, amount;
  final String type,
      message,
      customer,
      product,
      option,
      phone,
      code,
      staff,
      note;
  final DateTime createdAt;
}

class MockDatabase extends ChangeNotifier {
  MockDatabase._() {
    reset(notify: false);
  }
  static final instance = MockDatabase._();

  late List<MockProduct> products;
  late List<MockOrder> orders;
  late List<MockPickup> pickups;
  late List<MockReturn> returns;
  late List<DateTime> inboundReceipts;
  late List<WorkActivity> logs;
  int _nextLogId = 1;
  int _unread = 0;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(DateTime value) =>
      value.year == _today.year &&
      value.month == _today.month &&
      value.day == _today.day;

  int get totalProducts => products.length;
  int get normalProducts =>
      products.where((p) => p.status == ProductStatus.normal).length;
  int get lowStockProducts => products
      .where(
        (p) =>
            p.status == ProductStatus.warning ||
            p.status == ProductStatus.outOfStock,
      )
      .length;
  int get todaySalesQuantity => products.fold(0, (sum, p) => sum + p.todaySold);
  int get todayInboundCount => inboundReceipts.where(_isToday).length;
  int get todayExpectedOrders =>
      orders.where((o) => _isToday(o.expectedAt)).length;
  int get inTransitCount =>
      orders.where((o) => o.status == DeliveryStatus.inTransit).length;
  int get arrivedTodayCount => orders
      .where(
        (o) =>
            o.status == DeliveryStatus.arrivedToday ||
            o.status == DeliveryStatus.deliveredCompleted &&
                _isToday(o.expectedAt),
      )
      .length;
  int get delayedCount =>
      orders.where((o) => o.status == DeliveryStatus.delayed).length;
  int get todayCompletedPickups => pickups
      .where(
        (p) =>
            p.status == PickupStatus.completed &&
            p.completedAt != null &&
            _isToday(p.completedAt!),
      )
      .length;
  int get unreceivedPickups =>
      pickups.where((p) => p.status != PickupStatus.completed).length;
  int get waitingPickups => pickups
      .where(
        (p) =>
            p.status == PickupStatus.waiting ||
            p.status == PickupStatus.contactNeeded ||
            p.status == PickupStatus.delayed,
      )
      .length;
  int get longWaitingPickups => pickups
      .where((p) => p.status != PickupStatus.completed && p.waitingDays >= 3)
      .length;
  int get noticesNeeded => pickups
      .where(
        (p) =>
            p.status != PickupStatus.completed &&
            p.waitingDays >= 3 &&
            !p.contacted,
      )
      .length;
  int get returnRequestsCount => returns.length;
  int get inspectWaitingReturns =>
      returns.where((r) => r.status == ReturnStatus.inspectWaiting).length;
  int get approvedReturns =>
      returns.where((r) => r.status == ReturnStatus.approved).length;
  int get recallsInProgress => returns
      .where(
        (r) =>
            r.status == ReturnStatus.recallRequested ||
            r.status == ReturnStatus.recalling,
      )
      .length;
  int get todayWorkCount => logs.where((l) => _isToday(l.createdAt)).length;
  int get todaySalesCount =>
      logs.where((l) => _isToday(l.createdAt) && l.type == '판매').length;
  int get todayPickupCount =>
      logs.where((l) => _isToday(l.createdAt) && l.type == '고객 수령').length;
  int get todayReturnCount => logs
      .where(
        (l) =>
            _isToday(l.createdAt) &&
            (l.type == '반품 승인' || l.type == '본사 회수 요청'),
      )
      .length;
  int get unreadCount => _unread;

  Map<String, dynamic> exportState() => {
    'schemaVersion': 2,
    'unreadCount': _unread,
    'products': products
        .map(
          (p) => {
            'id': p.id,
            'name': p.name,
            'option': p.option,
            'code': p.code,
            'category': p.category,
            'stock': p.stock,
            'target': p.target,
            'sold': p.sold,
            'todaySold': p.todaySold,
            'safetyStock': p.safetyStock,
            'status': p.status.name,
            'lastInbound': p.lastInbound?.toIso8601String(),
          },
        )
        .toList(),
    'orders': orders
        .map(
          (o) => {
            'id': o.id,
            'orderCode': o.orderCode,
            'customer': o.customer,
            'phone': o.phone,
            'productId': o.productId,
            'orderedAt': o.orderedAt.toIso8601String(),
            'expectedAt': o.expectedAt.toIso8601String(),
            'status': o.status.name,
            'quantity': o.quantity,
            'address': o.address,
          },
        )
        .toList(),
    'pickups': pickups
        .map(
          (p) => {
            'id': p.id,
            'orderId': p.orderId,
            'arrivedAt': p.arrivedAt.toIso8601String(),
            'status': p.status.name,
            'contacted': p.contacted,
            'quantity': p.quantity,
            'completedAt': p.completedAt?.toIso8601String(),
            'location': p.location,
          },
        )
        .toList(),
    'returns': returns
        .map(
          (r) => {
            'id': r.id,
            'orderId': r.orderId,
            'reason': r.reason,
            'detailReason': r.detailReason,
            'note': r.note,
            'status': r.status.name,
            'requestedAt': r.requestedAt.toIso8601String(),
            'inspectionResult': r.inspectionResult,
            'recallRequested': r.recallRequested,
            'contacted': r.contacted,
          },
        )
        .toList(),
    'inboundReceipts': inboundReceipts
        .map((date) => date.toIso8601String())
        .toList(),
    'logs': logs
        .map(
          (item) => {
            'id': item.id,
            'type': item.type,
            'message': item.message,
            'customer': item.customer,
            'product': item.product,
            'option': item.option,
            'phone': item.phone,
            'code': item.code,
            'quantity': item.quantity,
            'staff': item.staff,
            'amount': item.amount,
            'note': item.note,
            'createdAt': item.createdAt.toIso8601String(),
          },
        )
        .toList(),
  };

  void restoreState(Map<String, dynamic> state) {
    if (state['schemaVersion'] != 2) {
      throw const FormatException('Unsupported employee state version');
    }
    final productStatuses = {
      for (final item in ProductStatus.values) item.name: item,
    };
    final deliveryStatuses = {
      for (final item in DeliveryStatus.values) item.name: item,
    };
    final pickupStatuses = {
      for (final item in PickupStatus.values) item.name: item,
    };
    final returnStatuses = {
      for (final item in ReturnStatus.values) item.name: item,
    };
    List<Map<String, dynamic>> rows(String key) => (state[key] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    DateTime date(Map<String, dynamic> row, String key) =>
        DateTime.parse(row[key] as String);
    int number(Map<String, dynamic> row, String key) =>
        (row[key] as num).toInt();

    products = rows('products')
        .map(
          (row) => MockProduct(
            id: row['id'] as String,
            name: row['name'] as String,
            option: row['option'] as String,
            code: row['code'] as String,
            category: row['category'] as String,
            stock: number(row, 'stock'),
            target: number(row, 'target'),
            sold: number(row, 'sold'),
            todaySold: number(row, 'todaySold'),
            safetyStock: number(row, 'safetyStock'),
            status: productStatuses[row['status']]!,
            lastInbound: row['lastInbound'] == null
                ? null
                : DateTime.parse(row['lastInbound'] as String),
          ),
        )
        .toList();
    orders = rows('orders')
        .map(
          (row) => MockOrder(
            id: row['id'] as String,
            orderCode: row['orderCode'] as String,
            customer: row['customer'] as String,
            phone: row['phone'] as String,
            productId: row['productId'] as String,
            orderedAt: date(row, 'orderedAt'),
            expectedAt: date(row, 'expectedAt'),
            status: deliveryStatuses[row['status']]!,
            quantity: number(row, 'quantity'),
            address: row['address'] as String,
          ),
        )
        .toList();
    pickups = rows('pickups')
        .map(
          (row) => MockPickup(
            id: row['id'] as String,
            orderId: row['orderId'] as String,
            arrivedAt: date(row, 'arrivedAt'),
            status: pickupStatuses[row['status']]!,
            contacted: row['contacted'] as bool,
            quantity: number(row, 'quantity'),
            completedAt: row['completedAt'] == null
                ? null
                : DateTime.parse(row['completedAt'] as String),
            location: row['location'] as String? ?? '',
          ),
        )
        .toList();
    returns = rows('returns')
        .map(
          (row) => MockReturn(
            id: row['id'] as String,
            orderId: row['orderId'] as String,
            reason: row['reason'] as String,
            detailReason: row['detailReason'] as String,
            note: row['note'] as String,
            status: returnStatuses[row['status']]!,
            requestedAt: date(row, 'requestedAt'),
            inspectionResult: row['inspectionResult'] as String,
            recallRequested: row['recallRequested'] as bool,
            contacted: row['contacted'] as bool,
          ),
        )
        .toList();
    inboundReceipts = (state['inboundReceipts'] as List<dynamic>)
        .map((item) => DateTime.parse(item as String))
        .toList();
    logs = rows('logs')
        .map(
          (row) => WorkActivity(
            id: number(row, 'id'),
            type: row['type'] as String,
            message: row['message'] as String,
            customer: row['customer'] as String,
            product: row['product'] as String,
            option: row['option'] as String,
            phone: row['phone'] as String,
            code: row['code'] as String,
            quantity: number(row, 'quantity'),
            staff: row['staff'] as String,
            amount: number(row, 'amount'),
            note: row['note'] as String,
            createdAt: date(row, 'createdAt'),
          ),
        )
        .toList();
    _unread = (state['unreadCount'] as num?)?.toInt() ?? 0;
    _nextLogId =
        logs.fold<int>(0, (maxId, item) => item.id > maxId ? item.id : maxId) +
        1;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    products = <MockProduct>[];
    orders = <MockOrder>[];
    pickups = <MockPickup>[];
    returns = <MockReturn>[];
    inboundReceipts = <DateTime>[];
    logs = <WorkActivity>[];
    _nextLogId = 1;
    _unread = 0;
    if (notify) notifyListeners();
  }

  void markAllRead() {
    _unread = 0;
    notifyListeners();
  }

  WorkActivity record({
    required String type,
    required String message,
    required String customer,
    required String product,
    required String option,
    required String phone,
    required String code,
    required int quantity,
    required String staff,
    int amount = 0,
    required String note,
  }) {
    final now = DateTime.now();
    final item = WorkActivity(
      id: _nextLogId++,
      type: type,
      message: message,
      customer: customer,
      product: product,
      option: option,
      phone: phone,
      code: code,
      quantity: quantity,
      staff: staff,
      amount: amount,
      note: note,
      createdAt: now,
    );
    logs.insert(0, item);
    _unread++;
    notifyListeners();
    return item;
  }

  static final _emptyOrder = MockOrder(
    id: '',
    orderCode: '-',
    customer: '-',
    phone: '',
    productId: '',
    orderedAt: DateTime.fromMillisecondsSinceEpoch(0),
    expectedAt: DateTime.fromMillisecondsSinceEpoch(0),
    status: DeliveryStatus.unknown,
    quantity: 0,
    address: '',
  );
  static final _emptyProduct = MockProduct(
    id: '',
    name: '-',
    option: '-',
    code: '-',
    category: '-',
    stock: 0,
    target: 0,
    sold: 0,
    todaySold: 0,
    safetyStock: 0,
    status: ProductStatus.outOfStock,
    lastInbound: null,
  );
  MockOrder orderForPickup(MockPickup pickup) => orders.firstWhere(
    (o) => o.id == pickup.orderId,
    orElse: () => _emptyOrder,
  );
  MockProduct productForOrder(MockOrder order) => products.firstWhere(
    (p) => p.id == order.productId,
    orElse: () => _emptyProduct,
  );
  void completePickup(String id, {String staff = '김직원'}) {
    final p = pickups.firstWhere((x) => x.id == id);
    if (p.status == PickupStatus.completed) return;
    p.status = PickupStatus.completed;
    p.completedAt = DateTime.now();
    final o = orderForPickup(p);
    final product = productForOrder(o);
    record(
      type: '고객 수령',
      message:
          '[' + staff + '] 직원님이 [' + o.customer + '] 고객의 상품 수령 처리를 완료하였습니다.',
      customer: o.customer,
      product: product.name,
      option: product.option,
      phone: o.phone,
      code: o.orderCode,
      quantity: p.quantity,
      staff: staff + ' (강남 대리점 · 사원)',
      note: '고객 본인 확인 후 상품을 전달했습니다.',
    );
  }

  void sendPickupNotice(String id, {String type = '안내 발송'}) {
    final p = pickups.firstWhere((x) => x.id == id);
    p.contacted = true;
    if (p.status == PickupStatus.contactNeeded) p.status = PickupStatus.waiting;
    final o = orderForPickup(p);
    final product = productForOrder(o);
    record(
      type: type,
      message: '[김직원] 직원님이 [' + o.customer + '] 고객에게 수령 안내를 발송하였습니다.',
      customer: o.customer,
      product: product.name,
      option: product.option,
      phone: o.phone,
      code: o.orderCode,
      quantity: p.quantity,
      staff: '김직원 (강남 대리점 · 사원)',
      note: '고객 수령 안내 메시지를 발송했습니다.',
    );
  }

  void approveReturn(String id, {String staff = '김직원'}) {
    final r = returns.firstWhere((x) => x.id == id);
    if (r.status != ReturnStatus.inspectWaiting &&
        r.status != ReturnStatus.requested)
      return;
    r.status = ReturnStatus.approved;
    final o = orders.firstWhere(
      (x) => x.orderCode == r.orderId,
      orElse: () => _emptyOrder,
    );
    final product = productForOrder(o);
    record(
      type: '반품 승인',
      message: '[' + staff + '] 직원님이 [' + o.orderCode + '] 건의 반품 요청을 승인하였습니다.',
      customer: o.customer,
      product: product.name,
      option: product.option,
      phone: o.phone,
      code: o.orderCode,
      quantity: o.quantity,
      staff: staff + ' (강남 대리점 · 사원)',
      note: r.reason,
    );
  }

  void sendReturnNotice(String id, {String type = '안내 발송'}) {
    final request = returns.firstWhere((item) => item.id == id);
    request.contacted = true;
    final pickup = pickups
        .where((item) => orderForPickup(item).orderCode == request.orderId)
        .firstOrNull;
    if (pickup != null) {
      pickup.contacted = true;
      if (pickup.status == PickupStatus.contactNeeded)
        pickup.status = PickupStatus.waiting;
    }
    final order = orders.firstWhere(
      (item) => item.orderCode == request.orderId,
      orElse: () => _emptyOrder,
    );
    final product = productForOrder(order);
    record(
      type: type,
      message: '[김직원] 직원님이 [' + order.customer + '] 고객에게 반품 관련 안내를 발송하였습니다.',
      customer: order.customer,
      product: product.name,
      option: product.option,
      phone: order.phone,
      code: order.orderCode,
      quantity: order.quantity,
      staff: '김직원 (강남 대리점 · 사원)',
      note: '반품 요청 처리 안내 메시지를 발송했습니다.',
    );
  }

  void requestReturnRecall(String id, {String staff = '김직원'}) {
    final r = returns.firstWhere((x) => x.id == id);
    if (r.status != ReturnStatus.approved) return;
    r.status = ReturnStatus.recallRequested;
    r.recallRequested = true;
    final o = orders.firstWhere(
      (x) => x.orderCode == r.orderId,
      orElse: () => _emptyOrder,
    );
    final product = productForOrder(o);
    record(
      type: '본사 회수 요청',
      message:
          '[' + staff + '] 직원님이 [' + o.orderCode + '] 건의 본사 회수 요청을 완료하였습니다.',
      customer: o.customer,
      product: product.name,
      option: product.option,
      phone: o.phone,
      code: o.orderCode,
      quantity: o.quantity,
      staff: staff + ' (강남 대리점 · 사원)',
      note: '본사 회수 요청을 등록했습니다.',
    );
  }

  void completeDelivery(String orderId) {
    final order = orders.firstWhere((item) => item.id == orderId);
    if (order.status == DeliveryStatus.deliveredCompleted) return;
    order.status = DeliveryStatus.deliveredCompleted;
    final product = productForOrder(order);
    if (product.id.isEmpty) return;
    product.stock += order.quantity;
    product.recalculateStatus();
    inboundReceipts.insert(0, DateTime.now());
    record(
      type: '재고 입고',
      message:
          '[김직원] 직원님이 [' +
          product.name +
          '] 상품 ' +
          order.quantity.toString() +
          '개를 매장 입고 처리하였습니다.',
      customer: order.customer,
      product: product.name,
      option: product.option,
      phone: order.phone,
      code: order.orderCode,
      quantity: order.quantity,
      staff: '김직원 (강남 대리점 · 사원)',
      note: '배송 상품 검수를 완료하고 매장 재고로 반영했습니다.',
    );
  }

  void receiveInventory(
    String productId,
    int quantity, {
    String staff = '김직원',
  }) {
    final p = products.firstWhere((x) => x.id == productId);
    p.stock += quantity;
    p.sold += 0;
    p.recalculateStatus();
    inboundReceipts.insert(0, DateTime.now());
    record(
      type: '재고 입고',
      message:
          '[' +
          staff +
          '] 직원님이 [' +
          p.name +
          '] 제품의 재고 ' +
          quantity.toString() +
          '개를 입고 처리하였습니다.',
      customer: '매장 재고',
      product: p.name,
      option: p.option,
      phone: '',
      code: p.code,
      quantity: quantity,
      staff: staff + ' (강남 대리점 · 사원)',
      note: '입고 수량 ' + quantity.toString() + '개를 등록했습니다.',
    );
  }
}

class WorkActivityStore {
  WorkActivityStore._();
  static final instance = WorkActivityStore._();
  MockDatabase get database => MockDatabase.instance;
  List<WorkActivity> get items => database.logs;
  int get unreadCount => database.unreadCount;
  void addListener(VoidCallback listener) => database.addListener(listener);
  void removeListener(VoidCallback listener) =>
      database.removeListener(listener);
  WorkActivity add({
    required String type,
    required String message,
    required String customer,
    required String product,
    required String option,
    required String phone,
    required String code,
    required int quantity,
    required String staff,
    int amount = 0,
    required String note,
  }) => database.record(
    type: type,
    message: message,
    customer: customer,
    product: product,
    option: option,
    phone: phone,
    code: code,
    quantity: quantity,
    staff: staff,
    amount: amount,
    note: note,
  );
  void markAllRead() => database.markAllRead();
}
