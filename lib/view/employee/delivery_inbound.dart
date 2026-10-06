import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/widgets/product_image.dart';
import 'package:step_seoul_app/services/employee_operations_api.dart';

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

String _displayDeliveryStatus(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  if (normalized.contains('transit') || normalized.contains('배송중')) {
    return '매장으로 배송 중';
  }
  if (normalized.contains('이동중')) return '물류센터 이동 중';
  return value.isEmpty ? '상태 미등록' : value;
}

class _DeliveryInboundPageState extends State<DeliveryInboundPage> {
  final search = TextEditingController();
  String status = '전체 상태', arrivalDate = '전체 날짜';
  _Delivery? selectedItem;
  bool isDetailOpen = false, isPhoneModalOpen = false, isMapModalOpen = false;
  final _database = MockDatabase.instance;
  final _shipmentApi = EmployeeOperationsApi.instance;
  List<Map<String, dynamic>> _shipmentRows = [];
  final Set<String> _selectedShipmentIds = {};
  bool _loadingShipments = true;
  bool _processingInbound = false;
  String? _loadError;
  List<_Delivery> get items => _shipmentRows
      .map((row) => _Delivery.fromShipmentRow(row, _database))
      .toList();

  @override
  void initState() {
    super.initState();
    _database.addListener(_refresh);
    _loadShipments();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      final code = selectedItem?.code;
      if (code != null) {
        selectedItem = items.where((item) => item.code == code).firstOrNull;
      }
    });
  }

  Future<void> _loadShipments() async {
    if (mounted)
      setState(() {
        _loadingShipments = true;
        _loadError = null;
      });
    try {
      final rows = await _shipmentApi.getInTransitShipments();
      if (!mounted) return;
      final converted = rows
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final validIds = converted
          .map((row) => row['shipment_id']?.toString() ?? '')
          .toSet();
      setState(() {
        _shipmentRows = converted;
        _selectedShipmentIds.removeWhere((id) => !validIds.contains(id));
        _loadingShipments = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingShipments = false;
        _loadError = error.toString();
      });
    }
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
        if (_loadingShipments)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(_loadError!, style: const TextStyle(color: Colors.red)),
                TextButton.icon(
                  onPressed: _loadShipments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 불러오기'),
                ),
              ],
            ),
          )
        else if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('배송 중인 상품이 없습니다.')),
          )
        else
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
                      selected: _selectedShipmentIds.contains(item.id),
                      onSelectChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedShipmentIds.add(item.id);
                          } else {
                            _selectedShipmentIds.remove(item.id);
                          }
                        });
                      },
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
    final selected = items
        .where((item) => _selectedShipmentIds.contains(item.id))
        .toList();
    if (selected.isEmpty || _processingInbound) return;
    if (selected.any(
      (item) =>
          item.pickupUserId.isEmpty ||
          item.pickupPaymentId.isEmpty ||
          item.pickupPurchaseId.isEmpty,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('주문과 고객 정보가 연결되지 않은 배송 건은 수령 대기로 등록할 수 없습니다.'),
        ),
      );
      return;
    }

    final actualQuantities = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => _InboundDialog(items: selected),
    );
    if (actualQuantities == null || !mounted) return;

    setState(() => _processingInbound = true);
    final completed = <_Delivery>[];
    Object? failure;
    for (final item in selected) {
      try {
        await _shipmentApi.updateShipmentAsDelivered(
          shoeId: item.shoeId,
          employeeId: item.employeeId,
          shipmentId: item.id,
          storeId: item.storeId,
          pickupUserId: item.pickupUserId,
          pickupPaymentId: item.pickupPaymentId,
          pickupPurchaseId: item.pickupPurchaseId,
          receiveId:
              'RCP-' +
              DateTime.now().microsecondsSinceEpoch.toString() +
              '-' +
              completed.length.toString(),
          receiveQuantity: actualQuantities[item.id] ?? item.qty,
        );
        completed.add(item);
      } catch (error) {
        failure = error;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _processingInbound = false;
      for (final item in completed) {
        _selectedShipmentIds.remove(item.id);
      }
    });
    if (completed.isNotEmpty) {
      try {
        _database.restoreState(await _shipmentApi.readState());
      } catch (error) {
        failure ??= error;
      }
    }
    await _loadShipments();
    if (!mounted) return;
    final message = failure == null
        ? completed.length.toString() + '건의 배송 완료 및 고객 수령 대기 등록을 처리했습니다.'
        : completed.length.toString() +
              '건 처리 후 오류가 발생했습니다: ' +
              failure.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    required this.shoeId,
    required this.employeeId,
    required this.storeId,
    required this.pickupUserId,
    required this.pickupPaymentId,
    required this.pickupPurchaseId,
  });

  factory _Delivery.fromShipmentRow(
    Map<String, dynamic> row,
    MockDatabase database,
  ) {
    String value(String key) => row[key]?.toString() ?? '';
    final id = value('shipment_id');
    final shoeId = value('shoe_shoe_id');
    final order = database.orders
        .where((item) => item.orderCode == id)
        .firstOrNull;
    final product = database.products
        .where((item) => item.id == shoeId)
        .firstOrNull;
    final date = DateTime.tryParse(
      value('expected_at').isNotEmpty
          ? value('expected_at')
          : value('arrival_date'),
    );
    final arrival = date == null
        ? (order == null || order.expectedAt.year <= 1970
              ? '-'
              : _formatDate(order.expectedAt))
        : _formatDate(date);
    return _Delivery(
      id: id,
      code: id,
      name: product?.name ?? shoeId,
      imageUrl: product?.imageUrl ?? '',
      option: product?.option ?? '-',
      qty: int.tryParse(value('delivery_quantity')) ?? order?.quantity ?? 0,
      status: _displayDeliveryStatus(value('delivery_status')),
      arrival: arrival,
      shoeId: shoeId,
      employeeId: value('employee_employee_id'),
      storeId: value('store_store_id'),
      pickupUserId: value('pickup_user_id'),
      pickupPaymentId: value('pickup_payment_id'),
      pickupPurchaseId: value('pickup_purchase_id'),
    );
  }

  static String _formatDate(DateTime value) =>
      value.year.toString() +
      '.' +
      value.month.toString().padLeft(2, '0') +
      '.' +
      value.day.toString().padLeft(2, '0');

  final String id, code, name, imageUrl, option, status, arrival;
  final String shoeId, employeeId, storeId, pickupUserId, pickupPaymentId;
  final String pickupPurchaseId;
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
  const _InboundDialog({required this.items});
  final List<_Delivery> items;

  @override
  State<_InboundDialog> createState() => _InboundDialogState();
}

class _InboundDialogState extends State<_InboundDialog> {
  late final Map<String, TextEditingController> _quantities = {
    for (final item in widget.items)
      item.id: TextEditingController(text: item.qty.toString()),
  };
  String? _error;

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final values = <String, int>{};
    for (final item in widget.items) {
      final quantity = int.tryParse(_quantities[item.id]?.text.trim() ?? '');
      if (quantity == null || quantity < 1) {
        setState(() => _error = '입고 수량을 1개 이상 입력하세요.');
        return;
      }
      values[item.id] = quantity;
    }
    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('입고 처리'),
    content: SizedBox(
      width: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('실제 입고 수량을 확인하세요. 처리 후 고객 수령 대기 목록에 등록됩니다.'),
          const SizedBox(height: 14),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ProductImage(
                              imageUrl: item.imageUrl,
                              width: 44,
                              height: 44,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.code +
                                        ' · 예상 ' +
                                        item.qty.toString() +
                                        '개',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 108,
                              child: TextField(
                                controller: _quantities[item.id],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: '실제 입고',
                                  suffixText: '개',
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _submit, child: const Text('입고 완료')),
    ],
  );
}
