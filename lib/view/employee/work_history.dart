import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/widgets/product_image.dart';

const _navy = Color(0xFF14284B);
const _blue = Color(0xFF3268E8);
const _ink = Color(0xFF1C2B43);
const _muted = Color(0xFF7D8BA1);
const _line = Color(0xFFE8EDF4);
const _canvas = Color(0xFFF4F7FB);

class WorkHistoryPage extends StatefulWidget {
  const WorkHistoryPage({
    super.key,
    required this.date,
    this.initialActivityId,
  });
  final String date;
  final int? initialActivityId;
  @override
  State<WorkHistoryPage> createState() => _WorkHistoryPageState();
}

class _WorkHistoryPageState extends State<WorkHistoryPage> {
  final _store = WorkActivityStore.instance;
  MockDatabase get _database => _store.database;
  int get _salesRevenue => _database.logs
      .where(
        (log) => log.type == '판매' && _sameDay(log.createdAt, _selectedDate),
      )
      .fold(0, (sum, log) => sum + log.amount);
  final _search = TextEditingController();
  String _staff = '전체 담당자';
  String _type = '전체 업무 유형';
  DateTime _selectedDate = DateTime.now();
  WorkActivity? _selected;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onActivitiesChanged);
    if (_store.items.isNotEmpty) _selectedDate = _store.items.first.createdAt;
    _selectInitial();
  }

  @override
  void didUpdateWidget(covariant WorkHistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialActivityId != widget.initialActivityId) {
      _selectInitial();
      setState(() {});
    }
  }

  void _selectInitial() {
    final id = widget.initialActivityId;
    if (id == null) return;
    for (final item in _store.items) {
      if (item.id == id) {
        _selected = item;
        _selectedDate = item.createdAt;
      }
    }
  }

  void _onActivitiesChanged() {
    if (!mounted) return;
    setState(() {
      if (_store.items.isNotEmpty) _selectedDate = _store.items.first.createdAt;
      final selectedId = _selected?.id;
      if (selectedId != null) {
        _selected = _store.items
            .where((item) => item.id == selectedId)
            .firstOrNull;
      }
    });
  }

  @override
  void dispose() {
    _store.removeListener(_onActivitiesChanged);
    _search.dispose();
    super.dispose();
  }

  List<WorkActivity> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _store.items.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.customer.toLowerCase().contains(query) ||
          item.product.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query);
      final matchesType = _type == '전체 업무 유형' || item.type == _type;
      final matchesStaff = _staff == '전체 담당자' || item.staff.contains(_staff);
      final sameDay =
          item.createdAt.year == _selectedDate.year &&
          item.createdAt.month == _selectedDate.month &&
          item.createdAt.day == _selectedDate.day;
      return matchesQuery && matchesType && matchesStaff && sameDay;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1150;
    final padding = wide ? 25.0 : 14.0;
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
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
                          '업무 내역',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '직원의 상품 판매 및 처리 이력을 확인하세요.',
                          style: TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (wide && _selected != null) const SizedBox(width: 390),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Summary(
                    '오늘 처리 건수',
                    _database.logs
                            .where(
                              (log) => _sameDay(log.createdAt, _selectedDate),
                            )
                            .length
                            .toString() +
                        '건',
                    '선택 날짜의 MySQL 업무 기록',
                    Icons.task_alt,
                    _blue,
                  ),
                  _Summary(
                    '판매 완료',
                    _database.logs
                            .where(
                              (log) =>
                                  log.type == '판매' &&
                                  _sameDay(log.createdAt, _selectedDate),
                            )
                            .length
                            .toString() +
                        '건',
                    '매출 ' + _money(_salesRevenue) + '원',
                    Icons.point_of_sale,
                    Color(0xFF25A77A),
                  ),
                  _Summary(
                    '수령 처리',
                    _database.logs
                            .where(
                              (log) =>
                                  log.type == '고객 수령' &&
                                  _sameDay(log.createdAt, _selectedDate),
                            )
                            .length
                            .toString() +
                        '건',
                    '오늘 수령 완료 처리',
                    Icons.shopping_bag_outlined,
                    Color(0xFF9566D8),
                  ),
                  _Summary(
                    '반품 처리',
                    _database.logs
                            .where(
                              (log) =>
                                  (log.type == '반품 승인' ||
                                      log.type == '본사 회수 요청') &&
                                  _sameDay(log.createdAt, _selectedDate),
                            )
                            .length
                            .toString() +
                        '건',
                    '승인 및 회수 처리',
                    Icons.assignment_return_outlined,
                    Color(0xFFF39A39),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _table()),
            ],
          ),
        ),
        if (wide && _selected != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 390,
            child: _detail(_selected!),
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
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month, size: 16),
                label: Text(_formatDate(_selectedDate)),
              ),
              _dropdown(_staff, [
                '전체 담당자',
                ..._database.logs
                    .map((log) => log.staff)
                    .where((name) => name.isNotEmpty)
                    .toSet(),
              ], (value) => setState(() => _staff = value)),
              _dropdown(_type, const [
                '전체 업무 유형',
                '판매',
                '고객 수령',
                '반품 승인',
                '재고 조정',
                '입고 처리',
              ], (value) => setState(() => _type = value)),
              SizedBox(
                width: 270,
                height: 40,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '상품명 또는 고객명을 입력하세요...',
                    prefixIcon: const Icon(Icons.search, size: 17),
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 18,
                headingRowHeight: 44,
                dataRowMinHeight: 62,
                dataRowMaxHeight: 70,
                headingTextStyle: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                columns: const [
                  DataColumn(label: Text('고객 이름')),
                  DataColumn(label: Text('제품명')),
                  DataColumn(label: Text('수량')),
                  DataColumn(label: Text('처리 담당자')),
                  DataColumn(label: Text('처리시간')),
                  DataColumn(label: Text('업무 유형')),
                  DataColumn(label: Text('주문번호')),
                  DataColumn(label: Text('상태')),
                ],
                rows: _filtered
                    .map(
                      (item) => DataRow(
                        selected: _selected?.id == item.id,
                        onSelectChanged: (_) => _openDetail(item),
                        cells: [
                          DataCell(
                            Text(
                              item.customer,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 190,
                              child: Row(
                                children: [
                                  _thumb(
                                    item.type,
                                    imageUrl: _productImage(item.product),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          item.option,
                                          style: const TextStyle(
                                            color: _muted,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(item.quantity.toString() + '개')),
                          DataCell(
                            Text(
                              item.staff,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatTime(item.createdAt),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          DataCell(_TypeTag(item.type)),
                          DataCell(
                            Text(
                              item.code,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                          const DataCell(_DoneTag()),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '총 ' + _filtered.length.toString() + '건의 업무 내역',
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _detail(WorkActivity item) => Material(
    color: Colors.white,
    elevation: 8,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 8, 7, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '업무 상세 정보',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: '닫기',
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: _canvas,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      _thumb(
                        item.type,
                        size: 52,
                        imageUrl: _productImage(item.product),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              item.option,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '수량 ' + item.quantity.toString() + '개',
                              style: const TextStyle(color: _ink, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _section('처리 정보'),
                _Info('업무 유형', item.type),
                _Info('처리 상태', '완료'),
                _Info('처리 시간', _formatDateTime(item.createdAt)),
                _Info('처리 담당자', item.staff),
                _Info('주문번호', item.code),
                if (item.amount > 0) _Info('판매 금액', _money(item.amount) + '원'),
                const Divider(height: 22),
                _section('고객 정보'),
                _Info('고객 이름', item.customer),
                _Info('연락처', item.phone.isEmpty ? '매장 재고' : item.phone),
                _Info('고객 유형', '일반 고객'),
                _Info('수령 방법', item.type == '고객 수령' ? '매장 픽업' : '매장 처리'),
                const Divider(height: 22),
                _section('메모'),
                Text(
                  item.note,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
  Widget _dropdown(
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
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
  );
  String _productImage(String name) =>
      _database.products
          .where((product) => product.name == name)
          .firstOrNull
          ?.imageUrl ??
      '';

  Widget _thumb(String type, {double size = 34, String imageUrl = ''}) {
    final c = type == '판매'
        ? _blue
        : type == '반품 승인'
        ? const Color(0xFFF39A39)
        : type == '재고 조정'
        ? const Color(0xFF9566D8)
        : const Color(0xFF25A77A);
    if (imageUrl.isNotEmpty) {
      return ProductImage(imageUrl: imageUrl, width: size, height: size);
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        type == '판매'
            ? Icons.shopping_bag_outlined
            : type == '반품 승인'
            ? Icons.assignment_return_outlined
            : type == '재고 조정'
            ? Icons.inventory_2_outlined
            : Icons.local_shipping_outlined,
        color: c,
        size: size * .55,
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (value != null) setState(() => _selectedDate = value);
  }

  void _openDetail(WorkActivity item) {
    setState(() => _selected = item);
    if (MediaQuery.sizeOf(context).width < 1150)
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .85,
          child: _detail(item),
        ),
      );
  }
}

class WorkActivityNotifications extends StatefulWidget {
  const WorkActivityNotifications({super.key});
  @override
  State<WorkActivityNotifications> createState() =>
      _WorkActivityNotificationsState();
}

class _WorkActivityNotificationsState extends State<WorkActivityNotifications> {
  final _store = WorkActivityStore.instance;
  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    alignment: Alignment.topRight,
    insetPadding: const EdgeInsets.only(top: 82, right: 20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 11, 7, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '업무 알림',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _store.markAllRead,
                  child: const Text('모두 읽음'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 19),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _store.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _store.items[index];
                return ListTile(
                  dense: true,
                  leading: _TypeTag(item.type),
                  title: Text(
                    item.message,
                    style: const TextStyle(fontSize: 11, height: 1.35),
                  ),
                  subtitle: Text(
                    _formatTime(item.createdAt),
                    style: const TextStyle(color: _muted, fontSize: 9),
                  ),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
          if (_store.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('새로운 업무 알림이 없습니다.'),
            ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary(this.title, this.value, this.note, this.icon, this.color);
  final String title, value, note;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width >= 1200
        ? 215
        : (MediaQuery.sizeOf(context).width - 52) / 2,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: _muted, fontSize: 10)),
              Text(
                value,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(note, style: const TextStyle(color: _muted, fontSize: 9)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TypeTag extends StatelessWidget {
  const _TypeTag(this.type);
  final String type;
  @override
  Widget build(BuildContext context) {
    final c = type == '판매'
        ? _blue
        : type == '반품 승인'
        ? const Color(0xFFF39A39)
        : type == '재고 조정'
        ? const Color(0xFF9566D8)
        : const Color(0xFF25A77A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _DoneTag extends StatelessWidget {
  const _DoneTag();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF25A77A).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      '완료',
      style: TextStyle(
        color: Color(0xFF25A77A),
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDate(DateTime d) =>
    d.year.toString() +
    '.' +
    d.month.toString().padLeft(2, '0') +
    '.' +
    d.day.toString().padLeft(2, '0');
String _formatTime(DateTime d) =>
    d.hour.toString().padLeft(2, '0') +
    ':' +
    d.minute.toString().padLeft(2, '0');
String _formatDateTime(DateTime d) =>
    _formatDate(d) +
    ' ' +
    d.hour.toString().padLeft(2, '0') +
    ':' +
    d.minute.toString().padLeft(2, '0') +
    ':' +
    d.second.toString().padLeft(2, '0');
String _money(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
