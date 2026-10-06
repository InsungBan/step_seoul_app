import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/work_activity_store.dart';
import 'package:step_seoul_app/widgets/product_image.dart';

const _navy = Color(0xFF14284B);
const _blue = Color(0xFF3268E8);
const _muted = Color(0xFF7D8BA1);
const _line = Color(0xFFE8EDF4);
const _canvas = Color(0xFFF4F7FB);

class InventoryStatusPage extends StatefulWidget {
  const InventoryStatusPage({super.key});
  @override
  State<InventoryStatusPage> createState() => _InventoryStatusPageState();
}

class _InventoryStatusPageState extends State<InventoryStatusPage> {
  final _search = TextEditingController();
  String _category = '모든 카테고리';
  String _filter = '재고 상태 전체';
  final _database = MockDatabase.instance;
  List<MockProduct> get _products => _database.products;
  int get _normal => _database.normalProducts;
  int get _low => _database.lowStockProducts;
  int _page = 1;
  static const _pageSize = 10;
  List<MockProduct> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _products
        .where(
          (p) =>
              (q.isEmpty ||
                  p.name.toLowerCase().contains(q) ||
                  p.brand.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q)) &&
              (_category == '모든 카테고리' || p.brand == _category) &&
              (_filter == '재고 상태 전체' ||
                  productStatusLabel(p.status) == _filter),
        )
        .toList();
  }

  List<MockProduct> get _pageItems {
    final start = (_page - 1) * _pageSize;
    if (start >= _visible.length) return const [];
    final end = (start + _pageSize).clamp(0, _visible.length);
    return _visible.sublist(start, end);
  }

  int get _pageCount => (_visible.length / _pageSize).ceil().clamp(1, 999);

  @override
  void initState() {
    super.initState();
    _database.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _database.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Padding(
      padding: EdgeInsets.all(wide ? 26 : 14),
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
                      '재고 현황',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '제품별 재고 수량과 판매 현황을 관리합니다.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _inbound,
                icon: const Icon(Icons.add_box_outlined),
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
                '총 상품 수',
                _database.totalProducts.toString() + '개',
                '등록된 전체 상품',
                Icons.inventory_2_outlined,
                _blue,
              ),
              _Summary(
                '정상 재고',
                _normal.toString() + '개',
                _products.isEmpty
                    ? '등록 데이터 없음'
                    : (_normal * 100 / _products.length).round().toString() +
                          '%',
                Icons.check_circle_outline,
                const Color(0xFF25A77A),
              ),
              _Summary(
                '재고 부족',
                _low.toString() + '개',
                _products.isEmpty
                    ? '등록 데이터 없음'
                    : (_low * 100 / _products.length).round().toString() + '%',
                Icons.warning_amber_rounded,
                const Color(0xFFF39A39),
              ),
              _Summary(
                '오늘 판매량',
                _database.todaySalesQuantity.toString() + '개',
                '구매 기록 기준',
                Icons.trending_up,
                Color(0xFF9566D8),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: _table()),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '총 ' +
                      _products.length.toString() +
                      '개의 상품이 등록되어 있습니다. · 검색 결과 ' +
                      _visible.length.toString() +
                      '개',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ),
              IconButton(
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(_page.toString() + ' / ' + _pageCount.toString()),
              IconButton(
                onPressed: _page < _pageCount
                    ? () => setState(() => _page++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
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
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 310,
                height: 42,
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() => _page = 1),
                  decoration: InputDecoration(
                    hintText: '상품명, 브랜드, 상품코드 검색...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              _dropdown(
                _category,
                [
                  '모든 카테고리',
                  ..._products
                      .map((product) => product.category)
                      .where((value) => value.isNotEmpty)
                      .toSet(),
                ],
                (v) => setState(() {
                  _category = v;
                  _page = 1;
                }),
              ),
              _dropdown(
                _filter,
                const ['재고 상태 전체', '정상', '주의', '재고부족'],
                (v) => setState(() {
                  _filter = v;
                  _page = 1;
                }),
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
                headingRowHeight: 46,
                dataRowMinHeight: 68,
                dataRowMaxHeight: 76,
                columns: const [
                  '상품 이미지',
                  '제품명',
                  '상품코드',
                  '카테고리',
                  '현재 재고 수량',
                  '전체 수량',
                  '판매 수량',
                  '상태',
                ].map((e) => DataColumn(label: Text(e))).toList(),
                rows: _pageItems
                    .map(
                      (p) => DataRow(
                        cells: [
                          DataCell(
                            _Thumb(
                              color: _productColor(p.category),
                              imageUrl: p.imageUrl,
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 185,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    p.option,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              p.code,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _muted,
                              ),
                            ),
                          ),
                          DataCell(Text(p.brand)),
                          DataCell(
                            SizedBox(
                              width: 115,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.stock.toString() + '개'),
                                  const SizedBox(height: 5),
                                  LinearProgressIndicator(
                                    value: (p.stock / p.target).clamp(0, 1),
                                    color: p.status == ProductStatus.outOfStock
                                        ? Colors.red
                                        : p.status == ProductStatus.warning
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(p.target.toString() + '개')),
                          DataCell(
                            Text(
                              '누적 ' +
                                  p.sold.toString() +
                                  '개 / 오늘 ' +
                                  p.today.toString() +
                                  '개',
                            ),
                          ),
                          DataCell(_Tag(productStatusLabel(p.status))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _dropdown(
    String value,
    List<String> options,
    ValueChanged<String> changed,
  ) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      items: options
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) {
        if (v != null) changed(v);
      },
    ),
  );

  Future<void> _inbound() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입고 처리할 상품 데이터가 없습니다.')));
      return;
    }
    final result = await showDialog<_Receipt>(
      context: context,
      builder: (_) => _InboundDialog(products: _products),
    );
    if (!mounted || result == null) return;
    _database.receiveInventory(result.product.id, result.quantity);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('완료되었습니다.')));
  }
}

class _Receipt {
  const _Receipt(this.product, this.quantity);
  final MockProduct product;
  final int quantity;
}

class _InboundDialog extends StatefulWidget {
  const _InboundDialog({required this.products});
  final List<MockProduct> products;
  @override
  State<_InboundDialog> createState() => _InboundDialogState();
}

class _InboundDialogState extends State<_InboundDialog> {
  late MockProduct _selected = widget.products.first;
  final _search = TextEditingController(),
      _quantity = TextEditingController(),
      _price = TextEditingController(),
      _memo = TextEditingController();
  String _date = _formatDate(DateTime.now());
  String _vendor = '';
  int _photos = 0;
  @override
  void dispose() {
    _search.dispose();
    _quantity.dispose();
    _price.dispose();
    _memo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(20),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 850),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 12, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '입고 처리',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '신규 입고된 상품의 정보를 등록하여 재고를 추가합니다.',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading('❶ 상품 선택'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            hintText: '상품명, 상품코드로 검색하세요.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _find, child: const Text('검색')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _selectedCard(),
                  const SizedBox(height: 20),
                  _heading('❷ 입고 정보 입력'),
                  Row(
                    children: [
                      Expanded(child: _input('입고 수량 *', _quantity, '개', true)),
                      const SizedBox(width: 12),
                      Expanded(child: _input('입고 단가 (선택)', _price, '원', true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: '입고일 *',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(_date)),
                                const Icon(Icons.calendar_month),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _vendor,
                          decoration: const InputDecoration(
                            labelText: '입고처 (선택)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => _vendor = value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _heading('❸ 추가 정보 (선택)'),
                  TextField(
                    controller: _memo,
                    maxLength: 200,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '입고 메모',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _heading('❹ 첨부 자료 (선택)'),
                  InkWell(
                    onTap: _addPhoto,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _canvas,
                        border: Border.all(color: _line),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _blue,
                            size: 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _photos == 0
                                ? '입고 관련 사진을 업로드하세요.'
                                : '첨부 사진 ' + _photos.toString() + '장',
                          ),
                          const Text(
                            '상품 박스, 송장, 접수 사진 등 · 최대 5장까지 첨부 가능합니다.',
                            style: TextStyle(color: _muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('입고 처리'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: _navy,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
  Widget _input(
    String label,
    TextEditingController controller,
    String suffix,
    bool number,
  ) => TextField(
    controller: controller,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      hintText: null,
      suffixText: suffix,
      border: const OutlineInputBorder(),
    ),
  );
  Widget _selectedCard() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _canvas,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _line),
    ),
    child: Row(
      children: [
        _Thumb(
          color: _productColor(_selected.category),
          imageUrl: _selected.imageUrl,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selected.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _selected.option + ' · ' + _selected.code,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
              Text(
                '현재 재고 ' +
                    _selected.stock.toString() +
                    '개 · 재고 부족 기준 ' +
                    _selected.threshold.toString() +
                    '개',
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                '최근 입고일 ' +
                    (_selected.lastInbound == null
                        ? '-'
                        : _formatDate(_selected.lastInbound!)) +
                    ' · 최근 판매량 ' +
                    _selected.sold.toString() +
                    '개',
                style: const TextStyle(color: _muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  void _find() {
    final q = _search.text.trim().toLowerCase();
    final found = widget.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.code.toLowerCase().contains(q),
        )
        .toList();
    if (found.isNotEmpty)
      setState(() => _selected = found.first);
    else
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('검색 결과가 없습니다.')));
  }

  Future<void> _pickDate() async {
    final initial =
        DateTime.tryParse(_date.replaceAll('.', '-')) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date != null)
      setState(
        () => _date =
            date.year.toString() +
            '.' +
            date.month.toString().padLeft(2, '0') +
            '.' +
            date.day.toString().padLeft(2, '0'),
      );
  }

  void _addPhoto() {
    if (_photos < 5)
      setState(() => _photos++);
    else
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진은 최대 5장까지 첨부할 수 있습니다.')));
  }

  void _submit() {
    final count = int.tryParse(_quantity.text) ?? 0;
    if (count < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('입고 수량을 입력해 주세요.')));
      return;
    }
    Navigator.pop(context, _Receipt(_selected, count));
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.title, this.value, this.note, this.icon, this.color);
  final String title, value, note;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: w >= 1200 ? 220 : (w - 56) / 2,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 21,
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
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.color, required this.imageUrl});
  final Color color;
  final String imageUrl;
  @override
  Widget build(BuildContext context) => ProductImage(
    imageUrl: imageUrl,
    width: 48,
    height: 48,
    backgroundColor: color,
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final c = status == '정상'
        ? const Color(0xFF25A77A)
        : status == '주의'
        ? const Color(0xFFF39A39)
        : const Color(0xFFE15D66);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Color _productColor(String category) => category == '나이키'
    ? const Color(0xFFECEFF5)
    : category == '아디다스'
    ? const Color(0xFFE9F0EA)
    : const Color(0xFFF3ECE7);

String _formatDate(DateTime date) =>
    date.year.toString() +
    '.' +
    date.month.toString().padLeft(2, '0') +
    '.' +
    date.day.toString().padLeft(2, '0');
