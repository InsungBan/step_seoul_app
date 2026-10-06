import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/widgets/product_image.dart';

const navy = Color(0xFF14284B),
    blue = Color(0xFF3268E8),
    ink = Color(0xFF1C2B43),
    muted = Color(0xFF7D8BA1),
    line = Color(0xFFE8EDF4);

class DeliveryInboundPage extends StatefulWidget {
  const DeliveryInboundPage({
    super.key,
    required this.branch,
    required this.date,
  });
  final String branch, date;
  @override
  State<DeliveryInboundPage> createState() => _DeliveryInboundPageState();
}

class _DeliveryInboundPageState extends State<DeliveryInboundPage> {
  final search = TextEditingController();
  String status = '전체 상태', arrivalDate = '전체 날짜';
  _Delivery? selectedItem;
  bool isDetailOpen = false,
      isPhoneModalOpen = false,
      isMapModalOpen = false,
      isInboundModalOpen = false;
  final _database = MockDatabase.instance;
  List<_Delivery> get items => _database.orders
      .map((order) => _Delivery.fromOrder(order, _database))
      .toList();

  @override
  void initState() {
    super.initState();
    _database.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      final code = selectedItem?.code;
      if (code != null)
        selectedItem = items.where((item) => item.code == code).firstOrNull;
    });
  }

  @override
  void dispose() {
    _database.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  List<_Delivery> get filtered => items.where((x) {
    final q = search.text.toLowerCase();
    return (q.isEmpty ||
            x.code.toLowerCase().contains(q) ||
            x.name.toLowerCase().contains(q)) &&
        (status == '전체 상태' || x.status == status) &&
        (arrivalDate == '전체 날짜' || x.arrival.startsWith(arrivalDate));
  }).toList();
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1120;
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(wide ? 28 : 16),
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
                            '입고 예정 배송',
                            style: TextStyle(
                              color: navy,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '매장으로 배송 중인 상품과 입고 예정 정보를 확인하세요.',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: openInbound,
                      icon: const Icon(Icons.add_task, size: 17),
                      label: const Text('입고 처리'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Summary(
                      '오늘 도착 예정',
                      _database.todayExpectedOrders.toString(),
                      Icons.event_available,
                      blue,
                    ),
                    _Summary(
                      '배송 중',
                      _database.inTransitCount.toString(),
                      Icons.local_shipping,
                      Color(0xFFF39A39),
                    ),
                    _Summary(
                      '도착 완료',
                      _database.arrivedTodayCount.toString(),
                      Icons.task_alt,
                      Color(0xFF25A77A),
                    ),
                    _Summary(
                      '지연 건수',
                      _database.delayedCount.toString(),
                      Icons.warning_amber,
                      Color(0xFFE15D66),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                listPanel(),
              ],
            ),
          ),
        ),
        if (wide && isDetailOpen && selectedItem != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 350,
            child: detailPanel(selectedItem!),
          ),
      ],
    );
  }

  Widget listPanel() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 275,
                height: 42,
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '주문번호 또는 상품명 검색',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              filter(status, [
                '전체 상태',
                '매장으로 배송 중',
                '물류센터 이동 중',
                '지역 센터 도착',
                '배송 지연',
              ], (v) => setState(() => status = v)),
              filter(arrivalDate, [
                '전체 날짜',
                '오늘',
                '내일',
              ], (v) => setState(() => arrivalDate = v)),
            ],
          ),
        ),
        const Divider(height: 1),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('주문/배송 코드')),
              DataColumn(label: Text('상품 정보')),
              DataColumn(label: Text('수량')),
              DataColumn(label: Text('현재 배송 상태')),
              DataColumn(label: Text('예상 도착시간')),
              DataColumn(label: Text('작업')),
            ],
            rows: filtered
                .map(
                  (item) => DataRow(
                    cells: [
                      DataCell(Text(item.code)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProductImage(
                              imageUrl: item.imageUrl,
                              width: 42,
                              height: 42,
                            ),
                            const SizedBox(width: 8),
                            Text(item.name + ' · ' + item.option),
                          ],
                        ),
                      ),
                      DataCell(Text(item.qty.toString() + '개')),
                      DataCell(Text(item.status)),
                      DataCell(Text(item.arrival)),
                      DataCell(
                        TextButton(
                          onPressed: () => showDetail(item),
                          child: const Text('배송위치 상세보기'),
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

  Widget filter(
    String value,
    List<String> choices,
    ValueChanged<String> change,
  ) => DropdownButton<String>(
    value: value,
    items: choices
        .map(
          (v) => DropdownMenuItem(
            value: v,
            child: Text(v, style: const TextStyle(fontSize: 11)),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) change(v);
    },
  );
  void showDetail(_Delivery x) {
    setState(() => selectedItem = x);
    if (MediaQuery.sizeOf(context).width < 1120) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: detailPanel(x),
        ),
      );
    } else {
      setState(() => isDetailOpen = true);
    }
  }

  Widget detailPanel(_Delivery x) => Material(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '배송 위치 상세정보',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => isDetailOpen = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: line),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(imageUrl: x.imageUrl, width: 84, height: 84),
                const SizedBox(height: 10),
                Text(
                  x.code,
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
                Text(
                  x.name + ' · ' + x.option,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '예상 도착시간  ' + x.arrival,
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '배송 진행 현황',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _Step('배송 상태', x.status, x.status != '상태 미등록'),
                const _Step('상세 배송 위치', 'MySQL 배송 상세 정보가 없습니다.', false),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Expanded(
                      child: Text('주소 정보 없음', style: TextStyle(fontSize: 10)),
                    ),
                    TextButton(
                      onPressed: openMap,
                      child: const Text('지도에서 보기'),
                    ),
                  ],
                ),
                const Text(
                  '담당 기사 정보 없음',
                  style: TextStyle(fontSize: 10, color: muted),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: openPhone,
              icon: const Icon(Icons.call),
              label: const Text('전화하기'),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> openPhone() async {
    setState(() => isPhoneModalOpen = true);
    await showDialog<void>(
      context: context,
      builder: (_) => _PhoneDialog(item: selectedItem),
    );
    if (mounted) setState(() => isPhoneModalOpen = false);
  }

  Future<void> openMap() async {
    setState(() => isMapModalOpen = true);
    await showDialog<void>(
      context: context,
      builder: (_) => const _MapDialog(),
    );
    if (mounted) setState(() => isMapModalOpen = false);
  }

  Future<void> openInbound() async {
    setState(() => isInboundModalOpen = true);
    final item = selectedItem ?? (items.isEmpty ? null : items.first);
    if (item == null) {
      if (mounted) setState(() => isInboundModalOpen = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입고 처리할 배송 데이터가 없습니다.')));
      return;
    }
    final completed = await showDialog<bool>(
      context: context,
      builder: (_) => _InboundDialog(item: item),
    );
    if (mounted) setState(() => isInboundModalOpen = false);
    if (completed == true) {
      _database.completeDelivery(item.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입고 처리가 완료되었습니다.')));
    }
  }
}

class _Delivery {
  const _Delivery({
    required this.id,
    required this.code,
    required this.name,
    required this.imageUrl,
    required this.option,
    required this.qty,
    required this.status,
    required this.arrival,
  });
  factory _Delivery.fromOrder(MockOrder order, MockDatabase database) {
    final product = database.productForOrder(order);
    final arrival = order.expectedAt.year <= 1970
        ? '-'
        : order.expectedAt.year.toString() +
              '.' +
              order.expectedAt.month.toString().padLeft(2, '0') +
              '.' +
              order.expectedAt.day.toString().padLeft(2, '0');
    return _Delivery(
      id: order.id,
      code: order.orderCode,
      name: product.name,
      imageUrl: product.imageUrl,
      option: product.option,
      qty: order.quantity,
      status: deliveryStatusLabel(order.status),
      arrival: arrival,
    );
  }
  final String id, code, name, imageUrl, option, status, arrival;
  final int qty;
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
      width: w > 1120 ? 220 : (w - 56) / 2,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: muted, fontSize: 10)),
                Text(
                  value + '건',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 22,
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

class _Step extends StatelessWidget {
  const _Step(this.title, this.detail, this.done);
  final String title, detail;
  final bool done;
  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      done ? Icons.check_circle : Icons.radio_button_unchecked,
      color: done ? blue : muted,
      size: 17,
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(detail, style: const TextStyle(fontSize: 9, color: muted)),
  );
}

class _PhoneDialog extends StatelessWidget {
  const _PhoneDialog({required this.item});
  final _Delivery? item;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('전화하기'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line('담당 기사', '정보 없음'),
        _line('연락처', '정보 없음'),
        _line('배송 업체', '정보 없음'),
        _line('현재 배송 상태', item?.status ?? '상태 미등록'),
        _line('주문 코드', item?.code ?? '-'),
        _line('상품 정보', item?.name ?? '-'),
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
          ).showSnackBar(const SnackBar(content: Text('전화 연결을 요청했습니다.')));
        },
        child: const Text('전화하기'),
      ),
    ],
  );
  Widget _line(String a, String b) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(a, style: const TextStyle(color: muted, fontSize: 10)),
        ),
        Expanded(
          child: Text(
            b,
            style: const TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MapDialog extends StatelessWidget {
  const _MapDialog();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('지도에서 보기'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          children: [
            Icon(Icons.schedule, color: blue),
            SizedBox(width: 6),
            Text('예상 도착 14:30'),
            Spacer(),
            Text('남은 거리 12.5km'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          width: 480,
          child: CustomPaint(
            painter: _RoutePainter(),
            child: const Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Icon(Icons.store, color: Color(0xFF25A77A), size: 30),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.local_shipping, color: blue, size: 30),
                ),
              ],
            ),
          ),
        ),
        const Wrap(
          spacing: 12,
          children: [Text('● 현재 차량 위치'), Text('━ 이동 경로'), Text('● 도착 매장')],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('확인'),
      ),
    ],
  );
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = blue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(20, 20)
      ..lineTo(s.width * .3, s.height * .25)
      ..lineTo(s.width * .5, s.height * .4)
      ..lineTo(s.width * .72, s.height * .55)
      ..lineTo(s.width - 25, s.height - 25);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InboundDialog extends StatefulWidget {
  const _InboundDialog({required this.item});
  final _Delivery item;
  @override
  State<_InboundDialog> createState() => _InboundDialogState();
}

class _InboundDialogState extends State<_InboundDialog> {
  late final actual = TextEditingController(
    text: widget.item.qty > 0 ? widget.item.qty.toString() : '',
  );
  final damaged = TextEditingController();
  final memo = TextEditingController();
  String store = '';
  @override
  void dispose() {
    actual.dispose();
    damaged.dispose();
    memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('입고 처리'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '선택한 상품의 입고 정보를 입력하고, 입고 처리를 완료하세요.',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.name + ' · ' + widget.item.option,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '예상 수량 ' + widget.item.qty.toString() + '개',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
            Row(
              children: [
                Expanded(child: _field('실제 입고 수량', actual)),
                const SizedBox(width: 8),
                Expanded(child: _field('파손 수량', damaged)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final database = MockDatabase.instance;
                      final options = database.stores
                          .map((item) => database.storeName(item['id'] ?? ''))
                          .where((name) => name.isNotEmpty)
                          .toSet()
                          .toList();
                      final selected = options.contains(store)
                          ? store
                          : options.firstOrNull ?? '';
                      if (options.isEmpty) {
                        return const TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: '입고 매장',
                            hintText: '매장 데이터 없음',
                          ),
                        );
                      }
                      return _choice(
                        '입고 매장',
                        selected,
                        options,
                        (value) => setState(() => store = value),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '입고 시각 ' +
                        DateTime.now().toLocal().toString().substring(0, 16),
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ),
              ],
            ),
            TextField(
              controller: memo,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
              ),
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
        },
        child: const Text('입고 완료'),
      ),
    ],
  );
  Widget _field(String label, TextEditingController c) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      suffixText: '개',
      border: const OutlineInputBorder(),
    ),
  );
  Widget _choice(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        items: values
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(v, style: const TextStyle(fontSize: 10)),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) change(v);
        },
      ),
    ),
  );
}
