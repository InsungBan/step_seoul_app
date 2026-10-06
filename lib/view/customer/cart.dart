import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/customer_cart_service.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/product_variant_service.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';
import 'package:step_seoul_app/view/customer/shoe_image.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);
const _line = Color(0xFFDCE5F1);

class CartPage extends StatefulWidget {
  const CartPage({super.key, this.service});

  final CustomerCartService? service;

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
      tooltip: '장바구니',
      icon: const Icon(Icons.shopping_bag_outlined, color: _muted),
      onPressed: () => Get.toNamed(AppRoutes.cart),
    ),
  );
}

class _CartPageState extends State<CartPage> {
  late final CustomerCartService _service;
  late Future<CustomerCartData> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CustomerCartService();
    _reload();
  }

  void _reload() => _future = _service.loadCart();

  Future<void> _mutate(
    Future<void> Function(CustomerCartData data) action,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final data = await _future;
      await action(data);
      if (mounted) setState(_reload);
    } on CustomerCartException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('서버에 연결할 수 없습니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearCart(CustomerCartData data) async {
    await _mutate((cart) async {
      for (final item in cart.items) {
        await _service.removeAll(cart, item);
      }
    });
  }

  Future<void> _chooseStore(CustomerCartData data) async {
    if (data.stores.isEmpty) {
      _message('선택할 수 있는 대리점이 없습니다.');
      return;
    }
    final selected = await Get.toNamed(
      AppRoutes.branchList,
      arguments: BranchListArguments(
        stores: data.stores,
        selectedStoreId: data.selectedStore?.id,
      ),
    );
    if (selected is CustomerStore && mounted) setState(_reload);
  }

  void _checkout(CustomerCartData data) {
    if (data.selectedStore == null) {
      _message('수령 대리점을 먼저 선택해 주세요.');
      return;
    }
    Get.toNamed(
      AppRoutes.checkoutPayment,
      arguments: CheckoutArguments(
        items: data.items
            .map(
              (item) =>
                  CheckoutLineItem(shoe: item.shoe, quantity: item.quantity),
            )
            .toList(),
        store: data.selectedStore,
        clearCart: true,
      ),
    );
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CustomerCartData>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final hasItems = data?.items.isNotEmpty == true;
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FD),
        appBar: _CartAppBar(
          canClear: hasItems && !_busy,
          onClear: data == null ? null : () => _clearCart(data),
        ),
        body: _buildBody(snapshot),
        bottomNavigationBar: hasItems
            ? _CheckoutBar(
                total: data!.total,
                count: _itemCount(data),
                busy: _busy,
                onOrder: () => _checkout(data),
              )
            : null,
      );
    },
  );

  Widget _buildBody(AsyncSnapshot<CustomerCartData> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator(color: _blue));
    }
    if (snapshot.hasError) {
      return _CartError(onRetry: () => setState(_reload));
    }
    final data = snapshot.requireData;
    if (data.items.isEmpty) return const _EmptyCart();
    return _CartContent(
      data: data,
      busy: _busy,
      onChooseStore: () => _chooseStore(data),
      onAdd: (item) => _mutate((_) => _service.addShoe(item.shoe)),
      onRemoveOne: (item) => _mutate((cart) => _service.removeOne(cart, item)),
      onDelete: (item) => _mutate((cart) => _service.removeAll(cart, item)),
    );
  }
}

class _CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CartAppBar({required this.canClear, required this.onClear});

  final bool canClear;
  final VoidCallback? onClear;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: const Color(0xFFF7F9FD),
    elevation: 0,
    centerTitle: true,
    title: const Text(
      '장바구니',
      style: TextStyle(color: _ink, fontSize: 21, fontWeight: FontWeight.w800),
    ),
    leading: Padding(
      padding: const EdgeInsets.all(8),
      child: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: _line),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: canClear ? onClear : null,
        child: const Text('전체 삭제'),
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _CartContent extends StatelessWidget {
  const _CartContent({
    required this.data,
    required this.busy,
    required this.onChooseStore,
    required this.onAdd,
    required this.onRemoveOne,
    required this.onDelete,
  });

  final CustomerCartData data;
  final bool busy;
  final VoidCallback onChooseStore;
  final ValueChanged<CustomerCartItem> onAdd;
  final ValueChanged<CustomerCartItem> onRemoveOne;
  final ValueChanged<CustomerCartItem> onDelete;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        children: [
          _CartSummaryHeader(
            kinds: data.items.length,
            count: _itemCount(data),
            busy: busy,
          ),
          const SizedBox(height: 12),
          for (final item in data.items)
            _CartItemCard(
              item: item,
              busy: busy,
              onAdd: item.quantity < item.shoe.stock ? () => onAdd(item) : null,
              onRemoveOne: item.quantity > 1 ? () => onRemoveOne(item) : null,
              onDelete: () => onDelete(item),
            ),
          const SizedBox(height: 10),
          const _SectionTitle('수령 대리점'),
          const SizedBox(height: 10),
          _StoreCard(store: data.selectedStore, onChange: onChooseStore),
          const SizedBox(height: 24),
          const _SectionTitle('결제 금액'),
          const SizedBox(height: 10),
          _PaymentSummary(total: data.total),
          const SizedBox(height: 16),
          const _InfoNotice(),
        ],
      ),
    ),
  );
}

class _CartSummaryHeader extends StatelessWidget {
  const _CartSummaryHeader({
    required this.kinds,
    required this.count,
    required this.busy,
  });

  final int kinds;
  final int count;
  final bool busy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.shopping_bag_rounded, color: _blue, size: 24),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          '$kinds종 · 총 $count개',
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ),
      if (busy)
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
        ),
    ],
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
  final VoidCallback? onAdd;
  final VoidCallback? onRemoveOne;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final size = shoeVariantSize(item.shoe.id);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: busy ? .65 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A1F3C70),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.shoe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '상품 삭제',
                  visualDensity: VisualDensity.compact,
                  onPressed: busy ? null : onDelete,
                  icon: const Icon(Icons.close_rounded, color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ShoeImage(
                    imageUrl: item.shoe.imageUrl,
                    fit: BoxFit.contain,
                    iconColor: _blue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AvailabilityBadge(stock: item.shoe.stock),
                      const SizedBox(height: 7),
                      Text(
                        'ID · ${item.shoe.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        size == null ? item.shoe.category : '사이즈 $size',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _won(item.unitPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28, color: Color(0xFFE6EDF6)),
            Row(
              children: [
                _QuantityControl(
                  quantity: item.quantity,
                  onMinus: busy ? null : onRemoveOne,
                  onPlus: busy ? null : onAdd,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _won(item.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
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

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final available = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F9F1) : const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        available ? '재고 $stock개' : '품절',
        style: TextStyle(
          color: available ? const Color(0xFF168856) : const Color(0xFFDD4961),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
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
      color: const Color(0xFFF7F9FD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove_rounded,
          onPressed: onMinus,
          color: _muted,
        ),
        SizedBox(
          width: 34,
          child: Text(
            quantity.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ),
        _QuantityButton(
          icon: Icons.add_rounded,
          onPressed: onPlus,
          color: _blue,
        ),
      ],
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => IconButton(
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    onPressed: onPressed,
    icon: Icon(icon, color: onPressed == null ? _line : color, size: 20),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _ink,
      fontSize: 19,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.onChange});

  final CustomerStore? store;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _line),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF3FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storefront_rounded, color: _blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store?.name ?? '수령 대리점을 선택해 주세요',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                store == null
                    ? '결제 전에 수령할 대리점을 선택합니다.'
                    : '${store!.district}  ${store!.phone}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onChange, child: const Text('변경')),
      ],
    ),
  );
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE8EDF5)),
    ),
    child: Column(
      children: [
        _PriceRow(label: '상품 금액', value: _won(total)),
        const SizedBox(height: 13),
        const _PriceRow(label: '대리점 수령', value: '무료', accent: true),
        const SizedBox(height: 13),
        const _PriceRow(label: '할인 금액', value: '0원'),
        const Divider(height: 28, color: _line),
        _PriceRow(
          label: '총 결제금액',
          value: _won(total),
          total: true,
          accent: true,
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
    this.total = false,
  });

  final String label;
  final String value;
  final bool accent;
  final bool total;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: total ? _ink : _muted,
            fontSize: total ? 16 : 14,
            fontWeight: total ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent ? _blue : _ink,
            fontSize: total ? 22 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_rounded, color: _blue, size: 21),
        SizedBox(width: 9),
        Expanded(
          child: Text(
            '대리점 도착 알림을 받은 뒤 수령 QR을 제시해 주세요.',
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
    required this.busy,
    required this.onOrder,
  });

  final int total;
  final int count;
  final bool busy;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 14,
    shadowColor: const Color(0x2417233C),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 568),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '총 $count개',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    Text(
                      _won(total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: busy ? null : onOrder,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    '$count개 주문하기',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 42,
              color: _blue,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '장바구니가 비어 있습니다.',
            style: TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text('마음에 드는 신발을 담아 보세요.', style: TextStyle(color: _muted)),
        ],
      ),
    ),
  );
}

class _CartError extends StatelessWidget {
  const _CartError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: _muted, size: 44),
          const SizedBox(height: 12),
          const Text('장바구니를 불러오지 못했습니다.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    ),
  );
}

int _itemCount(CustomerCartData data) =>
    data.items.fold(0, (sum, item) => sum + item.quantity);

String _won(int price) {
  final digits = price.toString();
  return '${digits.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')}원';
}
