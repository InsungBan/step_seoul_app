import 'package:flutter/foundation.dart';

enum ProductStatus { normal, warning, outOfStock, surplus }

enum DeliveryStatus { inTransit, arrivedToday, deliveredCompleted, delayed }

enum PickupStatus { waiting, completed, contactNeeded, delayed }

enum ReturnStatus {
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
  DeliveryStatus.inTransit => '매장으로 배송 중',
  DeliveryStatus.arrivedToday => '지역 센터 도착',
  DeliveryStatus.deliveredCompleted => '도착 완료',
  DeliveryStatus.delayed => '배송 지연',
};
String pickupStatusLabel(PickupStatus value) => switch (value) {
  PickupStatus.waiting => '수령 대기',
  PickupStatus.completed => '수령 완료',
  PickupStatus.contactNeeded => '연락 필요',
  PickupStatus.delayed => '지연',
};
String returnStatusLabel(ReturnStatus value) => switch (value) {
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
  });
  final String id, orderId;
  final DateTime arrivedAt;
  PickupStatus status;
  bool contacted;
  final int quantity;
  DateTime? completedAt;
  int get waitingDays =>
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
  int _unread = 4;

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

  void reset({bool notify = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    const templates = [
      ('나이키 에어포스 1 ’07', '나이키', '화이트 / 260', 50, 20),
      ('아디다스 삼바 OG', '아디다스', '블랙 / 240', 40, 15),
      ('뉴발란스 530', '뉴발란스', '실버 / 270', 35, 12),
      ('나이키 덩크 로우', '나이키', '그레이 / 255', 60, 15),
      ('아디다스 가젤', '아디다스', '그린 / 245', 30, 10),
      ('뉴발란스 2002R', '뉴발란스', '그레이 / 265', 40, 12),
    ];
    products = List.generate(342, (i) {
      final t = templates[i % templates.length];
      final status = i < 238
          ? ProductStatus.normal
          : i < 274
          ? ProductStatus.warning
          : i < 280
          ? ProductStatus.outOfStock
          : ProductStatus.surplus;
      final stock = status == ProductStatus.normal
          ? t.$4 - 5
          : status == ProductStatus.warning
          ? t.$5 - 2
          : status == ProductStatus.outOfStock
          ? 0
          : t.$4 + 12;
      return MockProduct(
        id: 'product-$i',
        name: t.$1,
        category: t.$2,
        option: i < 6
            ? t.$3
            : t.$3.split(' / ').first + ' / ' + (220 + i * 5 % 90).toString(),
        code: i == 0
            ? 'SPD-250928-1042'
            : 'SPD-260928-' + (1000 + i).toString().padLeft(4, '0'),
        stock: stock,
        target: t.$4,
        safetyStock: t.$5,
        sold: 12 + i % 37,
        todaySold: i < 11
            ? i == 0
                  ? 76
                  : 1
            : 0,
        status: status,
        lastInbound: yesterday,
      );
    });
    inboundReceipts = List.generate(
      18,
      (i) => today.subtract(Duration(minutes: 20 * i)),
    );
    orders = [];
    for (var i = 0; i < 60; i++) {
      final isTodayWindow = i < 18;
      final status = i < 12
          ? DeliveryStatus.inTransit
          : i < 16
          ? DeliveryStatus.deliveredCompleted
          : i < 18
          ? DeliveryStatus.delayed
          : DeliveryStatus.deliveredCompleted;
      final expected = isTodayWindow
          ? today
          : yesterday.subtract(Duration(days: i % 7));
      final product = products[i % products.length];
      orders.add(
        MockOrder(
          id: 'order-$i',
          orderCode: 'SPO-260928-' + (1042 - i).toString(),
          customer: _customer(i),
          phone: _phone(i),
          productId: product.id,
          orderedAt: today.subtract(Duration(days: 2 + i % 20)),
          expectedAt: expected,
          status: status,
          quantity: 1 + i % 2,
          address: '서울시 강남구 테헤란로 ' + (20 + i).toString(),
        ),
      );
    }
    pickups = List.generate(42, (i) {
      final done = i < 18;
      final long = i >= 18 && i < 26;
      final status = done
          ? PickupStatus.completed
          : i < 24
          ? PickupStatus.waiting
          : i < 30
          ? PickupStatus.contactNeeded
          : PickupStatus.delayed;
      final arrived = done
          ? today.subtract(const Duration(hours: 2))
          : today.subtract(Duration(days: long ? (i < 24 ? 3 : 4) : i % 3));
      return MockPickup(
        id: 'pickup-$i',
        orderId: 'order-' + (18 + i).toString(),
        arrivedAt: arrived,
        status: status,
        contacted: done || i == 24 || i == 25 || i >= 26,
        quantity: 1 + (i % 2),
        completedAt: done ? today.add(Duration(hours: 10, minutes: i)) : null,
      );
    });
    returns = List.generate(28, (i) {
      final status = i < 3
          ? ReturnStatus.requested
          : i < 15
          ? ReturnStatus.inspectWaiting
          : i < 24
          ? ReturnStatus.approved
          : ReturnStatus.recallRequested;
      return MockReturn(
        id: 'return-$i',
        orderId: 'order-' + (18 + i % 42).toString(),
        reason: i % 2 == 0 ? '사이즈가 생각보다 커서 반품 요청합니다.' : '상품 색상이 화면과 달라요.',
        detailReason: '상품 상태를 확인한 후 요청 사유에 따라 처리해 주세요.',
        note: '택배 회수 부탁드립니다.',
        status: status,
        requestedAt: today.subtract(Duration(days: i % 5)),
        inspectionResult: '미개봉 (새상품)',
        recallRequested: status == ReturnStatus.recallRequested,
      );
    });
    logs = _seedLogs(today);
    _nextLogId = logs.length + 1;
    _unread = 4;
    if (notify) notifyListeners();
  }

  String _customer(int i) =>
      const ['이현우', '김민지', '박서준', '최유진', '정수빈', '윤지호', '이준호', '이진서'][i % 8];
  String _phone(int i) => const [
    '010-1234-6789',
    '010-2345-6789',
    '010-3456-7890',
    '010-4567-8901',
    '010-5678-9012',
    '010-6789-0123',
  ][i % 6];
  List<WorkActivity> _seedLogs(DateTime today) {
    final result = <WorkActivity>[];
    for (var i = 0; i < 28; i++) {
      final type = i < 11
          ? '판매'
          : i < 20
          ? '고객 수령'
          : i < 25
          ? '반품 승인'
          : '재고 조정';
      final product = products[i % products.length];
      final customer = _customer(i);
      final q = type == '판매' && i == 0 ? 76 : 1;
      result.add(
        WorkActivity(
          id: i + 1,
          type: type,
          message: type == '고객 수령'
              ? '[김직원] 직원님이 [' + customer + '] 고객의 상품 수령 처리를 완료하였습니다.'
              : type == '반품 승인'
              ? '[이민우] 직원님이 [SPO-250928-1042] 건의 반품 요청을 승인하였습니다.'
              : '[김직원] 직원님이 [' +
                    customer +
                    '] 고객에게 [' +
                    product.name +
                    '] 상품을 판매하였습니다.',
          customer: customer,
          product: product.name,
          option: product.option,
          phone: _phone(i),
          code: type == '고객 수령' || type == '판매'
              ? product.code
              : 'SPO-250928-' + (1042 - i).toString(),
          quantity: q,
          staff: i % 3 == 0 ? '박현우 (강남 대리점 · 사원)' : '김직원 (강남 대리점 · 사원)',
          amount: type == '판매'
              ? i < 5
                    ? 129000
                    : i < 9
                    ? 179000
                    : 242000
              : 0,
          note: type == '고객 수령'
              ? '고객 본인 확인 후 상품을 전달했습니다.'
              : type == '반품 승인'
              ? '반품 상품 검수 후 승인 처리했습니다.'
              : '정상 처리되었습니다.',
          createdAt: today.add(Duration(hours: 9, minutes: i * 13)),
        ),
      );
    }
    return result;
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

  MockOrder orderForPickup(MockPickup pickup) => orders.firstWhere(
    (o) => o.id == pickup.orderId,
    orElse: () => orders.first,
  );
  MockProduct productForOrder(MockOrder order) => products.firstWhere(
    (p) => p.id == order.productId,
    orElse: () => products.first,
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
      orElse: () => orders.first,
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
      orElse: () => orders.first,
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
      orElse: () => orders.first,
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
