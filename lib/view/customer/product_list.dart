import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/customer_bottom_tabs.dart';
import 'package:step_seoul_app/view/customer/product_detail.dart';
import 'package:step_seoul_app/view/customer/shoe_image.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class ProductList extends StatefulWidget {
  const ProductList({super.key, required this.shoes});
  final List<CustomerShoe> shoes;

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  String _category = '\uC804\uCCB4';
  String _query = '';

  List<CustomerShoe> get _visibleShoes {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.shoes;
    return widget.shoes
        .where(
          (shoe) =>
              shoe.name.toLowerCase().contains(query) ||
              shoe.id.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final shoes = _visibleShoes;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FD),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '\uCD94\uCC9C \uC2E0\uBC1C',
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDCE5F1)),
            ),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CartNavigationButton(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText:
                    '\uC0C1\uD488\uBA85, \uC0C9\uC0C1, \uC0AC\uC774\uC988 \uAC80\uC0C9',
                hintStyle: const TextStyle(color: Color(0xFF9BAAC0)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _muted,
                  size: 30,
                ),
                suffixIcon: const Icon(Icons.grid_view_rounded, color: _blue),
                filled: true,
                fillColor: Colors.white,
                border: _searchBorder(),
                enabledBorder: _searchBorder(),
                focusedBorder: _searchBorder(color: _blue),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _CategoryBar(
            selected: _category,
            onSelected: (value) => setState(() => _category = value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 12),
            child: Row(
              children: [
                Text(
                  '\uC804\uCCB4 \uC0C1\uD488 ' + shoes.length.toString(),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort_rounded, size: 18),
                  label: const Text('\uCD94\uCC9C\uC21C'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _muted,
                    side: const BorderSide(color: Color(0xFFDCE5F1)),
                  ),
                ),
                const SizedBox(width: 7),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('\uD544\uD130'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    backgroundColor: const Color(0xFFEAF3FF),
                    side: const BorderSide(color: Color(0xFFBCD4FF)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: shoes.isEmpty
                ? const _NoProducts()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: .61,
                        ),
                    itemCount: shoes.length,
                    itemBuilder: (context, index) => _ProductTile(
                      shoe: shoes[index],
                      accent: _cardAccents[index % _cardAccents.length],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomTabs(selectedIndex: 0),
    );
  }

  OutlineInputBorder _searchBorder({Color color = const Color(0xFFDCE5F1)}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: color, width: 1.3),
      );
}

const _cardAccents = [
  Color(0xFFD8E9FF),
  Color(0xFFE9EEF5),
  Color(0xFFFFF0DD),
  Color(0xFFE8E4FF),
];

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const _items = [
    '\uC804\uCCB4',
    '\uB7EC\uB2DD',
    '\uC2A4\uB2C8\uCEE4\uC988',
    '\uAD6C\uB450',
    '\uD0A4\uC988',
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (context, index) {
        final item = _items[index];
        final active = item == selected;
        return ChoiceChip(
          label: Text(item),
          selected: active,
          onSelected: (_) => onSelected(item),
          selectedColor: _blue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: active ? Colors.white : const Color(0xFF536680),
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: active ? _blue : const Color(0xFFDCE5F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        );
      },
    ),
  );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.shoe, required this.accent});
  final CustomerShoe shoe;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final inStock = shoe.stock > 0;
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ProductDetail(shoe: shoe))),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B1F3C70),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 151,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ShoeImage(
                      imageUrl: shoe.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF71839E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AvailabilityTag(inStock: inStock),
            const SizedBox(height: 7),
            Text(
              shoe.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID \u00B7 ' + shoe.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 7),
            Text(
              shoe.price + '\uC6D0',
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              inStock
                  ? '\uB300\uB9AC\uC810 \uC7AC\uACE0 ' +
                        shoe.stock.toString() +
                        '\uAC1C'
                  : '\uC7AC\uACE0 \uC5C6\uC74C',
              style: TextStyle(
                color: inStock ? _blue : const Color(0xFFFF5A68),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag({required this.inStock});
  final bool inStock;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: inStock ? const Color(0xFFE8F9F1) : const Color(0xFFFFECEF),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      inStock ? '\uC7AC\uACE0 \uC788\uC74C' : '\uD488\uC808',
      style: TextStyle(
        color: inStock ? const Color(0xFF1D9B63) : const Color(0xFFDD4961),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ShoeArtwork extends StatelessWidget {
  const _ShoeArtwork({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ShoePainter(color), child: const SizedBox.expand());
}

class _ShoePainter extends CustomPainter {
  const _ShoePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final shoe = Paint()..color = color;
    final line = Paint()
      ..color = const Color(0xFF95C4FF)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .035;
    final path = Path()
      ..moveTo(size.width * .07, size.height * .70)
      ..cubicTo(
        size.width * .12,
        size.height * .47,
        size.width * .36,
        size.height * .64,
        size.width * .49,
        size.height * .16,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .56,
        size.width * .76,
        size.height * .55,
        size.width * .90,
        size.height * .68,
      )
      ..lineTo(size.width * .88, size.height * .88)
      ..lineTo(size.width * .14, size.height * .88)
      ..cubicTo(
        size.width * .05,
        size.height * .84,
        size.width * .05,
        size.height * .76,
        size.width * .07,
        size.height * .70,
      )
      ..close();
    canvas.drawPath(path, shoe);
    canvas.drawLine(
      Offset(size.width * .37, size.height * .49),
      Offset(size.width * .65, size.height * .64),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .25, size.height * .68),
      Offset(size.width * .75, size.height * .68),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .16, size.height * .84),
      Offset(size.width * .82, size.height * .84),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _ShoePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _NoProducts extends StatelessWidget {
  const _NoProducts();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      '\uC870\uAC74\uC5D0 \uB9DE\uB294 \uC0C1\uD488\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
      style: TextStyle(color: _muted),
    ),
  );
}
