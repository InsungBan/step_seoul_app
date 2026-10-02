import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/auth/login.dart';
import 'package:step_seoul_app/view/employee/delivery_inbound.dart';
import 'package:step_seoul_app/view/employee/customer_pickup.dart';
import 'package:step_seoul_app/view/employee/return_reception.dart';
import 'package:step_seoul_app/view/employee/inventory_status.dart';
import 'package:step_seoul_app/view/employee/work_history.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/services/app_state.dart';

const _navy = Color(0xFF14284B),
    _blue = Color(0xFF3268E8),
    _ink = Color(0xFF1C2B43),
    _muted = Color(0xFF7D8BA1),
    _canvas = Color(0xFFF4F7FB),
    _line = Color(0xFFE8EDF4);

class WorkHome extends StatefulWidget {
  const WorkHome({super.key});
  @override
  State<WorkHome> createState() => _WorkHomeState();
}

class _WorkHomeState extends State<WorkHome> {
  int selected = 0;
  String branch = '강남점';
  DateTime selectedDate = DateTime.now().toUtc().add(const Duration(hours: 9));
  bool _isNotificationOpen = false;
  bool _isCalendarOpen = false;
  int? _pendingHistoryId;
  final _activityStore = WorkActivityStore.instance;

  @override
  void initState() {
    super.initState();
    _activityStore.addListener(_onActivityChange);
  }

  void _onActivityChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _activityStore.removeListener(_onActivityChange);
    super.dispose();
  }

  static const menus = [
    ('업무 홈', Icons.grid_view_rounded),
    ('배송 입고', Icons.inventory_2_outlined),
    ('고객 수령', Icons.shopping_bag_outlined),
    ('반품 접수', Icons.assignment_return_outlined),
    ('재고 현황', Icons.stacked_bar_chart_rounded),
    ('업무 내역', Icons.history_rounded),
  ];

  String get date =>
      selectedDate.year.toString() +
      '.' +
      selectedDate.month.toString().padLeft(2, '0') +
      '.' +
      selectedDate.day.toString().padLeft(2, '0');

  Future<void> _openCalendar() async {
    if (_isCalendarOpen) return;
    setState(() => _isCalendarOpen = true);
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _CalendarDialog(initialDate: selectedDate),
    );
    if (!mounted) return;
    setState(() {
      _isCalendarOpen = false;
      if (picked != null) selectedDate = picked;
    });
  }

  Future<void> _openNotifications() async {
    if (_isNotificationOpen) return;
    setState(() => _isNotificationOpen = true);
    final activity = await showDialog<WorkActivity>(
      context: context,
      barrierColor: Colors.black12,
      builder: (_) => const WorkActivityNotifications(),
    );
    if (!mounted) return;
    setState(() {
      _isNotificationOpen = false;
      if (activity != null) {
        _pendingHistoryId = activity.id;
        selected = 5;
      }
    });
    if (activity != null) _activityStore.markAllRead();
  }

  Future<void> logout() async {
    await SessionService.instance.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (_) => false,
      );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Row(
          children: [
            if (wide) sidebar(),
            Expanded(
              child: Column(
                children: [
                  header(wide),
                  Expanded(
                    child: switch (selected) {
                      0 => dashboard(wide),
                      1 => DeliveryInboundPage(branch: branch, date: date),
                      2 => CustomerPickupPage(branch: branch, date: date),
                      3 => ReturnReceptionPage(branch: branch, date: date),
                      4 => const InventoryStatusPage(),
                      5 => WorkHistoryPage(
                        date: date,
                        initialActivityId: _pendingHistoryId,
                      ),
                      _ => placeholder(),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) => setState(() {
                selected = i;
                if (i != 5) _pendingHistoryId = null;
              }),
              destinations: menus
                  .map(
                    (m) => NavigationDestination(icon: Icon(m.$2), label: m.$1),
                  )
                  .toList(),
            ),
    );
  }

  Widget sidebar() => SizedBox(
    width: 245,
    child: Material(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 25, 12, 30),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP PICKUP',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'STORE OPERATIONS',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 9,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(23, 0, 12, 10),
            child: Text('매장 관리', style: TextStyle(color: _muted, fontSize: 11)),
          ),
          ...List.generate(
            menus.length,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: selected == i,
                selectedTileColor: const Color(0xFFEDF3FF),
                leading: Icon(
                  menus[i].$2,
                  color: selected == i ? _blue : _muted,
                  size: 20,
                ),
                title: Text(
                  menus[i].$1,
                  style: TextStyle(
                    color: selected == i ? _blue : _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                onTap: () => setState(() {
                  selected = i;
                  if (i != 5) _pendingHistoryId = null;
                }),
              ),
            ),
          ),
          const Spacer(),
          const Divider(color: _line),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF0FB),
              child: Icon(Icons.person, color: _blue),
            ),
            title: const Text(
              '김직원',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            subtitle: const Text(
              '강남 대리점 · 직원',
              style: TextStyle(fontSize: 10, color: _muted),
            ),
            trailing: IconButton(
              onPressed: logout,
              icon: const Icon(Icons.logout, size: 18, color: _muted),
            ),
          ),
        ],
      ),
    ),
  );
  Widget header(bool wide) => Container(
    height: 74,
    color: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: wide ? 30 : 14),
    child: Row(
      children: [
        if (!wide) const Icon(Icons.local_shipping_rounded, color: _blue),
        if (!wide) const SizedBox(width: 9),
        Expanded(
          child: Text(
            branch.replaceAll('점', '') + ' 대리점 ' + menus[selected].$1,
            style: TextStyle(
              color: _navy,
              fontSize: wide ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _openCalendar,
          icon: const Icon(Icons.calendar_month_outlined, size: 15),
          label: Text(
            date,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          style: TextButton.styleFrom(foregroundColor: _muted),
        ),
        PopupMenuButton<String>(
          onSelected: (v) => setState(() => branch = v),
          itemBuilder: (_) => [
            '강남점',
            '홍대점',
            '성수점',
          ].map((v) => PopupMenuItem(value: v, child: Text(v))).toList(),
          child: Chip(
            label: Text(branch, style: const TextStyle(fontSize: 11)),
            avatar: const Icon(Icons.place_outlined, size: 15),
          ),
        ),
        IconButton(
          tooltip: '업무 알림',
          onPressed: _openNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded),
              if (_activityStore.unreadCount > 0)
                Positioned(
                  right: -7,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE34D59),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        _activityStore.unreadCount > 9
                            ? '9+'
                            : _activityStore.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget dashboard(bool wide) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      padding: EdgeInsets.all(wide ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '안녕하세요, 김직원님 👋',
            style: TextStyle(
              color: _navy,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '오늘도 매장 업무를 확인하고 관리해보세요.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              stat(
                '오늘 입고',
                MockDatabase.instance.todayInboundCount.toString(),
                Icons.inventory_2_outlined,
                _blue,
                c.maxWidth,
              ),
              stat(
                '수령 대기',
                MockDatabase.instance.unreceivedPickups.toString(),
                Icons.shopping_bag_outlined,
                Color(0xFFF39A39),
                c.maxWidth,
              ),
              stat(
                '수령 완료',
                MockDatabase.instance.todayCompletedPickups.toString(),
                Icons.task_alt_rounded,
                Color(0xFF25A77A),
                c.maxWidth,
              ),
              stat(
                '반품 접수',
                MockDatabase.instance.returnRequestsCount.toString(),
                Icons.assignment_return_outlined,
                Color(0xFF9566D8),
                c.maxWidth,
              ),
            ],
          ),
          const SizedBox(height: 20),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: priorities()),
                    const SizedBox(width: 15),
                    Expanded(flex: 5, child: pickup()),
                  ],
                )
              : Column(
                  children: [
                    priorities(),
                    const SizedBox(height: 15),
                    pickup(),
                  ],
                ),
          const SizedBox(height: 20),
          pending(),
        ],
      ),
    ),
  );
  Widget stat(
    String title,
    String val,
    IconData icon,
    Color color,
    double width,
  ) => SizedBox(
    width: width > 880 ? (width - 36) / 4 : (width - 12) / 2,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: box(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _muted, fontSize: 11)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    val,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3, left: 3),
                    child: Text(
                      '건',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget priorities() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(19),
    decoration: box(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 우선 업무',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 15),
        ...['입고 상품 검수', '장기 수령 대기 고객 확인', '반품 상품 상태 확인'].asMap().entries.map(
          (e) => Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => setState(() {
                selected = e.key + 1;
                _pendingHistoryId = null;
              }),
              leading: CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFEDF3FF),
                child: Text(
                  '0' + (e.key + 1).toString(),
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                e.value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                [
                  '도착 예정 배송 ' +
                      MockDatabase.instance.todayExpectedOrders.toString() +
                      '건을 확인해주세요.',
                  '3일 이상 대기 주문 ' +
                      MockDatabase.instance.longWaitingPickups.toString() +
                      '건을 확인해주세요.',
                  '검수 대기 반품 ' +
                      MockDatabase.instance.inspectWaitingReturns.toString() +
                      '건을 확인해주세요.',
                ][e.key],
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: _muted,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget pickup() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: _navy,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '고객 수령 확인',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '주문 정보를 조회하고 수령을 처리하세요.',
          style: TextStyle(color: Color(0xFFB8C6DC), fontSize: 10),
        ),
        const SizedBox(height: 15),
        const Text('구매번호', style: TextStyle(color: Colors.white, fontSize: 10)),
        const SizedBox(height: 6),
        SizedBox(
          height: 43,
          child: TextFormField(
            initialValue: '',
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: qr,
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('QR 스캔'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF7184A1)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => order(' '),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('주문 조회'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget pending() => Container(
    width: double.infinity,
    decoration: box(),
    child: Column(
      children: [
        const ListTile(
          title: Text(
            '수령 대기 목록',
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          trailing: Text(
            '전체 보기 →',
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ),
        const Divider(height: 1, color: _line),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 28,
            headingTextStyle: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            columns: const [
              DataColumn(label: Text('주문번호')),
              DataColumn(label: Text('고객')),
              DataColumn(label: Text('상품')),
              DataColumn(label: Text('방문예정')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('상세/확인')),
            ],
            rows: MockDatabase.instance.pickups
                .where((pickup) => pickup.status != PickupStatus.completed)
                .map((pickup) {
                  final db = MockDatabase.instance;
                  final order = db.orderForPickup(pickup);
                  final product = db.productForOrder(order);
                  final expected = order.expectedAt.year <= 1970
                      ? '-'
                      : order.expectedAt.month.toString().padLeft(2, '0') +
                            '/' +
                            order.expectedAt.day.toString().padLeft(2, '0');
                  return row(
                    order.orderCode,
                    order.customer,
                    product.name + ' · ' + product.option,
                    expected,
                    pickupStatusLabel(pickup.status),
                  );
                })
                .toList(),
          ),
        ),
      ],
    ),
  );
  DataRow row(String a, String b, String c, String d, String state) => DataRow(
    cells: [
      DataCell(
        Text(
          a,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
      DataCell(Text(b)),
      DataCell(Text(c, style: const TextStyle(fontSize: 10))),
      DataCell(Text(d)),
      DataCell(
        Text(
          state,
          style: const TextStyle(color: Color(0xFFDB8A25), fontSize: 10),
        ),
      ),
      DataCell(TextButton(onPressed: () => order(a), child: const Text('확인'))),
    ],
  );
  Widget placeholder() => Center(
    child: Text(
      menus[selected].$1 + ' 화면을 준비 중입니다.',
      style: const TextStyle(color: _muted, fontSize: 14),
    ),
  );
  BoxDecoration box() => BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _line),
    borderRadius: BorderRadius.circular(15),
  );
  void msg(String s) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(s), behavior: SnackBarBehavior.floating),
  );
  Future<void> qr() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _QrDialog(),
    );
    if (mounted && code != null) order(code, true);
  }

  Future<void> order(String? initial, [bool auto = false]) => showDialog<void>(
    context: context,
    builder: (_) => _OrderDialog(initial: initial, auto: auto),
  );
}

class _NotificationDialog extends StatefulWidget {
  const _NotificationDialog();
  @override
  State<_NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<_NotificationDialog> {
  final Map<String, bool> options = {
    '배송 지연': true,
    '도착 임박': true,
    '출고 완료': false,
    '기사 연락 요청': true,
    '내 계정': true,
    '매장 관리자': true,
    '매장 전체 직원': false,
    'SMS 알림 추가': false,
  };
  String timing = '즉시 알림';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('알림 설정'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '최근 알림 내역',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...WorkActivityStore.instance.items
                .take(5)
                .map(
                  (item) => ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: _blue,
                    ),
                    title: Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    subtitle: Text(
                      item.createdAt.toLocal().toString(),
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
            if (WorkActivityStore.instance.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '등록된 알림이 없습니다.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ),
            const Divider(),
            const Text('알림 항목', style: TextStyle(fontWeight: FontWeight.w800)),
            ...['배송 지연', '도착 임박', '출고 완료', '기사 연락 요청'].map(_check),
            DropdownButtonFormField<String>(
              value: timing,
              decoration: const InputDecoration(labelText: '알림 시간'),
              items: [
                '즉시 알림',
                '업무 시간에만',
                '하루 한 번 요약',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => timing = v);
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '알림 수신 대상',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...['내 계정', '매장 관리자', '매장 전체 직원', 'SMS 알림 추가'].map(_check),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('설정하기'),
      ),
    ],
  );
  Widget _check(String label) => CheckboxListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 11)),
    value: options[label],
    onChanged: (v) => setState(() => options[label] = v ?? false),
  );
}

class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({required this.initialDate});
  final DateTime initialDate;
  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime _month = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
  );
  late DateTime _selected = widget.initialDate;
  @override
  Widget build(BuildContext context) {
    final offset = DateTime(_month.year, _month.month, 1).weekday - 1;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = ((offset + days + 6) ~/ 7) * 7;
    return AlertDialog(
      title: const Text('날짜 선택'),
      content: SizedBox(
        width: 330,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _month.year.toString() +
                        '년 ' +
                        _month.month.toString() +
                        '월',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: ['월', '화', '수', '목', '금', '토', '일']
                  .map(
                    (v) => Expanded(
                      child: Center(
                        child: Text(
                          v,
                          style: const TextStyle(color: _muted, fontSize: 10),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 228,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                ),
                itemCount: cells,
                itemBuilder: (context, index) {
                  final day = index - offset + 1;
                  if (day < 1 || day > days) return const SizedBox();
                  final active =
                      _selected.year == _month.year &&
                      _selected.month == _month.month &&
                      _selected.day == day;
                  return InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => setState(
                      () =>
                          _selected = DateTime(_month.year, _month.month, day),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active ? _blue : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            color: active ? Colors.white : _ink,
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('적용하기'),
        ),
      ],
    );
  }
}

class _QrDialog extends StatefulWidget {
  const _QrDialog();
  @override
  State<_QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends State<_QrDialog>
    with SingleTickerProviderStateMixin {
  late final ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('QR 스캔'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('상품의 QR코드를 스캔하여 주문 정보를 조회합니다.'),
        const SizedBox(height: 20),
        SizedBox(
          width: 230,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: _canvas,
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 130, color: _muted),
                ),
              ),
              CustomPaint(
                size: const Size(190, 160),
                painter: _CornerPainter(),
              ),
              AnimatedBuilder(
                animation: ctrl,
                builder: (_, __) => Positioned(
                  top: 10 + ctrl.value * 140,
                  left: 25,
                  right: 25,
                  child: Container(height: 2, color: _blue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, ''),
          icon: const Icon(Icons.image_outlined),
          label: const Text('이미지로 스캔하기'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ' '),
          child: const Text('스캔 완료'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _blue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    const length = 22.0;
    for (final x in [0.0, size.width - length]) {
      for (final y in [0.0, size.height - length]) {
        final path = Path()
          ..moveTo(x, y + (y == 0 ? length : 0))
          ..lineTo(x, y)
          ..lineTo(x + (x == 0 ? length : 0), y);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OrderDialog extends StatefulWidget {
  const _OrderDialog({this.initial, this.auto = false});
  final String? initial;
  final bool auto;
  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  late final c = TextEditingController(text: widget.initial ?? '');
  int tab = 0;
  bool result = false;
  MockOrder? matchedOrder;
  final hints = [
    '주문번호를 입력하세요. (예: SPO-250926-1042)',
    '고객명을 입력하세요. (예: 홍길동)',
    '연락처를 입력하세요. (예: 010-1234-5678)',
  ];

  @override
  void initState() {
    super.initState();
    matchedOrder = _findOrder(widget.initial ?? '');
    result = widget.auto && matchedOrder != null;
  }

  MockOrder? _findOrder(String input) {
    final query = input.trim().toLowerCase();
    if (query.isEmpty) return null;
    final db = MockDatabase.instance;
    return db.orders.where((order) {
      final candidate = switch (tab) {
        0 => order.orderCode,
        1 => order.customer,
        _ => order.phone,
      };
      return candidate.toLowerCase().contains(query);
    }).firstOrNull;
  }

  void _searchOrder() {
    setState(() {
      matchedOrder = _findOrder(c.text);
      result = true;
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 590, maxHeight: 700),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '주문 조회',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => tab = i),
                    child: Text(
                      ['주문번호 조회', '고객명 조회', '연락처 조회'][i],
                      style: TextStyle(
                        color: tab == i ? _blue : _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    onSubmitted: (_) => _searchOrder(),
                    decoration: InputDecoration(
                      hintText: hints[tab],
                      hintStyle: const TextStyle(fontSize: 10),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('검색'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (result && matchedOrder != null)
              Expanded(
                child: SingleChildScrollView(
                  child: _OrderResult(order: matchedOrder!),
                ),
              )
            else if (result)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text('조회 결과가 없습니다.'),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('주문 상세보기 →'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _OrderResult extends StatelessWidget {
  const _OrderResult({required this.order});
  final MockOrder order;
  String _date(DateTime value) => value.year <= 1970
      ? '-'
      : value.year.toString() +
            '.' +
            value.month.toString().padLeft(2, '0') +
            '.' +
            value.day.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    final product = MockDatabase.instance.productForOrder(order);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            product.option,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _Info('주문번호', order.orderCode),
              _Info('고객명', order.customer),
              _Info('연락처', order.phone.isEmpty ? '-' : order.phone),
              _Info('주문 수량', order.quantity.toString() + '개'),
              _Info('주문일', _date(order.orderedAt)),
              _Info('배송 상태', deliveryStatusLabel(order.status)),
            ],
          ),
        ],
      ),
    );
  }
}
