import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_cart_service.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';
import 'package:step_seoul_app/view/customer/shoe_image.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.shoe});
  final CustomerShoe shoe;

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final _cartService = CustomerCartService();
  int _quantity = 1;
  String _size = '270';
  int _colorIndex = 0;

  @override
  Widget build(BuildContext context) {
    final available = widget.shoe.stock > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FD),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '\uC0C1\uD488 \uC0C1\uC138',
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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 7),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.share_outlined, color: _muted),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CartNavigationButton(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 18),
        children: [
          _ProductHero(
            imageUrl: widget.shoe.imageUrl,
            color: _colorIndex == 0
                ? const Color(0xFFD3E8FF)
                : _colorIndex == 1
                ? const Color(0xFF20293C)
                : const Color(0xFFD7DCE5),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CarouselDot(active: true),
              _CarouselDot(),
              _CarouselDot(),
            ],
          ),
          const SizedBox(height: 24),
          _Availability(available: available),
          const SizedBox(height: 11),
          Text(
            widget.shoe.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '\uAC00\uBCBC\uACE0 \uC548\uC815\uC801\uC778 \uB370\uC77C\uB9AC \uB7EC\uB2DD\uD654 \u00B7 ' +
                widget.shoe.id,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Text(
                widget.shoe.price + '\uC6D0',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              const Text(
                '\uBB34\uB8CC \uB300\uB9AC\uC810 \uC218\uB839',
                style: TextStyle(color: _muted),
              ),
            ],
          ),
          const Divider(height: 27, color: Color(0xFFDCE5F1)),
          _SectionLabel(
            label: '\uC0C9\uC0C1',
            trailing: _colorIndex == 0
                ? '\uC624\uD504\uD654\uC774\uD2B8'
                : _colorIndex == 1
                ? '\uB124\uC774\uBE44'
                : '\uADF8\uB808\uC774',
          ),
          const SizedBox(height: 12),
          _ColorPicker(
            selected: _colorIndex,
            onSelected: (index) => setState(() => _colorIndex = index),
          ),
          const SizedBox(height: 22),
          const _SectionLabel(
            label: '\uC0AC\uC774\uC988',
            trailing: '\uC0AC\uC774\uC988 \uC548\uB0B4',
          ),
          const SizedBox(height: 11),
          _SizePicker(
            selected: _size,
            onSelected: (value) => setState(() => _size = value),
          ),
          const SizedBox(height: 22),
          const Text(
            '\uC218\uB839 \uB300\uB9AC\uC810',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFDCE5F1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: _blue, size: 39),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\uAC15\uB0A8 \uB300\uB9AC\uC810',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\uC7AC\uACE0 ' +
                            widget.shoe.stock.toString() +
                            '\uAC1C \u00B7 \uC624\uB298 \uC218\uB839 \uAC00\uB2A5',
                        style: TextStyle(
                          color: Color(0xFF26A66C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    '\uBCC0\uACBD',
                    style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                '\uC218\uB7C9',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              _QuantityPicker(
                quantity: _quantity,
                onMinus: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                onPlus: available ? () => setState(() => _quantity++) : null,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 11),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _addToCart,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(57, 57),
                      side: const BorderSide(color: Color(0xFFDCE5F1)),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: _ink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: available
                          ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CheckoutPaymentPage(
                                  items: [
                                    CheckoutLineItem(
                                      shoe: widget.shoe,
                                      quantity: _quantity,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(57),
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        '\uAD6C\uB9E4\uD558\uAE30  \u00B7  ' +
                            widget.shoe.price +
                            '\uC6D0',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                '\uC120\uD0DD: \uC624\uD504\uD654\uC774\uD2B8 \u00B7 ' +
                    _size +
                    ' \u00B7 ' +
                    _quantity.toString() +
                    '\uAC1C \u00B7 \uAC15\uB0A8 \uB300\uB9AC\uC810',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _addToCart() async {
    try {
      await _cartService.addShoe(widget.shoe, quantity: _quantity);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CartPage()));
    } on CustomerCartException catch (error) {
      _notice(error.message);
    } catch (_) {
      _notice('Unable to connect to the server.');
    }
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.color, required this.imageUrl});
  final Color color;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        height: 360,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ShoeImage(imageUrl: imageUrl, fit: BoxFit.contain),
        ),
      ),
      Positioned(
        top: 16,
        left: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Text(
            'BEST 01',
            style: TextStyle(
              color: _blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      const Positioned(
        top: 15,
        right: 15,
        child: CircleAvatar(
          radius: 21,
          backgroundColor: Colors.white,
          child: Icon(Icons.favorite_rounded, color: _blue, size: 29),
        ),
      ),
    ],
  );
}

class _ShoeArtwork extends StatelessWidget {
  const _ShoeArtwork();
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _ShoePainter(),
    child: const SizedBox.expand(),
  );
}

class _ShoePainter extends CustomPainter {
  const _ShoePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final shoe = Paint()..color = Colors.white;
    final shadow = Paint()..color = const Color(0x1D3D79C9);
    final line = Paint()
      ..color = const Color(0xFF73AFF0)
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
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .91),
        width: size.width * .8,
        height: size.height * .12,
      ),
      shadow,
    );
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
  bool shouldRepaint(covariant _ShoePainter oldDelegate) => false;
}

class _CarouselDot extends StatelessWidget {
  const _CarouselDot({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    width: active ? 11 : 9,
    height: active ? 11 : 9,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: active ? _blue : const Color(0xFFCAD5E5),
      shape: BoxShape.circle,
    ),
  );
}

class _Availability extends StatelessWidget {
  const _Availability({required this.available});
  final bool available;
  @override
  Widget build(BuildContext context) => Text(
    available ? '\uC7AC\uACE0 \uC788\uC74C' : '\uD488\uC808',
    style: TextStyle(
      color: available ? const Color(0xFF1D9B63) : const Color(0xFFDD4961),
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.trailing});
  final String label;
  final String trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 21),
      Text(trailing, style: const TextStyle(color: _muted)),
      const Spacer(),
      if (label == '\uC0AC\uC774\uC988')
        const Text(
          '\uC0AC\uC774\uC988 \uC548\uB0B4',
          style: TextStyle(color: _blue, fontSize: 12),
        ),
    ],
  );
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const _colors = [Colors.white, Color(0xFF17233C), Color(0xFFAAB3C2)];
  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(
      _colors.length,
      (index) => Padding(
        padding: const EdgeInsets.only(right: 13),
        child: InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(25),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _colors[index],
              shape: BoxShape.circle,
              border: Border.all(
                color: selected == index ? _blue : const Color(0xFFDCE5F1),
                width: selected == index ? 3 : 1,
              ),
            ),
            child: selected == index
                ? Icon(
                    Icons.check_rounded,
                    color: index == 0 ? _blue : Colors.white,
                  )
                : null,
          ),
        ),
      ),
    ),
  );
}

class _SizePicker extends StatelessWidget {
  const _SizePicker({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const _sizes = ['250', '260', '270', '280', '290'];
  @override
  Widget build(BuildContext context) => Row(
    children: _sizes.map((size) {
      final selected = size == this.selected;
      final disabled = size == '290';
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 7),
          child: OutlinedButton(
            onPressed: disabled ? null : () => onSelected(size),
            style: OutlinedButton.styleFrom(
              backgroundColor: selected ? _blue : Colors.white,
              foregroundColor: selected ? Colors.white : _ink,
              side: BorderSide(
                color: selected ? _blue : const Color(0xFFDCE5F1),
              ),
            ),
            child: Text(
              size,
              style: TextStyle(
                decoration: disabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _QuantityPicker extends StatelessWidget {
  const _QuantityPicker({
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });
  final int quantity;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFDCE5F1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onMinus,
          icon: const Icon(Icons.remove_rounded, color: _muted),
        ),
        Text(
          quantity.toString(),
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onPlus,
          icon: const Icon(Icons.add_rounded, color: _blue),
        ),
      ],
    ),
  );
}
