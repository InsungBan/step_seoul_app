import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/widgets/product_image.dart';
import 'package:flutter/services.dart';

const _navy = Color(0xFF14284B),
    _blue = Color(0xFF3268E8),
    _ink = Color(0xFF1C2B43),
    _muted = Color(0xFF7D8BA1),
    _line = Color(0xFFE8EDF4),
    _canvas = Color(0xFFF4F7FB);

class CustomerPickupPage extends StatefulWidget {
  const CustomerPickupPage({
    super.key,
    required this.branch,
    required this.date,
  });
  final String branch, date;
  @override
  State<CustomerPickupPage> createState() => _CustomerPickupPageState();
}

class _CustomerPickupPageState extends State<CustomerPickupPage> {
  final search = TextEditingController();
  int tab = 0;
  String filter = '전체';
  _Pickup? selected;
  bool detailOpen = false,
      detailModal = false,
      completeModal = false,
      messageModal = false,
      phoneModal = false,
      smsModal = false,
      bulkModal = false;
  final Set<String> selectedCustomers = <String>{};
  final _database = MockDatabase.instance;
  List<_Pickup> get waiting => _database.pickups
      .where((p) => p.status != PickupStatus.completed)
      .map((p) => _Pickup.fromDatabase(p, _database))
      .toList();
  List<_Pickup> get done => _database.pickups
      .where((p) => p.status == PickupStatus.completed)
      .map((p) => _Pickup.fromDatabase(p, _database))
      .toList();

  @override
  void initState() {
    super.initState();
    _database.addListener(_onDatabaseChanged);
  }

  void _onDatabaseChanged() {
    if (!mounted) return;
    setState(() {
      final id = selected?.id;
      if (id != null)
        selected = [...waiting, ...done].where((o) => o.id == id).firstOrNull;
    });
  }

  @override
  void dispose() {
    _database.removeListener(_onDatabaseChanged);
    search.dispose();
    super.dispose();
  }

  List<_Pickup> get visible => waiting.where((o) {
    final q = search.text.toLowerCase();
    final match =
        q.isEmpty ||
        o.code.toLowerCase().contains(q) ||
        o.product.toLowerCase().contains(q) ||
        o.customer.contains(q);
    final tabMatch =
        tab == 0 ||
        (tab == 1 && o.status == '수령 대기') ||
        (tab == 2 && o.status == '연락 필요') ||
        (tab == 3 && o.status == '지연');
    return match && tabMatch && (filter == '전체' || filter == o.status);
  }).toList();
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1150;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(wide ? 25 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '고객 수령',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '도착 상품과 고객 수령 현황을 관리하세요.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: waiting.isEmpty
                        ? null
                        : () => openMessage(waiting.first, bulk: true),
                    icon: const Icon(Icons.send, size: 15),
                    label: const Text('선택 고객 안내 발송하기'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Summary(
                    '오늘 수령 완료',
                    _database.todayCompletedPickups.toString(),
                    Icons.task_alt,
                    Color(0xFF25A77A),
                  ),
                  _Summary(
                    '미수령 상품',
                    _database.unreceivedPickups.toString(),
                    Icons.inventory_2,
                    _blue,
                  ),
                  _Summary(
                    '장기 대기',
                    _database.longWaitingPickups.toString(),
                    Icons.hourglass_bottom,
                    Color(0xFFF39A39),
                  ),
                  _Summary(
                    '안내 발송 필요',
                    _database.noticesNeeded.toString(),
                    Icons.mark_chat_unread,
                    Color(0xFF9566D8),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _doneTable(),
                            const SizedBox(height: 12),
                            _waitingTable(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (detailOpen && selected != null)
          Positioned.fill(
            child: wide
                ? Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => detailOpen = false),
                          child: ColoredBox(color: Colors.black26),
                        ),
                      ),
                      SizedBox(width: 420, child: _panel(selected!)),
                    ],
                  )
                : _panel(selected!),
          ),
      ],
    );
  }

  Widget _doneTable() => _Card(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '수령 완료 목록',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              _search(),
              const SizedBox(width: 7),
              _filter(),
            ],
          ),
        ),
        const Divider(height: 1),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 19,
            columns: const [
              DataColumn(label: Text('주문/배송 코드')),
              DataColumn(label: Text('상품 정보')),
              DataColumn(label: Text('고객명')),
              DataColumn(label: Text('수량')),
              DataColumn(label: Text('도착일')),
              DataColumn(label: Text('수령일')),
              DataColumn(label: Text('상태')),
            ],
            rows: done
                .map(
                  (o) => DataRow(
                    cells: [
                      DataCell(Text(o.code)),
                      DataCell(Text(o.product + ' · ' + o.option)),
                      DataCell(Text(o.customer)),
                      DataCell(Text(o.qty.toString() + '개')),
                      DataCell(Text(o.arrival)),
                      DataCell(Text(o.received ?? '-')),
                      const DataCell(_Tag('수령 완료')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );

  Widget _waitingTable() => _Card(
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '미수령 / 수령 대기 목록',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              _search(),
              const SizedBox(width: 7),
              _filter(),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              4,
              (i) => TextButton(
                onPressed: () => setState(() => tab = i),
                child: Text(
                  ['전체', '수령 대기', '연락 필요', '지연'][i],
                  style: TextStyle(
                    color: tab == i ? _blue : _muted,
                    fontWeight: tab == i ? FontWeight.w800 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 17,
            columns: const [
              DataColumn(label: Text('주문번호')),
              DataColumn(label: Text('상품 정보')),
              DataColumn(label: Text('고객명')),
              DataColumn(label: Text('도착일')),
              DataColumn(label: Text('대기 일수')),
              DataColumn(label: Text('상태')),
              DataColumn(label: Text('작업')),
            ],
            rows: visible
                .map(
                  (o) => DataRow(
                    cells: [
                      DataCell(Text(o.code)),
                      DataCell(Text(o.product + ' · ' + o.option)),
                      DataCell(Text(o.customer)),
                      DataCell(Text(o.arrival)),
                      DataCell(Text(o.days.toString() + '일')),
                      DataCell(_Tag(o.status)),
                      DataCell(
                        TextButton(
                          onPressed: () => showCustomer(o),
                          child: const Text('상세보기'),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
  Widget _search() => SizedBox(
    width: 190,
    height: 36,
    child: TextField(
      controller: search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: '주문번호, 상품, 고객 검색',
        hintStyle: const TextStyle(fontSize: 9),
        prefixIcon: const Icon(Icons.search, size: 15),
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
  Widget _filter() => DropdownButton<String>(
    value: filter,
    underline: const SizedBox(),
    items: ['전체', '수령 대기', '연락 필요', '지연', '수령 완료']
        .map(
          (v) => DropdownMenuItem(
            value: v,
            child: Text(v, style: const TextStyle(fontSize: 10)),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) setState(() => filter = v);
    },
  );
  void showCustomer(_Pickup o) {
    setState(() {
      selected = o;
      detailOpen = true;
    });
  }

  Widget _panel(_Pickup o) => Material(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 6, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '고객 상세 정보',
                  style: TextStyle(color: _navy, fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => detailOpen = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFEAF0FB),
                      child: Icon(Icons.person, color: _blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.customer + ' 고객님',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '최근 주문 3건 · ' + o.phone,
                            style: const TextStyle(color: _muted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => openPhone(o),
                      icon: const Icon(Icons.call, color: _blue),
                    ),
                    IconButton(
                      onPressed: () => openSms(o),
                      icon: const Icon(Icons.sms, color: _blue),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '대기 상품 정보',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _product(o),
                const SizedBox(height: 14),
                const Text(
                  '장기 대기 고객',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                ...waiting
                    .where((x) => x.days >= 3)
                    .map(
                      (x) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selectedCustomers.contains(x.customer),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            selectedCustomers.add(x.customer);
                          } else {
                            selectedCustomers.remove(x.customer);
                          }
                        }),
                        title: Text(
                          x.customer + ' · ' + x.days.toString() + '일 대기',
                          style: const TextStyle(fontSize: 10),
                        ),
                        subtitle: Text(
                          x.product,
                          style: const TextStyle(color: _muted, fontSize: 9),
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openMessage(o),
                  icon: const Icon(Icons.send, size: 15),
                  label: const Text('고객안내 문구 발송'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openPhone(o),
                      icon: const Icon(Icons.call, size: 14),
                      label: const Text('전화하기'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openSms(o),
                      icon: const Icon(Icons.sms, size: 14),
                      label: const Text('문자 발송'),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => openComplete(o),
                  child: const Text('수령 완료 처리'),
                ),
              ),
              TextButton(
                onPressed: () => openMessage(o, bulk: true),
                child: const Text(
                  '선택 고객에게 안내 발송하기',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _product(_Pickup o) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _canvas,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Row(
          children: [
            ProductImage(imageUrl: o.imageUrl, width: 52, height: 52),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.product,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    o.option,
                    style: const TextStyle(color: _muted, fontSize: 9),
                  ),
                  Text(
                    o.code,
                    style: const TextStyle(color: _muted, fontSize: 8),
                  ),
                ],
              ),
            ),
            _Tag(o.status),
          ],
        ),
        const Divider(height: 18),
        _Info('도착일', o.arrival),
        _Info('대기 일수', o.days.toString() + '일'),
        _Info('보관 위치', o.location),
        TextButton(
          onPressed: () => openDetail(o),
          child: const Text('수령 상세보기'),
        ),
      ],
    ),
  );
  Future<void> openDetail(_Pickup o) async {
    setState(() => detailModal = true);
    await showDialog<void>(
      context: context,
      builder: (_) => _DetailDialog(order: o),
    );
    if (mounted) setState(() => detailModal = false);
  }

  Future<void> openComplete(_Pickup o) async {
    setState(() => completeModal = true);
    final completed = await showDialog<bool>(
      context: context,
      builder: (_) => _CompleteDialog(order: o),
    );
    if (mounted) setState(() => completeModal = false);
    if (completed == true) _database.completePickup(o.id);
  }

  Future<void> openMessage(_Pickup o, {bool bulk = false}) async {
    setState(() {
      if (bulk) {
        bulkModal = true;
      } else {
        messageModal = true;
      }
    });
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _MessageDialog(
        customer: o.customer,
        bulk: bulk,
        customers: selectedCustomers.toList(),
      ),
    );
    if (mounted)
      setState(() {
        if (bulk) {
          bulkModal = false;
        } else {
          messageModal = false;
        }
      });
    if (sent == true) {
      final targets = bulk
          ? waiting
                .where((pickup) => selectedCustomers.contains(pickup.customer))
                .toList()
          : [o];
      for (final target in targets) {
        _database.sendPickupNotice(target.id);
      }
    }
  }

  Future<void> openPhone(_Pickup o) async {
    setState(() => phoneModal = true);
    await showDialog<void>(
      context: context,
      builder: (_) => _PhoneDialog(order: o),
    );
    if (mounted) setState(() => phoneModal = false);
  }

  Future<void> openSms(_Pickup o) async {
    setState(() => smsModal = true);
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _SmsDialog(order: o),
    );
    if (mounted) setState(() => smsModal = false);
    if (sent == true) _database.sendPickupNotice(o.id, type: '문자 발송');
  }
}

class _Pickup {
  const _Pickup({
    required this.id,
    required this.code,
    required this.customer,
    required this.product,
    required this.imageUrl,
    required this.option,
    required this.qty,
    required this.arrival,
    required this.days,
    required this.status,
    required this.location,
    required this.phone,
    this.received,
  });
  factory _Pickup.fromDatabase(MockPickup value, MockDatabase database) {
    final order = database.orderForPickup(value);
    final product = database.productForOrder(order);
    return _Pickup(
      id: value.id,
      code: order.orderCode,
      customer: order.customer,
      product: product.name,
      imageUrl: product.imageUrl,
      option: product.option,
      qty: value.quantity,
      arrival: _date(value.arrivedAt),
      days: value.waitingDays,
      status: pickupStatusLabel(value.status),
      location: value.location.isEmpty ? '-' : value.location,
      phone: order.phone,
      received: value.completedAt == null
          ? null
          : _date(value.completedAt!) +
                ' ' +
                value.completedAt!.hour.toString().padLeft(2, '0') +
                ':' +
                value.completedAt!.minute.toString().padLeft(2, '0'),
    );
  }
  final String id,
      code,
      customer,
      product,
      imageUrl,
      option,
      arrival,
      status,
      location,
      phone;
  final int qty, days;
  final String? received;
}

String _date(DateTime value) =>
    value.year.toString() +
    '.' +
    value.month.toString().padLeft(2, '0') +
    '.' +
    value.day.toString().padLeft(2, '0');

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(13),
    ),
    child: child,
  );
}

class _Summary extends StatelessWidget {
  const _Summary(this.title, this.value, this.icon, this.color);
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: w > 1150 ? 210 : (w - 52) / 2,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _muted, fontSize: 9)),
                Text(
                  value + '건',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = text == '수령 완료'
        ? const Color(0xFF25A77A)
        : text == '지연'
        ? const Color(0xFFE15D66)
        : text == '연락 필요'
        ? const Color(0xFF9566D8)
        : const Color(0xFFF39A39);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.a, this.b);
  final String a, b;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(a, style: const TextStyle(color: _muted, fontSize: 9)),
        ),
        Text(
          b,
          style: const TextStyle(
            color: _ink,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DetailDialog extends StatelessWidget {
  const _DetailDialog({required this.order});
  final _Pickup order;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('고객 수령 상세보기'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ProductImage(
                  imageUrl: order.imageUrl,
                  width: 88,
                  height: 88,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(order.option, style: const TextStyle(color: _muted)),
                      const SizedBox(height: 6),
                      _Tag(order.status),
                      Text(
                        order.code,
                        style: const TextStyle(color: _muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            _Info('고객명', order.customer),
            _Info('연락처', order.phone),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _PhoneDialog(order: order),
                  ),
                  icon: const Icon(Icons.call, size: 14),
                  label: const Text('전화하기'),
                ),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _SmsDialog(order: order),
                  ),
                  icon: const Icon(Icons.sms, size: 14),
                  label: const Text('문자 발송'),
                ),
              ],
            ),
            _Info('주문번호', order.code),
            _Info('상품명', order.product),
            _Info('사이즈', order.option),
            _Info('수령 상태', order.status),
            _Info('도착일', order.arrival),
            _Info('보관 위치', order.location),
            const _Info('메모', '메모 정보 없음'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
    ],
  );
}

class _CompleteDialog extends StatefulWidget {
  const _CompleteDialog({required this.order});
  final _Pickup order;
  @override
  State<_CompleteDialog> createState() => _CompleteDialogState();
}

class _CompleteDialogState extends State<_CompleteDialog> {
  final checks = List<bool>.filled(4, false);
  DateTime at = DateTime.now();
  String staff = MockDatabase.instance.activeEmployeeName;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('수령 완료 처리'),
    content: SizedBox(
      width: 490,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '아래 내용을 확인하고 고객의 상품 수령을 완료 처리합니다.',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
            _Info('고객 정보', widget.order.customer + ' · ' + widget.order.phone),
            _Info('선택 상품', widget.order.product + ' · ' + widget.order.option),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.order.code,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: widget.order.code)),
                  icon: const Icon(Icons.copy, size: 15),
                ),
              ],
            ),
            const Divider(),
            const Text(
              '최종 확인 체크리스트',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            ...[
              '고객 본인 확인 완료',
              '선택한 상품이 고객에게 정상적으로 전달되었습니다.',
              '상품 상태에 이상이 없음을 확인했습니다.',
              '수령 후 교환/반품 규정을 안내했습니다.',
            ].asMap().entries.map(
              (e) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: checks[e.key],
                onChanged: (v) => setState(() => checks[e.key] = v ?? false),
                title: Text(e.value, style: const TextStyle(fontSize: 9)),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.calendar_month, size: 14),
                    label: Text(at.toString().substring(0, 16)),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        MockDatabase.instance.employees.any(
                          (employee) => employee['name'] == staff,
                        )
                        ? staff
                        : null,
                    decoration: const InputDecoration(labelText: '처리 담당자'),
                    items: MockDatabase.instance.employees
                        .map((employee) => employee['name'] ?? '')
                        .where((name) => name.isNotEmpty)
                        .toSet()
                        .map(
                          (name) =>
                              DropdownMenuItem(value: name, child: Text(name)),
                        )
                        .toList(),
                    onChanged: (x) {
                      if (x != null) setState(() => staff = x);
                    },
                  ),
                ),
              ],
            ),
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
        onPressed: checks.every((x) => x)
            ? () {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('수령 처리가 완료되었습니다.')),
                );
              }
            : null,
        child: const Text('수령 완료 처리'),
      ),
    ],
  );
  Future<void> _pick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: at,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(at),
    );
    if (t != null)
      setState(() => at = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }
}

class _MessageDialog extends StatefulWidget {
  const _MessageDialog({
    required this.customer,
    required this.bulk,
    required this.customers,
  });
  final String customer;
  final bool bulk;
  final List<String> customers;
  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  String kind = '수령 독려 안내';
  String channel = '문자 메시지 SMS';
  final text = TextEditingController(
    text: '안녕하세요. 주문하신 상품이 매장에 도착했습니다. 편하신 시간에 방문해 수령해 주세요.',
  );
  bool sms = true, kakao = true, email = false;
  late final Set<String> checkedCustomers = widget.customers.toSet();

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.bulk ? '선택 고객에게 안내 발송하기' : '고객 안내 문구 발송'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '발송 대상  ' +
                  (widget.bulk
                      ? '장기 대기 고객 ' + checkedCustomers.length.toString() + '명'
                      : widget.customer + ' 고객님 1명'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
            ),
            if (widget.bulk)
              ...widget.customers.map(
                (customer) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: checkedCustomers.contains(customer),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      checkedCustomers.add(customer);
                    } else {
                      checkedCustomers.remove(customer);
                    }
                  }),
                  title: Text(
                    customer + ' · 장기 대기',
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
              ),
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: const InputDecoration(labelText: '안내 유형 / 템플릿'),
              items: [
                '수령 독려 안내',
                '보관 기간 안내',
                '수령 안내 (기본)',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) {
                if (v != null) setState(() => kind = v);
              },
            ),
            TextField(
              controller: text,
              onChanged: (_) => setState(() {}),
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '메시지 내용',
                border: OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                text.text.length.toString() + '/500',
                style: const TextStyle(color: _muted, fontSize: 9),
              ),
            ),
            if (widget.bulk)
              TextButton(
                onPressed: () => setState(
                  () => text.text = '안녕하세요. 매장에 도착한 상품을 방문 수령해 주세요.',
                ),
                child: const Text('기본 문구로 되돌리기'),
              ),
            if (widget.bulk) ...[
              CheckboxListTile(
                dense: true,
                title: const Text('문자', style: TextStyle(fontSize: 10)),
                value: sms,
                onChanged: (v) => setState(() => sms = v ?? false),
              ),
              CheckboxListTile(
                dense: true,
                title: const Text('카카오톡', style: TextStyle(fontSize: 10)),
                value: kakao,
                onChanged: (v) => setState(() => kakao = v ?? false),
              ),
              CheckboxListTile(
                dense: true,
                title: const Text('이메일', style: TextStyle(fontSize: 10)),
                value: email,
                onChanged: (v) => setState(() => email = v ?? false),
              ),
            ] else
              DropdownButtonFormField<String>(
                initialValue: channel,
                decoration: const InputDecoration(labelText: '발송 채널'),
                items: ['문자 메시지 SMS', '카카오톡 알림톡']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => channel = v);
                },
              ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _canvas,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(text.text, style: const TextStyle(fontSize: 9)),
            ),
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
        onPressed: () {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('안내 메시지를 발송했습니다.')));
        },
        child: Text(widget.bulk ? '안내 발송' : '안내 문구 발송'),
      ),
    ],
  );
}

class _PhoneDialog extends StatelessWidget {
  const _PhoneDialog({required this.order});
  final _Pickup order;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('전화하기'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Info('고객명', order.customer + ' 고객님'),
        Row(
          children: [
            Expanded(child: Text(order.phone)),
            IconButton(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: order.phone)),
              icon: const Icon(Icons.copy, size: 15),
            ),
          ],
        ),
        _Info('주문번호', order.code),
        _Info('상품명', order.product),
        _Info(
          '픽업 상태',
          order.days.toString() + '일 경과 (D+' + order.days.toString() + '일)',
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _canvas,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Text(
            '안녕하세요, STEP PICKUP입니다. 주문하신 상품 수령을 안내드리려고 연락드렸습니다.',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('전화 연결 요청: ' + order.phone)));
        },
        child: Text('지금 전화하기 (' + order.phone + ')'),
      ),
    ],
  );
}

class _SmsDialog extends StatefulWidget {
  const _SmsDialog({required this.order});
  final _Pickup order;
  @override
  State<_SmsDialog> createState() => _SmsDialogState();
}

class _SmsDialogState extends State<_SmsDialog> {
  String template = '수령 안내 (기본)';
  final text = TextEditingController(
    text: '안녕하세요. 주문하신 상품이 도착했습니다. 매장에 방문해 수령해 주세요.',
  );
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('문자 발송'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Info('고객 정보', widget.order.customer + ' · ' + widget.order.phone),
        DropdownButtonFormField<String>(
          initialValue: template,
          decoration: const InputDecoration(labelText: '문자 템플릿'),
          items: [
            '수령 안내 (기본)',
            '보관 기간 안내',
            '방문 요청',
          ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
          onChanged: (x) {
            if (x != null) setState(() => template = x);
          },
        ),
        TextField(
          controller: text,
          onChanged: (_) => setState(() {}),
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '문자 내용',
            border: OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            text.text.length.toString() +
                '자 · ' +
                (text.text.length * 2).toString() +
                'byte',
            style: const TextStyle(color: _muted, fontSize: 9),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('문자를 발송했습니다.')));
        },
        child: const Text('발송'),
      ),
    ],
  );
}
