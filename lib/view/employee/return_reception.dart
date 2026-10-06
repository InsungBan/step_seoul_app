import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/widgets/product_image.dart';

const _navy = Color(0xFF14284B),
    _blue = Color(0xFF3268E8),
    _ink = Color(0xFF1C2B43),
    _muted = Color(0xFF7D8BA1),
    _line = Color(0xFFE8EDF4),
    _canvas = Color(0xFFF4F7FB);

class ReturnReceptionPage extends StatefulWidget {
  const ReturnReceptionPage({
    super.key,
    required this.branch,
    required this.date,
  });
  final String branch, date;
  @override
  State<ReturnReceptionPage> createState() => _ReturnReceptionPageState();
}

class _ReturnReceptionPageState extends State<ReturnReceptionPage> {
  final search = TextEditingController();
  String status = '전체 상태', period = '최근 30일';
  _ReturnRequest? selected;
  bool detailOpen = false,
      approvalOpen = false,
      phoneOpen = false,
      smsOpen = false,
      messageOpen = false;
  final _database = MockDatabase.instance;
  List<_ReturnRequest> get requests => _database.returns
      .map((r) => _ReturnRequest.fromDatabase(r, _database))
      .toList();
  int get _returnCount => _database.returnRequestsCount;
  int get _inspectionCount => _database.inspectWaitingReturns;
  int get _approvedCount => _database.approvedReturns;
  int get _recallCount => _database.recallsInProgress;

  @override
  void initState() {
    super.initState();
    _database.addListener(_onDatabaseChanged);
  }

  void _onDatabaseChanged() {
    if (!mounted) return;
    setState(() {
      final id = selected?.id;
      if (id != null) selected = requests.where((r) => r.id == id).firstOrNull;
    });
  }

  @override
  void dispose() {
    _database.removeListener(_onDatabaseChanged);
    search.dispose();
    super.dispose();
  }

  List<_ReturnRequest> get visible => requests.where((r) {
    final q = search.text.trim().toLowerCase();
    final matches =
        q.isEmpty ||
        r.code.toLowerCase().contains(q) ||
        r.customer.contains(q) ||
        r.product.toLowerCase().contains(q) ||
        r.phone.contains(q);
    final matchesStatus = status == '전체 상태' || r.label == status;
    return matches && matchesStatus;
  }).toList();
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1150;
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              wide ? 25 : 14,
              wide ? 25 : 14,
              wide ? 25 : 14,
              wide ? 25 : 14,
            ),
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
                            '반품 접수',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '반품 요청을 검수하고 처리 현황을 관리하세요.',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => detailOpen = false),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('새로고침'),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Summary(
                      '반품 요청',
                      _returnCount.toString(),
                      '오늘 접수 ' +
                          _database.returns
                              .where(
                                (r) =>
                                    r.requestedAt.year == DateTime.now().year &&
                                    r.requestedAt.month ==
                                        DateTime.now().month &&
                                    r.requestedAt.day == DateTime.now().day,
                              )
                              .length
                              .toString() +
                          '건 증가',
                      Icons.assignment_return,
                      _blue,
                    ),
                    _Summary(
                      '검수 대기',
                      _inspectionCount.toString(),
                      '전체의 ' +
                          (_returnCount == 0
                                  ? 0
                                  : (_inspectionCount * 100 / _returnCount)
                                        .round())
                              .toString() +
                          '%',
                      Icons.pending_actions,
                      Color(0xFFF39A39),
                    ),
                    _Summary(
                      '승인 완료',
                      _approvedCount.toString(),
                      '오늘 ' +
                          _database.logs
                              .where((l) => l.type == '반품 승인')
                              .length
                              .toString() +
                          '건 승인',
                      Icons.verified,
                      Color(0xFF25A77A),
                    ),
                    _Summary(
                      '회수 진행 중',
                      _recallCount.toString(),
                      '본사 회수 대기',
                      Icons.local_shipping,
                      Color(0xFF9566D8),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _table(),
              ],
            ),
          ),
        ),
        if (wide && detailOpen && selected != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 420,
            child: _panel(selected!),
          ),
      ],
    );
  }

  Widget _table() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 270,
                height: 38,
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '고객, 주문번호, 상품 검색',
                    hintStyle: const TextStyle(fontSize: 10),
                    prefixIcon: const Icon(Icons.search, size: 16),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              _dropdown(status, [
                '전체 상태',
                '반품 요청',
                '승인 완료',
                '회수 요청 완료',
              ], (v) => setState(() => status = v)),
              _dropdown(period, [
                '최근 30일',
                '최근 7일',
                '이번 달',
                '전체 기간',
              ], (v) => setState(() => period = v)),
            ],
          ),
        ),
        const Divider(height: 1),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 17,
            headingTextStyle: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            columns: const [
              DataColumn(label: Text('고객 이름/연락처')),
              DataColumn(label: Text('주문번호/주문일')),
              DataColumn(label: Text('상품 정보')),
              DataColumn(label: Text('반품 사유')),
              DataColumn(label: Text('진행 상태')),
              DataColumn(label: Text('접수일')),
              DataColumn(label: Text('작업')),
            ],
            rows: visible
                .map(
                  (r) => DataRow(
                    cells: [
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.customer,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              r.phone,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              r.orderDate,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          r.product + ' · ' + r.option,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: Text(
                            r.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
                      DataCell(_Status(r.label)),
                      DataCell(
                        Text(r.submitted, style: const TextStyle(fontSize: 9)),
                      ),
                      DataCell(
                        TextButton(
                          onPressed: () => _showDetail(r),
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
  Widget _dropdown(
    String v,
    List<String> values,
    ValueChanged<String> onChange,
  ) => DropdownButton<String>(
    value: v,
    underline: const SizedBox(),
    items: values
        .map(
          (x) => DropdownMenuItem(
            value: x,
            child: Text(x, style: const TextStyle(fontSize: 10)),
          ),
        )
        .toList(),
    onChanged: (x) {
      if (x != null) onChange(x);
    },
  );
  void _showDetail(_ReturnRequest r) {
    setState(() {
      selected = r;
      detailOpen = true;
    });
    if (MediaQuery.sizeOf(context).width < 1150) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .9,
          child: _panel(r),
        ),
      );
    }
  }

  Widget _panel(_ReturnRequest r) => Material(
    color: Colors.white,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '반품 요청 상세정보',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
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
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _productSummary(r),
                const SizedBox(height: 13),
                _section('고객 정보'),
                _Info('고객명', r.customer),
                _Info('연락처', r.phone),
                _Info('주소', r.address),
                _Info('요청일', r.submitted),
                TextButton.icon(
                  onPressed: () => _openPhone(r),
                  icon: const Icon(Icons.call, size: 14),
                  label: const Text('전화하기'),
                ),
                const Divider(),
                _section('주문 정보'),
                _Info('주문번호', r.code),
                _Info('주문일', r.orderDate),
                _Info('구매 채널', r.channel),
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주문 상세 정보를 열었습니다.')),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('주문 상세보기'),
                ),
                const Divider(),
                _section('반품 사유'),
                Text(
                  r.reason,
                  style: const TextStyle(color: _ink, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  r.detailReason,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
                const Divider(),
                _section('상품 정보'),
                _productSummary(r),
                const Divider(),
                _section(r.approved ? '반품 진행 상태' : '처리 진행 상태'),
                _timeline(r),
                const SizedBox(height: 12),
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
                child: OutlinedButton.icon(
                  onPressed: () => _openMessage(r),
                  icon: const Icon(Icons.send, size: 14),
                  label: const Text('고객에게 안내 발송하기'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPhone(r),
                      icon: const Icon(Icons.call, size: 14),
                      label: const Text('전화하기'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openSms(r),
                      icon: const Icon(Icons.sms, size: 14),
                      label: const Text('문자 발송'),
                    ),
                  ),
                ],
              ),
              if (!r.approved)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _approve(r),
                    child: const Text('반품 승인'),
                  ),
                ),
              if (r.approved)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: r.pickupRequested
                        ? null
                        : () => _requestPickup(r),
                    icon: const Icon(Icons.local_shipping, size: 15),
                    label: Text(r.pickupRequested ? '본사 회수 요청 완료' : '본사 회수 요청'),
                  ),
                ),
              TextButton(
                onPressed: () => setState(() => detailOpen = false),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _productSummary(_ReturnRequest r) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _canvas,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        ProductImage(imageUrl: r.imageUrl, width: 54, height: 54),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.product,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                r.option + ' · ' + r.qty.toString() + '개',
                style: const TextStyle(color: _muted, fontSize: 9),
              ),
              Text(
                '주문 ' + r.code,
                style: const TextStyle(color: _muted, fontSize: 8),
              ),
              Text(
                '송장 ' + r.invoice,
                style: const TextStyle(color: _muted, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _section(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      s,
      style: const TextStyle(
        color: _navy,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    ),
  );
  Widget _timeline(_ReturnRequest r) {
    final steps = r.approved
        ? ['반품 요청 접수', '승인 완료', '본사 회수 요청 중', '상품 회수 중', '회수 완료', '환불 처리']
        : ['반품 요청', '검수 대기', '승인 완료', '본사 회수 요청'];
    return Column(
      children: steps.asMap().entries.map((e) {
        final done =
            e.key == 0 ||
            (r.approved && e.key == 1) ||
            (r.pickupRequested && e.key == 2);
        final active =
            !done && (r.approved && e.key == 2 || !r.approved && e.key == 1);
        return _Timeline(
          title: e.value,
          detail: done
              ? (e.key == 0 ? r.submitted : r.approvedAt ?? '처리 일시 정보 없음')
              : active
              ? '담당자가 확인 중입니다.'
              : '처리 대기 중',
          done: done,
          active: active,
          isLast: e.key == steps.length - 1,
        );
      }).toList(),
    );
  }

  Future<void> _approve(_ReturnRequest r) async {
    setState(() => approvalOpen = true);
    final approved = await showDialog<bool>(
      context: context,
      builder: (_) => _ApproveDialog(request: r),
    );
    if (!mounted) return;
    setState(() => approvalOpen = false);
    if (approved == true) _database.approveReturn(r.id);
  }

  void _requestPickup(_ReturnRequest r) {
    _database.requestReturnRecall(r.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('완료되었습니다.')));
  }

  Future<void> _openPhone(_ReturnRequest r) async {
    setState(() => phoneOpen = true);
    await showDialog<void>(
      context: context,
      builder: (_) => _ContactDialog(request: r, kind: '전화하기'),
    );
    if (mounted) setState(() => phoneOpen = false);
  }

  Future<void> _openSms(_ReturnRequest r) async {
    setState(() => smsOpen = true);
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _SimpleMessageDialog(request: r, sms: true),
    );
    if (mounted) setState(() => smsOpen = false);
    if (sent == true) _database.sendReturnNotice(r.id, type: '문자 발송');
  }

  Future<void> _openMessage(_ReturnRequest r) async {
    setState(() => messageOpen = true);
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _SimpleMessageDialog(request: r, sms: false),
    );
    if (mounted) setState(() => messageOpen = false);
    if (sent == true) _database.sendReturnNotice(r.id);
  }
}

class _ReturnRequest {
  _ReturnRequest.fromDatabase(MockReturn value, MockDatabase database)
    : id = value.id,
      code = value.orderId,
      customer = _order(database, value.orderId).customer,
      phone = _order(database, value.orderId).phone,
      product = database.productForOrder(_order(database, value.orderId)).name,
      imageUrl = database
          .productForOrder(_order(database, value.orderId))
          .imageUrl,
      option = database.productForOrder(_order(database, value.orderId)).option,
      qty = _order(database, value.orderId).quantity,
      reason = value.reason,
      submitted = _date(value.requestedAt),
      orderDate = _date(_order(database, value.orderId).orderedAt),
      invoice = '-',
      address = _order(database, value.orderId).address,
      channel = '-',
      detailReason = value.detailReason,
      requestNote = value.note,
      status = value.status,
      recallRequested = value.recallRequested,
      approvedAt = null;

  static MockOrder _order(MockDatabase database, String code) =>
      database.orders.where((order) => order.orderCode == code).firstOrNull ??
      MockOrder(
        id: '',
        orderCode: code,
        customer: '-',
        phone: '',
        productId: '',
        orderedAt: DateTime.fromMillisecondsSinceEpoch(0),
        expectedAt: DateTime.fromMillisecondsSinceEpoch(0),
        status: DeliveryStatus.unknown,
        quantity: 0,
        address: '',
      );
  final String id,
      code,
      customer,
      phone,
      product,
      imageUrl,
      option,
      reason,
      submitted,
      orderDate,
      invoice,
      address,
      channel,
      detailReason,
      requestNote;
  final int qty;
  final ReturnStatus status;
  final bool recallRequested;
  final String? approvedAt;
  bool get approved => status == ReturnStatus.approved || recallRequested;
  bool get pickupRequested => recallRequested;
  String get label => returnStatusLabel(status);
}

String _date(DateTime value) =>
    value.year.toString() +
    '.' +
    value.month.toString().padLeft(2, '0') +
    '.' +
    value.day.toString().padLeft(2, '0');

class _Summary extends StatelessWidget {
  const _Summary(this.title, this.value, this.note, this.icon, this.color);
  final String title, value, note;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: w > 1150 ? 235 : (w - 42) / 2,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(note, style: const TextStyle(color: _muted, fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = label == '승인 완료'
        ? const Color(0xFF25A77A)
        : label == '회수 요청 완료'
        ? const Color(0xFF9566D8)
        : const Color(0xFFF39A39);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.title,
    required this.detail,
    required this.done,
    required this.active,
    required this.isLast,
  });
  final String title, detail;
  final bool done, active, isLast;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 51,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          child: Column(
            children: [
              Icon(
                done
                    ? Icons.check_circle
                    : active
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: done
                    ? const Color(0xFF25A77A)
                    : active
                    ? _blue
                    : _muted,
                size: 15,
              ),
              if (!isLast) Expanded(child: Container(width: 1.5, color: _line)),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: done
                            ? _ink
                            : active
                            ? _blue
                            : _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _Status(
                    done
                        ? '완료'
                        : active
                        ? '진행중'
                        : '대기',
                  ),
                ],
              ),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 8)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({required this.request});
  final _ReturnRequest request;
  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  String condition = '미개봉 (새상품)';
  final reason = TextEditingController();
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('반품 승인'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '선택한 반품 요청을 승인하시겠습니까? 승인 시 본사 회수 요청이 진행됩니다.',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
            const SizedBox(height: 12),
            _Info(
              '상품 정보',
              widget.request.product + ' · ' + widget.request.option,
            ),
            _Info('주문번호', widget.request.code),
            _Info(
              '고객 정보',
              widget.request.customer + ' · ' + widget.request.phone,
            ),
            _Info('주문일', widget.request.orderDate),
            _Info('반품 신청일', widget.request.submitted),
            _Info('반품 사유', widget.request.reason),
            _Info('상세 사유', widget.request.detailReason),
            _Info('요청 사항', widget.request.requestNote),
            const Divider(),
            const Text(
              '상품 상태 (검수 결과)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
            ),
            ...['미개봉 (새상품)', '사용 흔적 없음', '약간의 사용감', '사용감 있음'].map(
              (x) => RadioListTile<String>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: x,
                groupValue: condition,
                onChanged: (v) {
                  if (v != null) setState(() => condition = v);
                },
                title: Text(x, style: const TextStyle(fontSize: 9)),
              ),
            ),
            TextField(
              controller: reason,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '승인 사유 (선택)',
                border: OutlineInputBorder(),
              ),
            ),
            _Info(
              '처리 담당자',
              MockDatabase.instance.activeEmployeeName.isEmpty
                  ? '-'
                  : MockDatabase.instance.activeEmployeeName,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('반품 승인 처리'),
      ),
    ],
  );
}

class _ContactDialog extends StatelessWidget {
  const _ContactDialog({required this.request, required this.kind});
  final _ReturnRequest request;
  final String kind;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(kind),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Info('고객명', request.customer),
        _Info('연락처', request.phone),
        _Info('주문번호', request.code),
        _Info('상품명', request.product),
        const SizedBox(height: 8),
        const Text(
          '안녕하세요. STEP PICKUP입니다. 접수하신 반품 요청 관련하여 안내드립니다.',
          style: TextStyle(fontSize: 10),
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
          ).showSnackBar(const SnackBar(content: Text('연락 요청을 완료했습니다.')));
        },
        child: Text(kind),
      ),
    ],
  );
}

class _SimpleMessageDialog extends StatefulWidget {
  const _SimpleMessageDialog({required this.request, required this.sms});
  final _ReturnRequest request;
  final bool sms;
  @override
  State<_SimpleMessageDialog> createState() => _SimpleMessageDialogState();
}

class _SimpleMessageDialogState extends State<_SimpleMessageDialog> {
  final text = TextEditingController(
    text: '안녕하세요. STEP PICKUP입니다. 반품 요청이 접수되어 확인 중입니다.',
  );
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.sms ? '문자 발송' : '고객 안내 문구 발송'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Info('고객 정보', widget.request.customer + ' · ' + widget.request.phone),
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
          ).showSnackBar(const SnackBar(content: Text('메시지를 발송했습니다.')));
        },
        child: Text(widget.sms ? '발송' : '안내 발송'),
      ),
    ],
  );
}
