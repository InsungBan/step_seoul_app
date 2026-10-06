import 'package:flutter/material.dart';
import 'hq_fields.dart';
import 'hq_palette.dart';
import 'hq_repository.dart';
import 'hq_view_data.dart';
import 'hq_charts.dart';
import 'hq_create_record_dialog.dart';

class HqConsole extends StatefulWidget {
  const HqConsole({super.key, this.repository, this.currentEmployeeId});
  final HqRepository? repository;

  /// The logged-in employee ID; the API resolves their role from the DB.
  final String? currentEmployeeId;
  @override
  State<HqConsole> createState() => _HqConsoleState();
}

class _HqConsoleState extends State<HqConsole> {
  late final HqRepository repository;
  HqViewData db = HqViewData({});
  bool loading = true;
  String? error;
  int section = 0, tab = 0, page = 0;
  String query = '', status = '전체 상태';
  final search = TextEditingController();
  final selected = <int>{};
  final selectedShipments = <String, HqRow>{};
  bool dispatching = false;
  String shipmentKey(HqRow row) => [
    'shoe_shoe_id',
    'employee_employee_id',
    'shipment_id',
    'store_store_id',
  ].map((key) => Uri.encodeComponent(row[key].toString())).join('/');
  HqRow? detailRow;
  String? detailType;
  bool writing = false, finalInbox = false;
  DateTimeRange? period;
  static const labels = [
    '대시보드',
    '주문 · 배송',
    '전체 재고',
    '품의 관리',
    '발주 · 수주',
    '판매 현황',
    '기준 정보',
  ];
  static const subtitles = [
    '판매 · 재고 · 품의 · 발주 현황을 한 화면에서 확인합니다.',
    '고객 주문 접수부터 대리점 배송, 수령, 반품까지 관리합니다.',
    '본사 및 각 대리점의 신발 재고 현황을 제품별, 대리점별로 확인합니다.',
    '재고 부족에 따른 발주 품의서를 작성하고 진행 상태를 확인합니다.',
    '승인된 품의를 기반으로 제조사 발주와 수주 현황을 관리합니다.',
    '제품별, 대리점별, 기간별 판매 성과를 분석합니다.',
    '사용자, 직원, 대리점, 신발, 제조사 등의 기준 데이터를 관리합니다.',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.local_shipping_outlined,
    Icons.grid_view,
    Icons.description_outlined,
    Icons.inventory_2_outlined,
    Icons.bar_chart,
    Icons.my_location,
  ];
  List<(String, String)> get tabs => switch (section) {
    1 => [
      ('주문 목록', 'purchase'),
      ('배송 현황', 'shipment'),
      ('수령 현황', 'receive'),
      ('반품 현황', 'return_record'),
      ('회수 현황', 'recall'),
    ],
    2 => [('상품별 재고', 'shoe')],
    3 => [
      ('품의서 목록', 'approval'),
      ('결재 대기', 'pending'),
      ('승인 완료', 'approved'),
      ('반려', 'rejected'),
    ],
    4 => [('발주 목록', 'purchase_order'), ('수주 현황', 'get_order')],
    6 => [
      ('사용자 관리', 'user'),
      ('직원 관리', 'employee'),
      ('대리점 관리', 'store'),
      ('신발 정보', 'shoe'),
      ('제조사 정보', 'shoe_manufacturer'),
    ],
    _ => [],
  };
  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? HqRepository();
    reload();
  }

  @override
  void dispose() {
    search.dispose();
    proposalTitle.dispose();
    proposalContent.dispose();
    proposalAmount.dispose();
    if (widget.repository == null) repository.close();
    super.dispose();
  }

  Future<void> reload() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await repository.load(
        start: period?.start,
        end: period?.end,
      );
      if (!mounted) return;
      setState(() {
        db = HqViewData(data);
        selectedShipments.clear();
        loading = false;
        detailRow = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'DB 데이터를 불러오지 못했습니다. API 서버 연결을 확인해 주세요.';
      });
    }
  }

  void navigate(int index) => setState(() {
    section = index;
    tab = index == 6 ? 2 : 0;
    page = 0;
    query = '';
    status = '전체 상태';
    search.clear();
    selected.clear();
    selectedShipments.clear();
    proposalProducts.clear();
    detailRow = null;
    writing = false;
    finalInbox = false;
    period = null;
  });
  String text(dynamic v) => db.text(v);
  String money(num? v) => v == null ? hqMissing : '${hqNumber(v)}원';
  String amount(num? v, [String unit = '개']) =>
      v == null ? hqMissing : '${hqNumber(v)}$unit';
  HqRow? report(String name) {
    final values = db.rows('hq_reports');
    if (values.isEmpty || values.first[name] is! Map) return null;
    return Map<String, dynamic>.from(values.first[name] as Map);
  }

  List<HqRow> reportRows(String name) {
    final value = report(name);
    if (value == null ||
        value['available'] != true ||
        value['result'] is! List) {
      return [];
    }
    return (value['result'] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();
  }

  String reportCount(String name, String unit) =>
      report(name)?['available'] == true
      ? '${reportRows(name).length}$unit'
      : hqMissing;
  String reportValue(String name, String field, String unit) {
    final rows = reportRows(name);
    if (rows.isEmpty) return hqMissing;
    final value = db.number(rows.first[field]);
    return value == null
        ? hqMissing
        : unit == '%'
        ? '${value.toStringAsFixed(1)}%'
        : amount(value, unit);
  }

  Widget reportChart(
    String name,
    String label,
    String value, {
    bool currency = false,
  }) {
    final rows = reportRows(name);
    if (rows.isEmpty) return empty();
    final values = <String, num>{};
    for (final row in rows) {
      final n = db.number(row[value]);
      if (n != null) values[text(row[label])] = n;
    }
    return values.isEmpty
        ? empty()
        : HqBarChart(values: values, money: currency);
  }

  Widget reportList(String name) {
    final rows = reportRows(name);
    if (rows.isEmpty) return empty();
    if (name == 'final-approvals') {
      return Column(
        children: rows
            .map(
              (r) => ListTile(
                title: Text(text(r['approval_name'])),
                subtitle: Text(text(r['employee_name'])),
                trailing: pill(text(r['approval_status'])),
                onTap: () => setState(() {
                  detailRow = r;
                  detailType = 'approval';
                }),
              ),
            )
            .toList(),
      );
    }
    return Column(
      children: rows
          .map(
            (r) => ListTile(
              title: Text(text(r['movement_id'] ?? r['order_id'])),
              subtitle: Text(text(r['changed_at'] ?? r['order_date'])),
            ),
          )
          .toList(),
    );
  }

  Widget empty() => const SizedBox(
    height: 150,
    child: Center(
      child: Text(hqMissing, style: TextStyle(color: HqPalette.muted)),
    ),
  );
  Widget pill(String value) {
    final c =
        value.contains('반려') || value.contains('부족') || value.contains('지연')
        ? HqPalette.red
        : value.contains('완료') || value == '승인' || value == '정상'
        ? HqPalette.green
        : value.contains('대기') || value == '주의'
        ? HqPalette.orange
        : HqPalette.purple;
    if (value == hqMissing) {
      return Text(
        value,
        style: const TextStyle(fontSize: 11, color: HqPalette.muted),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget panel(String title, Widget body, {String? subtitle, Widget? action}) =>
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: HqPalette.line),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: HqPalette.ink,
                      ),
                    ),
                  ),
                  ?action,
                ],
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: HqPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      );
  Widget pair(Widget left, Widget right, {bool equalHeight = false}) =>
      LayoutBuilder(
        builder: (context, b) {
          if (b.maxWidth < 800) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, right],
            );
          }
          final row = Row(
            crossAxisAlignment: equalHeight
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          );
          return equalHeight ? IntrinsicHeight(child: row) : row;
        },
      );
  Widget sidebar(bool drawer) => Material(
    color: HqPalette.navy,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 30, 20, 32),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6353FF), HqPalette.purple],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.show_chart,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP HQ',
                          style: TextStyle(color: Colors.white, fontSize: 22),
                        ),
                        Text(
                          'EXECUTIVE CONSOLE',
                          style: TextStyle(
                            color: Color(0xFF99B7D7),
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 28, bottom: 18),
              child: Text(
                'MANAGEMENT',
                style: TextStyle(
                  color: Color(0xFF99B7D7),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: List.generate(
                labels.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    tileColor: section == i ? HqPalette.purple : null,
                    leading: Icon(
                      icons[i],
                      color: section == i
                          ? Colors.white
                          : const Color(0xFFAACAE4),
                    ),
                    title: Text(
                      labels[i],
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                    onTap: () {
                      navigate(i);
                      if (drawer) Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ),
          const Divider(color: Color(0xFF293C54), indent: 24, endIndent: 24),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('로그인 사용자', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              hqMissing,
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
  String get title => writing
      ? '품의서 작성'
      : finalInbox && detailRow == null
      ? '최종결재함'
      : detailRow != null
      ? switch (detailType) {
          'purchase' => '주문 상세',
          'shoe' => '상품 재고 상세',
          'purchase_order' => '발주 상세',
          _ => '상세 정보',
        }
      : section == 0
      ? '본사 임원 대시보드'
      : labels[section];
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final wide = size.maxWidth >= 1000;
      return Scaffold(
        backgroundColor: HqPalette.canvas,
        drawer: wide ? null : Drawer(child: sidebar(true)),
        body: Row(
          children: [
            if (wide) SizedBox(width: 230, child: sidebar(false)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(size.maxWidth < 600 ? 16 : 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!wide)
                          Builder(
                            builder: (c) => IconButton(
                              onPressed: () => Scaffold.of(c).openDrawer(),
                              icon: const Icon(Icons.menu),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: HqPalette.ink,
                            ),
                          ),
                        ),
                        if (size.maxWidth > 750)
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.schedule, size: 18),
                            label: Text(db.day(DateTime.now())),
                          ),
                        IconButton(
                          tooltip: '알림',
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('알림'),
                              content: const Text(hqMissing),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('닫기'),
                                ),
                              ],
                            ),
                          ),
                          icon: const Icon(Icons.notifications_none),
                        ),
                        IconButton(
                          tooltip: '새로고침',
                          onPressed: loading ? null : reload,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: Text(
                        subtitles[section],
                        style: const TextStyle(
                          color: HqPalette.muted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (loading)
                      const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      panel(
                        '연결 오류',
                        Column(
                          children: [
                            Text(error!),
                            FilledButton(
                              onPressed: reload,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    else if (writing)
                      proposalForm()
                    else if (detailRow != null)
                      detailPage()
                    else if (finalInbox)
                      inbox()
                    else ...[
                      metrics(),
                      if (section == 0)
                        dashboard()
                      else if (section == 5)
                        sales()
                      else ...[
                        if (section == 2) stockCharts(),
                        tabBar(),
                        filters(),
                        tableArea(),
                        const SizedBox(height: 16),
                        footerPanels(),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget metrics() {
    final today = DateUtils.dateOnly(DateTime.now());
    final todayPaid = db.paymentsBetween(
      today,
      today.add(const Duration(days: 1)),
    );
    final monthPaid = db.paymentsBetween(
      DateTime(today.year, today.month),
      today.add(const Duration(days: 1)),
    );
    final approvals = db.rows('approval');
    String stateCount(String state) => approvals.isEmpty
        ? hqMissing
        : '${approvals.where((r) => text(db.latestApproval(r['approval_id'])?['approval_status']).contains(state)).length}건';
    final items = switch (section) {
      1 =>
        tab == 1
            ? [
                (Icons.local_shipping_outlined, '전체 배송', db.count('shipment')),
                (
                  Icons.local_shipping_outlined,
                  '배송중',
                  statusCount('shipment', 'delivery_status', '배송중'),
                ),
                (
                  Icons.storefront,
                  '대리점 도착',
                  statusCount('shipment', 'delivery_status', '대리점도착'),
                ),
                (
                  Icons.check,
                  '배송완료',
                  statusCount('shipment', 'delivery_status', '배송완료'),
                ),
              ]
            : tab == 2
            ? [
                (Icons.people_outline, '수령 대상', db.count('receive')),
                (
                  Icons.schedule,
                  '수령 대기',
                  statusCount('receive', 'receive_status', '수령대기'),
                ),
                (Icons.check, '수령 완료', reportCount('completed-receipts', '건')),
              ]
            : tab >= 3
            ? [
                (
                  Icons.assignment_return_outlined,
                  '전체 반품',
                  db.count('return_record'),
                ),
                (Icons.inventory, '회수 기록', db.count('recall')),
                (Icons.currency_exchange, '환불 기록', db.count('refund')),
              ]
            : [
                (Icons.shopping_cart_outlined, '전체 주문', db.count('purchase')),
                (
                  Icons.local_shipping_outlined,
                  '배송중',
                  statusCount('shipment', 'delivery_status', '배송중'),
                ),
                (
                  Icons.storefront,
                  '대리점 도착',
                  statusCount('shipment', 'delivery_status', '대리점도착'),
                ),
                (Icons.check, '수령 완료', reportCount('completed-receipts', '건')),
                (Icons.assignment_return, '전체 반품', db.count('return_record')),
              ],
      2 => [
        (
          Icons.inventory_2_outlined,
          '전체 상품 수',
          amount(db.rows('shoe').isEmpty ? null : db.rows('shoe').length),
        ),
        (
          Icons.layers_outlined,
          '총 재고 수량',
          amount(db.sum(db.rows('shoe'), 'stock_quantity')),
        ),
        (
          Icons.warning_amber,
          '재고 30% 미만',
          amount(db.rows('shoe').isEmpty ? null : db.lowStock.length),
        ),
        (
          Icons.shopping_cart_outlined,
          '자동 발주 대상',
          reportCount('auto-order-targets', '개'),
        ),
        (
          Icons.move_to_inbox_outlined,
          '월간 입고량',
          reportValue('monthly-inbound', 'quantity', '개'),
        ),
      ],
      3 => [
        (Icons.description_outlined, '전체 품의서', db.count('approval')),
        (Icons.schedule, '결재 대기', stateCount('대기')),
        (Icons.check, '승인 완료', stateCount('승인')),
        (Icons.close, '반려', stateCount('반려')),
      ],
      4 => [
        (Icons.description_outlined, '전체 발주', db.count('purchase_order')),
        (Icons.inventory_2_outlined, '수주 기록', db.count('get_order')),
      ],
      5 => [
        (
          Icons.currency_exchange,
          '오늘 매출',
          money(db.sum(todayPaid, 'payment_amount')),
        ),
        (
          Icons.calendar_month,
          '월간 매출',
          money(db.sum(monthPaid, 'payment_amount')),
        ),
        (Icons.inventory, '판매 수량', amount(monthSoldQuantity())),
        (
          Icons.assignment_return,
          '반품률',
          reportValue('return-rate', 'rate', '%'),
        ),
        (Icons.emoji_events_outlined, '인기 상품', topName()),
      ],
      6 => [
        (
          Icons.person_outline,
          '사용자 수',
          amount(db.rows('user').isEmpty ? null : db.rows('user').length, '명'),
        ),
        (
          Icons.people_outline,
          '직원 수',
          amount(
            db.rows('employee').isEmpty ? null : db.rows('employee').length,
            '명',
          ),
        ),
        (
          Icons.storefront,
          '대리점 수',
          amount(db.rows('store').isEmpty ? null : db.rows('store').length),
        ),
        (
          Icons.inventory_2_outlined,
          '등록 상품 수',
          amount(db.rows('shoe').isEmpty ? null : db.rows('shoe').length),
        ),
      ],
      _ => [
        (
          Icons.bar_chart,
          '오늘 판매금액',
          money(db.sum(todayPaid, 'payment_amount')),
        ),
        (Icons.shopping_cart_outlined, '결제완료 주문', paidOrders()),
        (
          Icons.warning_amber,
          '재고 30% 미만',
          amount(db.rows('shoe').isEmpty ? null : db.lowStock.length),
        ),
        (Icons.schedule, '최종결재 대기', reportCount('final-approvals', '건')),
      ],
    };
    return LayoutBuilder(
      builder: (c, b) {
        final singleRow =
            section == 0 ||
            section == 3 ||
            section == 6 ||
            (section == 1 && tab == 1);
        final n = singleRow
            ? 4
            : b.maxWidth > 1150
            ? items.length
            : b.maxWidth > 650
            ? 3
            : b.maxWidth > 420
            ? 2
            : 1;
        return Wrap(
          spacing: 12,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final narrow = singleRow && (b.maxWidth - 36) / 4 < 240;
            final color = [
              HqPalette.purple,
              Colors.blue,
              HqPalette.orange,
              HqPalette.green,
              HqPalette.red,
            ][i % 5];
            return SizedBox(
              width: (b.maxWidth - (n - 1) * 12) / n,
              child: Container(
                constraints: const BoxConstraints(minHeight: 136),
                margin: const EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(narrow ? 8 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: HqPalette.line),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!narrow)
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.$1, color: color, size: 26),
                      ),
                    if (!narrow) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 15),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.$3,
                              style: TextStyle(
                                fontSize: item.$3 == hqMissing ? 12 : 23,
                                fontWeight: FontWeight.w800,
                                color: item.$3 == hqMissing
                                    ? HqPalette.muted
                                    : HqPalette.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            item.$2 == '반품률'
                                ? '기간 반품건수 / 결제완료 구매건수'
                                : item.$2 == '월간 입고량'
                                ? '이번 달 수주일자 기준'
                                : '현재 등록 내역',
                            style: TextStyle(
                              fontSize: 10,
                              color: HqPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  String paidOrders() {
    final ids = db.paid.map((r) => r['payment_id']).toSet();
    return db.rows('purchase').isEmpty
        ? hqMissing
        : '${db.rows('purchase').where((r) => ids.contains(r['payment_id'])).length}건';
  }

  String statusCount(String table, String field, String value) =>
      db.rows(table).isEmpty || db.rows(table).any((row) => row[field] == null)
      ? hqMissing
      : '${db.rows(table).where((r) => r[field].toString().replaceAll(' ', '') == value.replaceAll(' ', '')).length}건';
  num? monthSoldQuantity() {
    final now = DateUtils.dateOnly(DateTime.now());
    final products = db.bestProducts(
      DateTime(now.year, now.month),
      now.add(const Duration(days: 1)),
    );
    return products.isEmpty
        ? null
        : products.fold<num>(0, (sum, row) => sum + (row['quantity'] as num));
  }

  String topName() {
    final range = salesRange;
    final top = db.bestProducts(
      range.start,
      range.end.add(const Duration(days: 1)),
    );
    return top.isEmpty
        ? hqMissing
        : db.name('shoe', 'shoe_id', top.first['shoe_shoe_id'], 'brand_name');
  }

  DateTimeRange get salesRange {
    final now = DateUtils.dateOnly(DateTime.now());
    return period ??
        DateTimeRange(start: DateTime(now.year, now.month), end: now);
  }

  Widget tabBar() => Row(
    children: [
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              tabs.length,
              (i) => TextButton(
                onPressed: () => setState(() {
                  tab = i;
                  page = 0;
                  status = '전체 상태';
                  selected.clear();
                  selectedShipments.clear();
                }),
                style: TextButton.styleFrom(
                  foregroundColor: tab == i
                      ? HqPalette.purple
                      : HqPalette.muted,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: tab == i ? HqPalette.purple : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[i].$1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      if (section == 3)
        FilledButton.icon(
          onPressed: () => setState(() {
            writing = true;
            proposalEmployeeId =
                db
                    .rows('employee')
                    .any(
                      (employee) =>
                          employee['employee_id'].toString() ==
                          widget.currentEmployeeId,
                    )
                ? widget.currentEmployeeId
                : null;
            proposalCreatedAt = DateTime.now().toUtc().add(
              const Duration(hours: 9),
            );
            page = 0;
          }),
          icon: const Icon(Icons.add),
          label: const Text('품의서 작성'),
        ),
      if (section == 1 && activeType == 'shipment')
        FilledButton.icon(
          onPressed: dispatching || selectedShipments.isEmpty
              ? null
              : dispatchSelected,
          icon: const Icon(Icons.local_shipping_outlined),
          label: Text(
            dispatching ? '처리 중...' : '배송 (${selectedShipments.length})',
          ),
        ),
      if (section == 6 && ['employee', 'store'].contains(activeType))
        FilledButton.icon(
          onPressed: () => addMasterRecord(activeType),
          icon: const Icon(Icons.add),
          label: Text(activeType == 'employee' ? '직원 추가' : '대리점 추가'),
        ),
    ],
  );
  Future<void> pickPeriod() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: period,
    );
    if (result != null && mounted) {
      setState(() {
        period = result;
        page = 0;
      });
      await reload();
    }
  }

  Future<void> dispatchSelected() async {
    if (dispatching || selectedShipments.isEmpty) return;
    final rows = selectedShipments.values.toList();
    setState(() => dispatching = true);
    try {
      await repository.dispatchShipments(rows);
      if (!mounted) return;
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${rows.length}건을 배송 중으로 변경했습니다.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('배송 처리에 실패했습니다. 서버 연결과 선택한 배송 정보를 확인해 주세요.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => dispatching = false);
    }
  }

  Future<void> addMasterRecord(String type) async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => HqCreateRecordDialog(
        repository: repository,
        type: type,
        occupiedDistricts: db
            .rows('store')
            .map((row) => row['district_name']?.toString().trim())
            .whereType<String>()
            .toSet(),
      ),
    );
    if (created == true && mounted) {
      await reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('추가되었습니다.')));
      }
    }
  }

  Widget filters() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: LayoutBuilder(
      builder: (c, b) => Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: b.maxWidth > 650 ? 320 : b.maxWidth,
            child: TextField(
              controller: search,
              decoration: const InputDecoration(
                hintText: '번호, 상품명, 고객명으로 검색...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() {
                query = v.trim().toLowerCase();
                page = 0;
              }),
            ),
          ),
          if (section != 5)
            DropdownButton<String>(
              value: status,
              items: [
                '전체 상태',
                ...availableStatuses(),
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() {
                status = v!;
                page = 0;
              }),
            ),
          OutlinedButton.icon(
            onPressed: pickPeriod,
            icon: const Icon(Icons.calendar_month, size: 18),
            label: Text(
              period == null
                  ? '기간 선택'
                  : '${db.day(period!.start)} → ${db.day(period!.end)}',
            ),
          ),
          FilledButton.icon(
            onPressed: () => setState(() => page = 0),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('검색'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final hadPeriod = period != null;
              setState(() {
                query = '';
                search.clear();
                status = '전체 상태';
                period = null;
                page = 0;
              });
              if (hadPeriod) await reload();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('초기화'),
          ),
        ],
      ),
    ),
  );
  String get activeType => finalInbox
      ? 'approval'
      : tabs.isEmpty
      ? 'shoe'
      : tabs[tab].$2;
  Set<String> availableStatuses() => sourceRows()
      .map((r) => rowStatus(activeType, r))
      .where((s) => s != hqMissing)
      .toSet();
  String rowStatus(String type, HqRow row) => switch (type) {
    'shoe' => db.stockStatus(row),
    'approval' || 'pending' || 'approved' || 'rejected' => text(
      db.latestApproval(row['approval_id'])?['approval_status'],
    ),
    'shipment' => text(row['delivery_status']),
    'receive' => text(row['receive_status']),
    'get_order' || 'inbound' => text(row['get_order_status']),
    _ => hqMissing,
  };
  List<HqRow> sourceRows() {
    final type = activeType;
    if (['pending', 'approved', 'rejected'].contains(type)) {
      final key = {'pending': '대기', 'approved': '승인', 'rejected': '반려'}[type]!;
      return db
          .rows('approval')
          .where(
            (r) => text(
              db.latestApproval(r['approval_id'])?['approval_status'],
            ).contains(key),
          )
          .toList();
    }
    if (type == 'mine' || type == 'inbound') return [];
    return db.rows(type);
  }

  Map<String, String> columns(String type) => switch (type) {
    'purchase' => {
      'purchase_id': '주문번호',
      '_order_date': '결제일자',
      'user_user_id': '고객명',
      'shoe_shoe_id': '상품정보',
      '_shoe_code': '신발코드',
      'quantity': '수량',
      '_total': '상품 금액',
      '_store': '선택 대리점',
      '_payment': '결제상태',
      '_delivery': '배송상태',
      '_receive': '수령상태',
    },
    'shipment' => {
      'shipment_id': '발송번호',
      '_order': '주문번호',
      'shoe_shoe_id': '상품정보',
      'delivery_quantity': '수량',
      'store_store_id': '도착 대리점',
      'delivery_status': '배송상태',
    },
    'receive' => {
      'receive_id': '수령번호',
      'receive_payment_id': '결제번호',
      'user_user_id': '고객명',
      '_product': '상품정보',
      'store_store_id': '선택 대리점',
      'receive_verification_status': '인증상태 코드',
      'receive_status': '수령상태',
      'employee_employee_id': '담당자',
      'receive_date': '수령일시',
    },
    'return_record' => {
      'return_id': '반품번호',
      '_order': '주문번호',
      '_customer': '고객명',
      'shoe_shoe_id': '상품정보',
      '_reason': '반품 사유',
      '_store': '접수 대리점',
      'return_date': '요청일',
      '_inspection': '검수상태',
      '_refund': '환불상태',
      'employee_employee_id': '담당자',
    },
    'shoe' => {
      'brand_name': '상품정보',
      'shoe_id': '제품코드',
      if (section == 6) 'shoe_price': '가격',
      '_category': '카테고리',
      '_manufacturer': '제조사',
      'standard_stock': '기준재고',
      'stock_quantity': '현재재고',
      '_ratio': '재고비율',
      '_stock': '재고상태',
    },
    'approval' || 'pending' || 'approved' || 'rejected' => {
      'approval_id': '품의번호',
      '_created': '작성일자',
      'approval_name': '제목 / 신청 사유',
      '_requested_amount': '신청 금액',
      '_author': '결재 담당 직원',
      '_stage': '현재 단계',
      '_approval': '결재 상태',
    },
    'purchase_order' => {
      'order_id': '발주번호',
      'order_date': '발주일자',
      'shoe_manufacturer_manufacturer_id': '제조사',
      'shoe_shoe_id': '품목',
      'order_quantity': '발주수량',
      'get_amount': '발주금액',
    },
    'store' => {
      'store_id': '대리점 ID',
      'agency_name': '대리점명',
      'district_name': '지역 / 자치구',
      'phone': '연락처',
    },
    'manufacturing' => {
      'manufacturing_id': '제조번호',
      'shoe_shoe_id': '상품',
      'shoe_manufacturer_manufacturer_id': '제조사',
      'manufacturing_date': '제조일',
    },
    'recall' => {
      'recall_id': '회수번호',
      'store_store_id': '대리점',
      'user_user_id': '고객',
      'recall_quantity': '회수수량',
      'recall_date': '회수일',
      'employee_employee_id': '담당 직원',
    },
    'refund' => {
      'refund_id': '환불번호',
      'user_user_id': '고객',
      'refund_amount': '환불금액',
      'refund_quantity': '수량',
      'refund_reason': '사유',
      '_status': '환불상태',
    },
    _ => hqFields[type] ?? {},
  };
  String display(String type, HqRow row, String field) {
    if (field == '_shoe_code') return text(row['shoe_shoe_id']);
    if (field == '_size' || field == '_color') {
      final options = db.shoeCodeOptions(row['shoe_shoe_id']);
      return text(options?[field == '_size' ? 'size' : 'color']);
    }
    if (field == '_product' && type == 'receive') {
      return db.receivedProducts(row);
    }
    if (field == '_order' && type == 'shipment') {
      return text(db.shipmentOrder(row)?['purchase_id']);
    }
    if (field == '_refund' && type == 'return_record') {
      return db.returnRefundStatus(row);
    }
    if (field == '_category') return text(row['shoe_category']);
    if (field == '_ratio') {
      final r = db.ratio(row);
      return r == null ? hqMissing : '${(r * 100).toStringAsFixed(0)}%';
    }
    if (field == '_stock') return db.stockStatus(row);
    if (field == '_manufacturer') return db.manufacturerFor(row['shoe_id']);
    if (field == '_total') {
      final q = db.number(row['quantity']);
      final p = db.number(row['sale_price']);
      return money(q == null || p == null ? null : q * p);
    }
    if (field == '_order_date') return text(db.payment(row)?['payment_date']);
    if (field == '_payment') {
      return text(db.payment(row)?['payment_status']) == hqMissing
          ? hqMissing
          : db.payment(row)?['payment_status'].toString() == '1'
          ? '결제완료'
          : '상태 코드 ${db.payment(row)?['payment_status']}';
    }
    if (field == '_created') {
      return text(row['approval_date']);
    }
    if (field == '_requested_amount') {
      if (row['requested_amount'] != null) {
        return money(db.number(row['requested_amount']));
      }
      final orders = db
          .rows('purchase_order')
          .where((r) => r['approval_approval_id'] == row['approval_id'])
          .toList();
      return money(db.sum(orders, 'get_amount'));
    }
    if (field == '_store') {
      return type == 'purchase'
          ? db.name('store', 'store_id', row['store_store_id'], 'agency_name')
          : hqMissing;
    }
    if (field == '_delivery') return db.deliveryStatus(row);
    if (field == '_receive') return db.receiveStatus(row);
    if (field == '_author') {
      return db.name(
        'employee',
        'employee_id',
        db.latestApproval(row['approval_id'])?['employee_employee_id'],
        'employee_name',
      );
    }
    if (field == '_approval') {
      return text(db.latestApproval(row['approval_id'])?['approval_status']);
    }
    if (field == '_stage') {
      final p = db.latestApproval(row['approval_id']);
      return p == null
          ? hqMissing
          : '팀장: ${text(p['team_leader_approval'])} / 이사: ${text(p['director_approval'])}';
    }
    if (field.startsWith('_')) return hqMissing;
    final ref = switch (field) {
      'shoe_shoe_id' => ('shoe', 'shoe_id', 'brand_name'),
      'user_user_id' => ('user', 'user_id', 'user_name'),
      'store_store_id' => ('store', 'store_id', 'agency_name'),
      'employee_employee_id' => ('employee', 'employee_id', 'employee_name'),
      'shoe_manufacturer_manufacturer_id' => (
        'shoe_manufacturer',
        'manufacturer_id',
        'manufacturer_name',
      ),
      _ => null,
    };
    if (ref != null) return db.name(ref.$1, ref.$2, row[field], ref.$3);
    if ([
      'shoe_price',
      'sale_price',
      'get_amount',
      'refund_amount',
    ].contains(field)) {
      return money(db.number(row[field]));
    }
    return text(row[field]);
  }

  Widget tableArea() => panel(
    '',
    dataTable(
      activeType,
      sourceRows(),
      columns(activeType),
      showSelection:
          activeType == 'shipment' || ![1, 2, 3, 4, 6].contains(section),
      isRowSelected: activeType == 'shipment'
          ? (row) => selectedShipments.containsKey(shipmentKey(row))
          : null,
      onRowSelected: activeType == 'shipment'
          ? (row, checked) => setState(() {
              final key = shipmentKey(row);
              if (checked) {
                selectedShipments[key] = row;
              } else {
                selectedShipments.remove(key);
              }
            })
          : null,
      fillWidth:
          (section == 1 && activeType == 'shipment') ||
          section == 4 ||
          (section == 6 &&
              ['employee', 'shoe_manufacturer'].contains(activeType)),
      onOpen: (r) => setState(() {
        detailRow = r;
        detailType = ['pending', 'approved', 'rejected'].contains(activeType)
            ? 'approval'
            : activeType;
      }),
    ),
  );
  Widget dataTable(
    String type,
    List<HqRow> source,
    Map<String, String> cols, {
    void Function(HqRow)? onOpen,
    bool compact = false,
    bool fillWidth = false,
    bool showSelection = true,
    Set<String>? selectedProducts,
    void Function(HqRow, bool)? onProductSelected,
    bool Function(HqRow)? isRowSelected,
    void Function(HqRow, bool)? onRowSelected,
  }) {
    final filtered = source.where((r) {
      if (!writing &&
          query.isNotEmpty &&
          !cols.keys.any(
            (f) => display(type, r, f).toLowerCase().contains(query),
          )) {
        return false;
      }
      if (!writing && status != '전체 상태' && rowStatus(type, r) != status) {
        return false;
      }
      if (!writing && period != null && !compact) {
        final dateField = switch (type) {
          'purchase' => 'payment_date',
          'shipment' => null,
          'approval' ||
          'pending' ||
          'approved' ||
          'rejected' => 'approval_date',
          'shoe' => null,
          _ => cols.keys.where((k) => k.endsWith('_date')).firstOrNull,
        };
        final d = db.date(
          type == 'purchase'
              ? (db.payment(r)?['payment_date'])
              : ['approval', 'pending', 'approved', 'rejected'].contains(type)
              ? r['approval_date']
              : (dateField == null ? null : r[dateField]),
        );
        if (d == null ||
            d.isBefore(period!.start) ||
            !d.isBefore(period!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
    if (filtered.isEmpty) return empty();
    final maxPage = (filtered.length - 1) ~/ 8;
    final safePage = compact ? 0 : page.clamp(0, maxPage);
    final visible = filtered.skip(safePage * 8).take(compact ? 5 : 8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: fillWidth
                    ? constraints.maxWidth.clamp(
                        0.0,
                        MediaQuery.sizeOf(context).width,
                      )
                    : 0,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF2F6FF),
                ),
                headingRowHeight: 40,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                columnSpacing: 24,
                horizontalMargin: 12,
                columns: [
                  if (!compact && showSelection)
                    const DataColumn(label: Text('선택')),
                  ...cols.values.map(
                    (v) => DataColumn(
                      label: Text(
                        v,
                        style: const TextStyle(
                          color: HqPalette.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  if (onOpen != null) const DataColumn(label: Text('작업')),
                ],
                rows: List.generate(visible.length, (i) {
                  final row = visible[i];
                  return DataRow(
                    cells: [
                      if (!compact && showSelection)
                        DataCell(
                          Checkbox(
                            value: isRowSelected != null
                                ? isRowSelected(row)
                                : selectedProducts != null
                                ? selectedProducts.contains(
                                    row['shoe_id'].toString(),
                                  )
                                : selected.contains(safePage * 8 + i),
                            onChanged: dispatching
                                ? null
                                : onRowSelected != null
                                ? (v) => onRowSelected(row, v == true)
                                : onProductSelected != null
                                ? (v) => onProductSelected(row, v == true)
                                : (v) => setState(() {
                                    v == true
                                        ? selected.add(safePage * 8 + i)
                                        : selected.remove(safePage * 8 + i);
                                  }),
                          ),
                        ),
                      ...cols.keys.map((f) {
                        final v = display(type, row, f);
                        return DataCell(
                          SizedBox(
                            width: v == hqMissing
                                ? 115
                                : f.contains('name')
                                ? 170
                                : null,
                            child:
                                f.contains('status') ||
                                    f == '_stock' ||
                                    f == '_approval'
                                ? pill(v)
                                : Text(
                                    v,
                                    style: TextStyle(
                                      fontSize: v == hqMissing ? 10 : 12,
                                      color: v == hqMissing
                                          ? HqPalette.muted
                                          : HqPalette.ink,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        );
                      }),
                      if (onOpen != null)
                        DataCell(
                          OutlinedButton(
                            onPressed: () => onOpen(row),
                            child: const Text(
                              '상세보기',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '전체 ${filtered.length}건 중 ${safePage * 8 + 1}–${safePage * 8 + visible.length}건 표시',
                    style: const TextStyle(
                      color: HqPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: safePage > 0
                      ? () => setState(() => page = safePage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${safePage + 1}'),
                IconButton(
                  onPressed: safePage < maxPage
                      ? () => setState(() => page = safePage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget process(String title, List<(IconData, String)> steps) => panel(
    title,
    Wrap(
      spacing: 20,
      runSpacing: 16,
      children: List.generate(
        steps.length,
        (i) => SizedBox(
          width: 110,
          child: Column(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFEFEDFF),
                child: Icon(steps[i].$1, color: HqPalette.purple, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                '${i + 1}'.padLeft(2, '0'),
                style: const TextStyle(color: HqPalette.muted, fontSize: 10),
              ),
              Text(
                steps[i].$2,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget dashboard() {
    final now = DateUtils.dateOnly(DateTime.now());
    final days = db.salesDays(
      now.subtract(const Duration(days: 6)),
      now.add(const Duration(days: 1)),
    );
    return Column(
      children: [
        pair(
          panel(
            '최근 7일 판매금액',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days.isEmpty
                      ? hqMissing
                      : money(days.values.fold<num>(0, (a, b) => a + b)),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                days.isEmpty ? empty() : HqLineChart(values: days),
              ],
            ),
            subtitle: '결제 완료 기준 · 실제 결제일별 집계',
          ),
          panel(
            '최종결재 대기',
            Column(
              children: [
                reportList('final-approvals'),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => finalInbox = true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('최종결재함 열기'),
                  ),
                ),
              ],
            ),
            subtitle: '팀장 승인 후 이사 결재를 기다리는 품의입니다.',
          ),
        ),
        panel(
          '재고 부족 상품',
          dataTable(
            'shoe',
            db.lowStock,
            {
              'brand_name': '상품',
              'stock_quantity': '현재',
              'standard_stock': '기준',
              '_ratio': '재고비율',
              '_manufacturer': '제조사',
            },
            compact: true,
            fillWidth: true,
            onOpen: (r) => setState(() {
              section = 2;
              detailRow = r;
              detailType = 'shoe';
            }),
          ),
          subtitle: '기준재고 대비 30% 미만',
          action: TextButton(
            onPressed: () => navigate(2),
            child: const Text('전체 재고 보기 ›'),
          ),
        ),
      ],
    );
  }

  Widget stockCharts() {
    final valid = db.rows('shoe').where((r) => db.ratio(r) != null).toList();
    final counts = <String, num>{};
    for (final row in valid) {
      final key = db.stockStatus(row);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return pair(
      panel(
        '재고 상태 분포',
        counts.isEmpty ? empty() : HqDonutChart(values: counts),
        subtitle: '상품 수 기준 · 정상 70% 이상 / 주의 30–70% / 부족 30% 미만',
      ),
      panel(
        '카테고리별 재고 현황',
        reportChart('inventory-by-category', 'category', 'quantity'),
      ),
      equalHeight: true,
    );
  }

  Widget footerPanels() => switch (section) {
    2 => const SizedBox.shrink(),
    1 => panel(
      tab >= 3
          ? '반품 사유 분포'
          : tab == 2
          ? '오늘 수령 현황 (대리점별)'
          : '오늘 배송 현황 (대리점별)',
      tab == 2 ? storeReceipts() : empty(),
    ),
    3 => panel(
      '최근 품의서',
      dataTable(
        'approval',
        db.rows('approval').reversed.toList(),
        {'approval_id': '품의번호', 'approval_name': '제목', '_approval': '결재 상태'},
        compact: true,
        fillWidth: true,
      ),
    ),
    4 => panel('제조사별 발주 요약', manufacturerSummary()),
    6 => panel(
      '기준 데이터 현황',
      Wrap(
        spacing: 30,
        runSpacing: 20,
        children: [
          for (final item in [
            ('user', '사용자'),
            ('employee', '직원'),
            ('store', '대리점'),
            ('shoe', '신발 상품'),
            ('shoe_manufacturer', '제조사'),
          ])
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2, style: const TextStyle(color: HqPalette.muted)),
                  Text(
                    amount(
                      db.rows(item.$1).isEmpty ? null : db.rows(item.$1).length,
                      ['user', 'employee'].contains(item.$1) ? '명' : '개',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    _ => panel('자동 발주 이력', reportList('auto-order-history')),
  };
  Widget storeReceipts() {
    final today = DateUtils.dateOnly(DateTime.now());
    final values = <String, num>{};
    for (final row in db.rows('receive')) {
      final d = db.date(row['receive_date']);
      if (d != null &&
          DateUtils.isSameDay(d, today) &&
          row['receive_status'] == '수령완료') {
        final name = db.name(
          'store',
          'store_id',
          row['store_store_id'],
          'agency_name',
        );
        values[name] = (values[name] ?? 0) + 1;
      }
    }
    return values.isEmpty ? empty() : HqBarChart(values: values);
  }

  Widget manufacturerSummary() {
    final values = <String, num>{};
    for (final row in db.rows('purchase_order')) {
      final amount = db.number(row['get_amount']);
      if (amount == null) continue;
      final name = db.name(
        'shoe_manufacturer',
        'manufacturer_id',
        row['shoe_manufacturer_manufacturer_id'],
        'manufacturer_name',
      );
      values[name] = (values[name] ?? 0) + amount;
    }
    return values.isEmpty ? empty() : HqBarChart(values: values, money: true);
  }

  Widget sales() {
    final range = salesRange;
    final days = db.salesDays(
      range.start,
      range.end.add(const Duration(days: 1)),
    );
    final top = db.bestProducts(
      range.start,
      range.end.add(const Duration(days: 1)),
    );
    return Column(
      children: [
        filters(),
        pair(
          panel(
            '일별 판매 매출 추이',
            days.isEmpty ? empty() : HqLineChart(values: days),
            subtitle:
                '${db.day(range.start)} → ${db.day(range.end)} · 결제 완료 기준',
          ),
          panel(
            '카테고리별 판매 매출',
            reportChart(
              'sales-by-category',
              'category',
              'amount',
              currency: true,
            ),
          ),
          equalHeight: true,
        ),
        pair(
          panel(
            '대리점별 판매 매출 순위',
            reportChart(
              'sales-by-store',
              'agency_name',
              'amount',
              currency: true,
            ),
          ),
          panel(
            '인기 판매 상품 TOP 5',
            top.isEmpty
                ? empty()
                : Column(
                    children: List.generate(top.take(5).length, (i) {
                      final row = top[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFEFEDFF),
                          child: Text('${i + 1}'),
                        ),
                        title: Text(
                          db.name(
                            'shoe',
                            'shoe_id',
                            row['shoe_shoe_id'],
                            'brand_name',
                          ),
                        ),
                        subtitle: Text('판매 수량 ${row['quantity']}개'),
                        trailing: Text(money(row['amount'] as num)),
                        onTap: () {
                          final shoe = db.find(
                            'shoe',
                            'shoe_id',
                            row['shoe_shoe_id'],
                          );
                          if (shoe != null) {
                            setState(() {
                              detailRow = shoe;
                              detailType = 'shoe';
                            });
                          }
                        },
                      );
                    }),
                  ),
          ),
          equalHeight: true,
        ),
      ],
    );
  }

  Widget backButton() => Align(
    alignment: Alignment.centerRight,
    child: OutlinedButton.icon(
      onPressed: () => setState(() {
        if (detailRow == null) finalInbox = false;
        detailRow = null;
        writing = false;
      }),
      icon: const Icon(Icons.arrow_back),
      label: const Text('목록으로 돌아가기'),
    ),
  );
  Widget info(Map<String, String> values) => Column(
    children: values.entries
        .map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 125,
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      color: HqPalette.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    e.value,
                    style: TextStyle(
                      fontSize: e.value == hqMissing ? 11 : 13,
                      color: e.value == hqMissing
                          ? HqPalette.muted
                          : HqPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
  Widget detailPage() {
    final r = detailRow!;
    final type = detailType!;
    return Column(
      children: [
        backButton(),
        const SizedBox(height: 16),
        panel(
          type == 'shoe'
              ? text(r['brand_name'])
              : type == 'purchase'
              ? text(r['purchase_id'])
              : type == 'purchase_order'
              ? text(r['order_id'])
              : '상세 정보',
          info({
            for (final field in columns(type).entries)
              if (type != 'approval' || field.key != '_requested_amount')
                field.value: display(type, r, field.key),
          }),
        ),
        if (type == 'purchase') ...[
          process('주문 진행 상태', [
            (Icons.shopping_cart_outlined, '주문 접수'),
            (Icons.payment, '결제 완료'),
            (Icons.local_shipping_outlined, '본사 출고'),
            (Icons.storefront, '대리점 도착'),
            (Icons.check, '수령 완료'),
          ]),
          pair(
            panel(
              '주문 상품 내역',
              dataTable(
                'purchase',
                [r],
                {
                  'shoe_shoe_id': '상품정보',
                  '_size': '사이즈',
                  '_color': '색상',
                  'quantity': '수량',
                  'sale_price': '단가',
                  '_total': '금액',
                },
                compact: true,
              ),
            ),
            panel(
              '고객 정보',
              info({
                '고객명': text(db.customer(r)?['user_name']),
                '연락처': text(db.customer(r)?['user_phone']),
                '이메일': text(db.customer(r)?['user_email']),
                '주소': hqMissing,
              }),
            ),
          ),
        ],
        if (type == 'shoe') ...[
          pair(
            panel('상품 이미지 · 옵션', empty()),
            panel(
              '재고 기준',
              info({
                '기준재고': text(r['standard_stock']),
                '현재재고': text(r['stock_quantity']),
                '재고비율': display(type, r, '_ratio'),
              }),
            ),
          ),
        ],
        if (type == 'purchase_order') ...[
          panel(
            '발주 상품 목록',
            dataTable(
              type,
              [r],
              {
                'shoe_shoe_id': '신발명',
                '_options': '색상 / 사이즈',
                'order_quantity': '발주수량',
                'get_amount': '금액',
              },
              compact: true,
            ),
          ),
        ],
        if (type == 'approval') ...[
          pair(
            panel('신청 사유', Text(text(r['approval_content']))),
            panel(
              '결재 정보',
              info({
                '결재 담당 직원': display(type, r, '_author'),
                '팀장 승인': text(
                  db.latestApproval(r['approval_id'])?['team_leader_approval'],
                ),
                '이사 승인': text(
                  db.latestApproval(r['approval_id'])?['director_approval'],
                ),
              }),
            ),
            equalHeight: true,
          ),
          ...[
            const SizedBox(height: 12),
            finalApprovalButton(r),
            if (widget.currentEmployeeId == null)
              const Text('로그인 사용자 정보 연결 후 직급에 맞게 승인할 수 있습니다.'),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  bool approving = false;

  Future<void> approveFinal(HqRow row) async {
    if (approving || widget.currentEmployeeId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('품의 승인'),
        content: Text('${text(row['approval_name'])} 건을 현재 사용자 직급으로 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('승인'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || approving) return;
    setState(() => approving = true);
    try {
      await repository.approveProposal(
        row['approval_id'].toString(),
        widget.currentEmployeeId!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재 사용자 직급으로 승인되었습니다.')));
      await reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('승인에 실패했습니다. 사용자 직급과 결재 순서, 서버 연결을 확인해 주세요.'),
        ),
      );
    } finally {
      if (mounted) setState(() => approving = false);
    }
  }

  Widget finalApprovalButton(HqRow row) => FilledButton.icon(
    onPressed:
        approving ||
            widget.currentEmployeeId == null ||
            db.latestApproval(row['approval_id']) == null ||
            !['결재대기', '결재중', '진행중'].contains(
              db.latestApproval(row['approval_id'])?['approval_status'],
            )
        ? null
        : () => approveFinal(row),
    icon: const Icon(Icons.check_circle_outline),
    label: Text(approving ? '처리 중...' : '품의 승인'),
  );

  Widget inbox() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      backButton(),
      panel(
        '품의서 및 결재 기록',
        dataTable(
          'approval',
          reportRows('final-approvals'),
          {'approval_id': '품의번호', 'approval_name': '제목', '_approval': '결재 상태'},
          fillWidth: true,
          showSelection: false,
          onOpen: (r) => setState(() {
            detailRow = r;
            detailType = 'approval';
          }),
        ),
      ),
    ],
  );
  final proposalTitle = TextEditingController();
  final proposalContent = TextEditingController();
  final proposalAmount = TextEditingController();
  String? proposalEmployeeId;
  DateTime? proposalCreatedAt;
  final proposalProducts = <String, HqRow>{};
  bool saving = false;
  Future<void> saveProposal() async {
    if (proposalTitle.text.trim().isEmpty ||
        proposalContent.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('품의 제목과 사유를 입력해 주세요.')));
      return;
    }
    if (proposalProducts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('품의를 작성할 상품을 선택해 주세요.')));
      return;
    }
    final requestedAmount = num.tryParse(proposalAmount.text.trim());
    if (proposalEmployeeId == null ||
        requestedAmount == null ||
        !requestedAmount.isFinite ||
        requestedAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결재 담당 직원과 올바른 신청금액을 입력해 주세요.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await repository.createProposal(
        proposalTitle.text.trim(),
        [
          proposalContent.text.trim(),
          '',
          '품의 유형: 재고 보충',
          '요청일: ${DateTime.now().toUtc().add(const Duration(hours: 9)).toIso8601String().replaceAll('Z', '')}',
          '품의 대상 상품:',
          for (final product in proposalProducts.values)
            '- ${text(product['brand_name'])} (제품코드: ${text(product['shoe_id'])})',
        ].join('\n'),
        employeeId: proposalEmployeeId!,
        requestedAmount: proposalAmount.text.trim(),
      );
      if (!mounted) return;
      proposalTitle.clear();
      proposalContent.clear();
      proposalProducts.clear();
      proposalAmount.clear();
      proposalEmployeeId = null;
      setState(() {
        writing = false;
        saving = false;
      });
      await reload();
    } catch (_) {
      if (mounted) {
        setState(() => saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('품의 저장 실패. 서버 연결을 확인해 주세요.')),
        );
      }
    }
  }

  Widget proposalForm() => Column(
    children: [
      backButton(),
      const SizedBox(height: 16),
      Column(
        children: [
          panel(
            '1. 기본 정보',
            Column(
              children: [
                TextField(
                  controller: proposalTitle,
                  maxLength: 45,
                  decoration: const InputDecoration(labelText: '품의 제목 *'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: proposalEmployeeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '결재 담당 직원 *'),
                  items: db
                      .rows('employee')
                      .map(
                        (employee) => DropdownMenuItem(
                          value: employee['employee_id'].toString(),
                          child: Text(
                            '${text(employee['employee_name'])} (${text(employee['employee_id'])})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (value) => setState(() => proposalEmployeeId = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: proposalCreatedAt?.toIso8601String().substring(
                    0,
                    10,
                  ),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '작성일자',
                    helperText: '저장 시 한국 시간 기준 작성일자가 자동 기록됩니다.',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: proposalAmount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: '신청금액 *',
                    suffixText: '원',
                  ),
                ),
              ],
            ),
          ),
          panel(
            '2. 품의 사유',
            TextField(
              controller: proposalContent,
              maxLines: 4,
              decoration: const InputDecoration(hintText: '발주가 필요한 사유를 입력하세요.'),
            ),
          ),
          panel(
            '3. 부족 상품 목록',
            dataTable(
              'shoe',
              db.lowStock,
              {
                'brand_name': '상품명',
                'shoe_id': '제품코드',
                if (section == 6) 'shoe_price': '가격',
                '_manufacturer': '제조사',
                'stock_quantity': '현재재고',
                'standard_stock': '기준재고',
                '_ratio': '재고비율',
              },
              fillWidth: true,
              selectedProducts: proposalProducts.keys.toSet(),
              onProductSelected: (row, checked) => setState(() {
                final id = row['shoe_id'].toString();
                if (checked) {
                  proposalProducts[id] = Map<String, dynamic>.from(row);
                } else {
                  proposalProducts.remove(id);
                }
              }),
            ),
          ),
        ],
      ),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => setState(() => writing = false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: saving ? null : saveProposal,
            child: Text(saving ? '저장 중...' : '품의 저장'),
          ),
        ],
      ),
    ],
  );
}
