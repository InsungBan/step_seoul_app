import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/services/customer_cart_service.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/checkout_service.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class CheckoutLineItem {
  const CheckoutLineItem({required this.shoe, required this.quantity});
  final CustomerShoe shoe;
  final int quantity;
  int get unitPrice =>
      int.tryParse(shoe.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  int get total => unitPrice * quantity;
}

class CheckoutPaymentPage extends StatefulWidget {
  const CheckoutPaymentPage({
    super.key,
    required this.items,
    this.store,
    this.clearCart = false,
  });
  final List<CheckoutLineItem> items;
  final CustomerStore? store;
  final bool clearCart;

  @override
  State<CheckoutPaymentPage> createState() => _CheckoutPaymentPageState();
}

class _CheckoutPaymentPageState extends State<CheckoutPaymentPage> {
  final _checkoutService = CheckoutService();
  CustomerStore? _store;
  String _paymentMethod = '\uC2E0\uC6A9\u00B7\uCCB4\uD06C\uCE74\uB4DC';
  bool _agreed = true;
  bool _paying = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
    _loadCheckoutContext();
  }

  Future<void> _loadCheckoutContext() async {
    final session = await SessionService.instance.readSession();
    CustomerStore? selectedStore = _store;
    if (selectedStore == null) {
      try {
        selectedStore = (await CustomerCartService().loadCart()).selectedStore;
      } catch (_) {
        // The order page can still present the selected product offline.
      }
    }
    if (mounted) {
      setState(() {
        _userId = session?.userId;
        _store = selectedStore;
      });
    }
  }

  int get _total => widget.items.fold(0, (sum, item) => sum + item.total);
  int get _count => widget.items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _pay() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uC8FC\uBB38 \uB0B4\uC6A9\uACFC \uACB0\uC81C\uC5D0 \uB3D9\uC758\uD574 \uC8FC\uC138\uC694.',
          ),
        ),
      );
      return;
    }
    if (_store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uC218\uB839 \uB300\uB9AC\uC810\uC744 \uBA3C\uC800 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('\uACB0\uC81C\uB97C \uC9C4\uD589\uD560\uAE4C\uC694?'),
        content: Text(
          '${_won(_total)}\uC744 $_paymentMethod\uB85C \uACB0\uC81C\uD569\uB2C8\uB2E4.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('\uCDE8\uC18C'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('\uACB0\uC81C\uD558\uAE30'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _paying = true);
    try {
      final receipt = await _checkoutService.complete(
        items: widget.items,
        store: _store!,
        paymentMethod: _paymentMethod,
        clearCart: widget.clearCart,
      );
      if (!mounted) return;
      await Get.offNamed(AppRoutes.orderComplete, arguments: receipt);
    } on CheckoutException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\uACB0\uC81C \uCC98\uB9AC \uC911 \uC5F0\uACB0 \uC624\uB958\uAC00 \uBC1C\uC0DD\uD588\uC2B5\uB2C8\uB2E4.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '\uC8FC\uBB38\uC11C \u00B7 \uACB0\uC81C',
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
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: CartNavigationButton(),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const _CheckoutStep(),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  '\uC8FC\uBB38 \uC0C1\uD488',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '\uCD1D $_count\uAC1C',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.items.map((item) => _OrderItemCard(item: item)),
            const SizedBox(height: 24),
            const Text(
              '\uC218\uB839 \uC815\uBCF4',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _PickupInfo(store: _store, userId: _userId),
            const SizedBox(height: 24),
            const Text(
              '\uACB0\uC81C \uC218\uB2E8',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _PaymentMethodCard(
              selected: _paymentMethod,
              onSelected: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: 24),
            const Text(
              '\uCD5C\uC885 \uACB0\uC81C \uAE08\uC561',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _TotalCard(total: _total),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              activeColor: _blue,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                '\uC8FC\uBB38 \uB0B4\uC6A9\uACFC \uACB0\uC81C\uC5D0 \uB3D9\uC758\uD569\uB2C8\uB2E4.',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
              ),
              secondary: const Text(
                '\uD544\uC218 \uC57D\uAD00 \uBCF4\uAE30',
                style: TextStyle(color: _blue, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  '\uCD1D \uACB0\uC81C\uAE08\uC561',
                  style: TextStyle(color: _muted),
                ),
                const Spacer(),
                Text(
                  _won(_total),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: widget.items.isEmpty || _paying ? null : _pay,
              icon: const Icon(Icons.lock_outline_rounded),
              label: _paying
                  ? const SizedBox(
                      height: 21,
                      width: 21,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text('${_won(_total)} \uACB0\uC81C\uD558\uAE30'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(57),
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '\uACB0\uC81C \uC644\uB8CC \uD6C4 \uC120\uD0DD\uD55C \uB300\uB9AC\uC810\uC5D0\uC11C \uC218\uB839\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
              style: TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CheckoutStep extends StatelessWidget {
  const _CheckoutStep();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _Step(label: '\uC7A5\uBC14\uAD6C\uB2C8', complete: true),
      Expanded(child: Divider(color: _blue, thickness: 2)),
      _Step(label: '\uC8FC\uBB38 \u00B7 \uACB0\uC81C', active: true),
      Expanded(child: Divider(color: Color(0xFFDCE5F1), thickness: 2)),
      _Step(label: '\uC644\uB8CC'),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    this.complete = false,
    this.active = false,
  });
  final String label;
  final bool complete;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: active || complete ? _blue : const Color(0xFFF0F3F8),
        child: complete
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : Text(
                active ? '2' : '3',
                style: TextStyle(
                  color: active ? Colors.white : _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          color: active ? _blue : _muted,
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ],
  );
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});
  final CheckoutLineItem item;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Row(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFD5E8FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: Colors.white,
            size: 52,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TodayTag(),
              const SizedBox(height: 7),
              Text(
                item.shoe.name,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.shoe.id} \u00B7 ${item.quantity}\uAC1C',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 7),
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
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFB2C0D1)),
      ],
    ),
  );
}

class _TodayTag extends StatelessWidget {
  const _TodayTag();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F9F1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      '\uC624\uB298 \uC218\uB839',
      style: TextStyle(
        color: Color(0xFF28A86C),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PickupInfo extends StatelessWidget {
  const _PickupInfo({required this.store, required this.userId});
  final CustomerStore? store;
  final String? userId;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        _PickupRow(
          icon: Icons.location_on_outlined,
          label: '\uC218\uB839 \uB300\uB9AC\uC810',
          value: store?.name.isNotEmpty == true
              ? store!.name
              : '\uB300\uB9AC\uC810 \uC120\uD0DD \uD544\uC694',
          detail: store == null
              ? '\uC218\uB839 \uC9C0\uC810\uC744 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.'
              : '${store!.district} \u00B7 \uC601\uC5C5 \uC911',
          action: '\uBCC0\uACBD',
        ),
        _PickupRow(
          icon: Icons.person_outline_rounded,
          label: '\uC218\uB839\uC790 \u00B7 \uC5F0\uB77D\uCC98',
          value: userId ?? '\uB85C\uADF8\uC778 \uD544\uC694',
          detail:
              '\uB85C\uADF8\uC778 \uACC4\uC815\uC744 \uC0AC\uC6A9\uD569\uB2C8\uB2E4.',
          action: '\uC218\uC815',
        ),
      ],
    ),
  );
}

class _PickupRow extends StatelessWidget {
  const _PickupRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.action,
  });
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final String action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: const Color(0xFFF0F5FF),
          child: Icon(icon, color: _blue, size: 28),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF28A86C), fontSize: 11),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            action,
            style: const TextStyle(color: _blue, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const methods = [
    '\uC2E0\uC6A9\u00B7\uCCB4\uD06C\uCE74\uB4DC',
    '\uAC04\uD3B8\uACB0\uC81C',
    '\uACC4\uC88C\uC774\uCCB4',
  ];
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        Row(
          children: methods
              .map(
                (method) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Text(method, overflow: TextOverflow.ellipsis),
                      selected: method == selected,
                      onSelected: (_) => onSelected(method),
                      selectedColor: const Color(0xFFEAF3FF),
                      labelStyle: TextStyle(
                        color: method == selected ? _blue : _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: method == selected
                            ? _blue
                            : const Color(0xFFDCE5F1),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFE),
            border: Border.all(color: const Color(0xFFDCE5F1)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.credit_card_rounded,
                color: Color(0xFF192D66),
                size: 30,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\uB4F1\uB85D \uCE74\uB4DC',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                    Text(
                      '\uAC1C\uC778 \uCE74\uB4DC \u00B7 \ub05d\uc790\ub9ac 2026 \u00B7 \uc77c\uc2dc\ubd88',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        _TotalRow(label: '\uC0C1\uD488 \uAE08\uC561', value: _won(total)),
        const SizedBox(height: 12),
        const _TotalRow(
          label: '\uB300\uB9AC\uC810 \uC218\uB839',
          value: '\uBB34\uB8CC',
          green: true,
        ),
        const Divider(height: 25, color: Color(0xFFDCE5F1)),
        _TotalRow(
          label: '\uCD1D \uACB0\uC81C\uAE08\uC561',
          value: _won(total),
          bold: true,
        ),
      ],
    ),
  );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.green = false,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool green;
  final bool bold;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          color: bold ? _ink : _muted,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          color: green
              ? const Color(0xFF28A86C)
              : bold
              ? _blue
              : _ink,
          fontSize: bold ? 21 : 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ],
  );
}

String _won(int value) =>
    value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    ) +
    '\uC6D0';
