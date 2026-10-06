import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/customer_cart_service.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/product_variant_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';
import 'package:step_seoul_app/view/customer/shoe_image.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class ProductDetail extends StatefulWidget {
  const ProductDetail({super.key, required this.shoe, this.variantService});
  final CustomerShoe shoe;
  final ProductVariantService? variantService;

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final _cartService = CustomerCartService();
  late final _variantService = widget.variantService ?? ProductVariantService();
  late CustomerShoe _selectedShoe = widget.shoe;
  late List<CustomerShoe> _variants = [widget.shoe];
  int _quantity = 1;
  bool _loadingVariants = false;
  String? _variantError;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  @override
  void dispose() {
    if (widget.variantService == null) _variantService.dispose();
    super.dispose();
  }

  Future<void> _loadVariants() async {
    if (_loadingVariants) return;
    setState(() {
      _loadingVariants = true;
      _variantError = null;
    });
    try {
      final variants = await _variantService.loadVariants(widget.shoe);
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _selectedShoe = variants.firstWhere(
          (shoe) => shoe.id == _selectedShoe.id,
          orElse: () => _selectedShoe,
        );
        _limitQuantity();
      });
    } on ProductVariantException catch (error) {
      if (mounted) setState(() => _variantError = error.message);
    } finally {
      if (mounted) setState(() => _loadingVariants = false);
    }
  }

  void _limitQuantity() {
    if (_selectedShoe.stock <= 0) {
      _quantity = 1;
    } else if (_quantity > _selectedShoe.stock) {
      _quantity = _selectedShoe.stock;
    }
  }

  void _selectColor(String code) {
    if (code == shoeColorCode(_selectedShoe.id)) return;
    final shoe = shoeForColor(_variants, _selectedShoe, code);
    if (shoe == null) return;
    setState(() {
      _selectedShoe = shoe;
      _limitQuantity();
    });
  }

  List<String> _sizesForSelectedColor() {
    final sizes = _variants
        .where(
          (shoe) =>
              shoeFamilyPrefix(shoe.id) == shoeFamilyPrefix(_selectedShoe.id) &&
              shoeColorCode(shoe.id) == shoeColorCode(_selectedShoe.id) &&
              shoeVariantGender(shoe.id) == shoeVariantGender(_selectedShoe.id),
        )
        .map((shoe) => shoeVariantSize(shoe.id))
        .whereType<String>()
        .toSet()
        .toList();
    sizes.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return sizes;
  }

  void _selectSize(String size) {
    final code = shoeColorCode(_selectedShoe.id);
    if (code == null) return;
    final shoe = shoeForColor(_variants, _selectedShoe, code, size: size);
    if (shoe == null || shoeVariantSize(shoe.id) != size) return;
    setState(() {
      _selectedShoe = shoe;
      _limitQuantity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shoe = _selectedShoe;
    final available = shoe.stock > 0;
    final colors = productColorOptions(_variants, shoe);
    final selectedColorCode = shoeColorCode(shoe.id);
    final selectedColor = colors
        .where((option) => option.code == selectedColorCode)
        .firstOrNull;
    final colorLabel = selectedColor?.label ?? '정보 없음';
    final size = shoeVariantSize(shoe.id) ?? '정보 없음';
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
            onPressed: () => Get.back(),
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
          _ProductHero(imageUrl: shoe.imageUrl, color: const Color(0xFFD3E8FF)),
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
            shoe.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '\uAC00\uBCBC\uACE0 \uC548\uC815\uC801\uC778 \uB370\uC77C\uB9AC \uB7EC\uB2DD\uD654 \u00B7 ' +
                shoe.id,
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Text(
                shoe.price + '\uC6D0',
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
          _SectionLabel(label: '\uC0C9\uC0C1', trailing: colorLabel),
          const SizedBox(height: 12),
          _ColorPicker(
            colors: colors,
            selected: selectedColorCode,
            onSelected: _selectColor,
          ),
          if (_loadingVariants)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('색상 확인 중…', style: TextStyle(color: _muted)),
            ),
          if (_variantError != null)
            TextButton.icon(
              onPressed: _loadVariants,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_variantError!),
            ),
          const SizedBox(height: 22),
          const _SectionLabel(
            label: '\uC0AC\uC774\uC988',
            trailing: '\uC0AC\uC774\uC988 \uC548\uB0B4',
          ),
          const SizedBox(height: 11),
          _SizePicker(
            sizes: _sizesForSelectedColor(),
            selected: size,
            onSelected: _selectSize,
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
                            shoe.stock.toString() +
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
                onPlus: available && _quantity < shoe.stock
                    ? () => setState(() => _quantity++)
                    : null,
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
                    onPressed: available ? _addToCart : null,
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
                          ? () => Get.toNamed(
                              AppRoutes.checkoutPayment,
                              arguments: CheckoutArguments(
                                items: [
                                  CheckoutLineItem(
                                    shoe: shoe,
                                    quantity: _quantity,
                                  ),
                                ],
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
                            shoe.price +
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
                '선택: $colorLabel · $size · $_quantity개 · 강남 대리점',
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
      await _cartService.addShoe(_selectedShoe, quantity: _quantity);
      if (!mounted) return;
      await Get.toNamed(AppRoutes.cart);
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
  const _ColorPicker({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });
  final List<ProductColorOption> colors;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 13,
    runSpacing: 10,
    children: colors.map((option) {
      final swatch = option.argb == null ? Colors.white : Color(option.argb!);
      final isSelected = selected == option.code;
      return Semantics(
        label: option.label,
        button: true,
        selected: isSelected,
        child: Tooltip(
          message: option.label,
          child: InkWell(
            key: ValueKey('product-color-${option.code}'),
            onTap: () => onSelected(option.code),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _blue : const Color(0xFFDCE5F1),
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: swatch.computeLuminance() > .5
                          ? _blue
                          : Colors.white,
                    )
                  : option.argb == null
                  ? const Icon(Icons.question_mark, color: _muted, size: 18)
                  : null,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _SizePicker extends StatelessWidget {
  const _SizePicker({
    required this.sizes,
    required this.selected,
    required this.onSelected,
  });
  final List<String> sizes;
  final String selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 7,
    runSpacing: 7,
    children: sizes.map((size) {
      final isSelected = size == selected;
      return OutlinedButton(
        onPressed: () => onSelected(size),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? _blue : Colors.white,
          foregroundColor: isSelected ? Colors.white : _ink,
          side: BorderSide(color: isSelected ? _blue : const Color(0xFFDCE5F1)),
        ),
        child: Text(size),
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
