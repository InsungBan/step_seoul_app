import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_cart_service.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class CartNavigationButton extends StatelessWidget {
  const CartNavigationButton({super.key});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 21,
    backgroundColor: Colors.white,
    child: IconButton(
      tooltip: '\uC7A5\uBC14\uAD6C\uB2C8',
      icon: const Icon(Icons.shopping_bag_outlined, color: _muted),
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CartPage())),
    ),
  );
}

class _CartPageState extends State<CartPage> {
  final _service = CustomerCartService();
  late Future<CustomerCartData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = _service.loadCart();

  Future<void> _mutate(
    Future<void> Function(CustomerCartData data) action,
  ) async {
    final data = await _future;
    setState(() => _busy = true);
    try {
      await action(data);
      if (mounted) setState(_reload);
    } on CustomerCartException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '\uC7A5\uBC14\uAD6C\uB2C8',
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
          padding: EdgeInsets.only(right: 20),
          child: Center(
            child: Text('\uD3B8\uC9D1', style: TextStyle(color: _muted)),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: FutureBuilder<CustomerCartData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(
                child: CircularProgressIndicator(color: _blue),
              );
            if (snapshot.hasError)
              return _CartError(onRetry: () => setState(_reload));
            final data = snapshot.requireData;
            if (data.items.isEmpty) return const _EmptyCart();
            final store = data.selectedStore;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 7, 20, 24),
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _blue,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '\uC804\uCCB4 \uC120\uD0DD ' +
                          data.items.length.toString(),
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _mutate((cart) async {
                              for (final item in cart.items) {
                                await _service.removeAll(cart, item);
                              }
                            }),
                      child: const Text(
                        '\uC120\uD0DD \uC0AD\uC81C',
                        style: TextStyle(color: _muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.items.map(
                  (item) => _CartItemCard(
                    item: item,
                    busy: _busy,
                    onAdd: () => _mutate((cart) => _service.addShoe(item.shoe)),
                    onRemoveOne: item.quantity > 1
                        ? () =>
                              _mutate((cart) => _service.removeOne(cart, item))
                        : null,
                    onDelete: () =>
                        _mutate((cart) => _service.removeAll(cart, item)),
                  ),
                ),
                const SizedBox(height: 21),
                const Text(
                  '\uC218\uB839 \uB300\uB9AC\uC810',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _StoreCard(
                  name: store?.name ?? '\uB300\uB9AC\uC810 \uBC30\uC815 \uC911',
                  detail: store == null
                      ? '\uC218\uB839 \uB300\uB9AC\uC810\uC744 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.'
                      : store.district + '  ' + store.phone,
                ),
                const SizedBox(height: 26),
                const Text(
                  '\uACB0\uC81C \uC608\uC815 \uAE08\uC561',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _PaymentSummary(total: data.total),
                const SizedBox(height: 20),
                const _InfoNotice(),
              ],
            );
          },
        ),
      ),
    ),
    bottomNavigationBar: FutureBuilder<CustomerCartData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.requireData.items.isEmpty) {
          return const SizedBox.shrink();
        }
        final data = snapshot.requireData;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _CheckoutBar(
              total: data.total,
              count: data.items.length,
              onOrder: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CheckoutPaymentPage(
                    items: data.items
                        .map(
                          (item) => CheckoutLineItem(
                            shoe: item.shoe,
                            quantity: item.quantity,
                          ),
                        )
                        .toList(),
                    store: data.selectedStore,
                    clearCart: true,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.busy,
    required this.onAdd,
    required this.onRemoveOne,
    required this.onDelete,
  });
  final CustomerCartItem item;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback? onRemoveOne;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 13),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A1F3C70),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _blue, size: 27),
            const SizedBox(width: 9),
            const Text(
              'STEP SEOUL',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            IconButton(
              onPressed: busy ? null : onDelete,
              icon: const Icon(Icons.close_rounded, color: _muted),
            ),
          ],
        ),
        const Divider(color: Color(0xFFE6EDF6)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFD3E8FF),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: _CartShoeArtwork(),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\uC624\uB298 \uC218\uB839 \uAC00\uB2A5',
                    style: TextStyle(
                      color: Color(0xFF27A96E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.shoe.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID \u00B7 ' + item.shoe.id,
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _won(item.unitPrice),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(89, 35),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('\uC635\uC158 \uBCC0\uACBD'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 28, color: Color(0xFFE6EDF6)),
        Row(
          children: [
            const Text(
              '\uC218\uB7C9',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 16),
            _QuantityControl(
              quantity: item.quantity,
              enabled: !busy,
              onMinus: onRemoveOne,
              onPlus: onAdd,
            ),
            const Spacer(),
            Text(
              _won(item.total),
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.circle, color: Color(0xFF25C979), size: 10),
            SizedBox(width: 7),
            Text(
              '\uC120\uD0DD\uD55C \uB300\uB9AC\uC810 \uC7AC\uACE0\uAC00 \uD655\uBCF4\uB418\uC5B4 \uC788\uC2B5\uB2C8\uB2E4.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
  });
  final int quantity;
  final bool enabled;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFF9FBFF),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFDCE5F1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: enabled ? onMinus : null,
          icon: const Icon(Icons.remove_rounded, color: _muted),
        ),
        Text(
          quantity.toString(),
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: enabled ? onPlus : null,
          icon: const Icon(Icons.add_rounded, color: _blue),
        ),
      ],
    ),
  );
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.name, required this.detail});
  final String name;
  final String detail;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDCE5F1)),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: _blue, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
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
  );
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        _PriceRow(label: '\uC0C1\uD488 \uAE08\uC561', value: _won(total)),
        const SizedBox(height: 14),
        const _PriceRow(
          label: '\uB300\uB9AC\uC810 \uC218\uB839',
          value: '\uBB34\uB8CC',
          accent: true,
        ),
        const SizedBox(height: 14),
        const _PriceRow(label: '\uD560\uC778 \uAE08\uC561', value: '0\uC6D0'),
        const Divider(height: 28, color: Color(0xFFDCE5F1)),
        Row(
          children: [
            const Text(
              '\uCD1D \uACB0\uC81C\uAE08\uC561',
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              _won(total),
              style: const TextStyle(
                color: _blue,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(color: _muted)),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          color: accent ? const Color(0xFF1DAB6D) : _ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_rounded, color: _blue),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            '\uB300\uB9AC\uC810 \uB3C4\uCC29 \uC54C\uB9BC \uD6C4 \uC218\uB839 QR\uC744 \uC81C\uC2DC\uD574 \uC8FC\uC138\uC694.',
            style: TextStyle(color: Color(0xFF56709A), fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.count,
    required this.onOrder,
  });
  final int total;
  final int count;
  final VoidCallback onOrder;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\uC120\uD0DD \uC0C1\uD488 ' + count.toString() + '\uAC1C',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                Text(
                  _won(total),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: onOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(57),
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                count.toString() +
                    '\uAC1C \uC0C1\uD488 \uC8FC\uBB38\uD558\uAE30',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shopping_bag_outlined, size: 62, color: _blue),
        SizedBox(height: 14),
        Text(
          '\uC7A5\uBC14\uAD6C\uB2C8\uAC00 \uBE44\uC5B4 \uC788\uC2B5\uB2C8\uB2E4.',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _CartError extends StatelessWidget {
  const _CartError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: FilledButton(
      onPressed: onRetry,
      child: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
    ),
  );
}

class _CartShoeArtwork extends StatelessWidget {
  const _CartShoeArtwork();
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _CartShoePainter(),
    child: const SizedBox.expand(),
  );
}

class _CartShoePainter extends CustomPainter {
  const _CartShoePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final shoe = Paint()..color = Colors.white;
    final line = Paint()
      ..color = const Color(0xFF78B2F4)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .042;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .70)
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
        size.width * .08,
        size.height * .70,
      )
      ..close();
    canvas.drawPath(path, shoe);
    canvas.drawLine(
      Offset(size.width * .35, size.height * .51),
      Offset(size.width * .65, size.height * .65),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .18, size.height * .83),
      Offset(size.width * .82, size.height * .83),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _CartShoePainter oldDelegate) => false;
}

String _won(int price) {
  final digits = price.toString();
  return digits.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => match.group(1)! + ',',
      ) +
      '\uC6D0';
}
