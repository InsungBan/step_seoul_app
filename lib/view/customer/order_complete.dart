import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/services/checkout_service.dart';
import 'package:step_seoul_app/view/customer/order_detail.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class OrderCompletePage extends StatelessWidget {
  const OrderCompletePage({super.key, required this.receipt});
  final CheckoutReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final item = receipt.items.isEmpty ? null : receipt.items.first;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FD),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '\uC8FC\uBB38 \uC644\uB8CC',
          style: TextStyle(
            color: _ink,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.offAllNamed('/customer/home', arguments: 0),
            icon: const Icon(Icons.close_rounded, color: _muted),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDCE5F1)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 9, 20, 20),
            children: [
              const _CompletionSteps(),
              const SizedBox(height: 21),
              const _SuccessBanner(),
              const SizedBox(height: 19),
              _OrderNumberCard(receipt: receipt),
              const SizedBox(height: 23),
              const Text(
                '\uC8FC\uBB38 \uC694\uC57D',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _OrderSummary(item: item, receipt: receipt),
              const SizedBox(height: 24),
              const Text(
                '\uB2E4\uC74C \uC548\uB0B4',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const _NextSteps(),
              const SizedBox(height: 19),
              const _ReceiptNotice(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    Get.offAllNamed('/customer/home', arguments: 0),
                icon: const Icon(Icons.home_outlined),
                label: const Text('\uD648\uC73C\uB85C'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(135, 57),
                  foregroundColor: _ink,
                  side: const BorderSide(color: Color(0xFFDCE5F1)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailPage(orderId: receipt.orderId),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('\uC8FC\uBB38 \uC0C1\uC138 \uBCF4\uAE30'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(57),
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionSteps extends StatelessWidget {
  const _CompletionSteps();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _Step(label: '\uC7A5\uBC14\uAD6C\uB2C8'),
      Expanded(child: Divider(color: _blue, thickness: 2)),
      _Step(label: '\uC8FC\uBB38 \u00B7 \uACB0\uC81C'),
      Expanded(child: Divider(color: _blue, thickness: 2)),
      _Step(label: '\uC644\uB8CC', active: true),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.label, this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 15,
        backgroundColor: _blue,
        child: const Icon(Icons.check, color: Colors.white, size: 18),
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

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 27),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF112A68), Color(0xFF2869EA)],
      ),
      borderRadius: BorderRadius.circular(25),
    ),
    child: const Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Color(0x556D98E9),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.check_rounded, color: _blue, size: 39),
          ),
        ),
        SizedBox(height: 13),
        Text(
          '\uC8FC\uBB38\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          '\uC0C1\uD488\uC774 \uB300\uB9AC\uC810\uC5D0 \uB3C4\uCC29\uD558\uBA74\n\uC54C\uB9BC\uACFC \uC218\uB839 QR\uC744 \uBCF4\uB0B4\uB4DC\uB9B4\uAC8C\uC694.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFD4E2FF)),
        ),
        SizedBox(height: 11),
        _PaidBadge(),
      ],
    ),
  );
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x337FA5F7),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: Color(0xFF28D67B), size: 14),
        SizedBox(width: 5),
        Text(
          '\uACB0\uC81C \uC644\uB8CC',
          style: TextStyle(color: Colors.white, fontSize: 11),
        ),
      ],
    ),
  );
}

class _OrderNumberCard extends StatelessWidget {
  const _OrderNumberCard({required this.receipt});
  final CheckoutReceipt receipt;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\uC8FC\uBB38\uBC88\uD638',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Text(
                receipt.orderId,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${receipt.paidAt.replaceFirst('T', ' ')} \u00B7 \uC2E0\uC6A9\uCE74\uB4DC \uACB0\uC81C',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\uC8FC\uBB38\uBC88\uD638\uB97C \uBCF5\uC0AC\uD588\uC2B5\uB2C8\uB2E4.',
              ),
            ),
          ),
          icon: const Icon(Icons.copy_outlined, size: 18),
          label: const Text('\uBCF5\uC0AC'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFEAF3FF),
            foregroundColor: _blue,
          ),
        ),
      ],
    ),
  );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.item, required this.receipt});
  final CheckoutReceiptItem? item;
  final CheckoutReceipt receipt;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 95,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFD5E8FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
                size: 49,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\uC624\uB298 \uC8FC\uBB38',
                    style: TextStyle(
                      color: Color(0xFF28A86C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item?.name ?? '\uC0C1\uD488',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item?.shoeId ?? ''} \u00B7 ${item?.quantity ?? 0}\uAC1C',
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _won(receipt.total),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (receipt.items.length > 1)
              Text(
                '+${receipt.items.length - 1}',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const Divider(height: 25, color: Color(0xFFDCE5F1)),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: _blue, size: 35),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\uC218\uB839 \uB300\uB9AC\uC810',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                  Text(
                    receipt.store.name,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '\uC624\uB298 10:00-20:00',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NextSteps extends StatelessWidget {
  const _NextSteps();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: const Column(
      children: [
        Row(
          children: [
            _NextStep(
              icon: Icons.check_rounded,
              label: '\uC8FC\uBB38 \uD655\uC778',
              active: true,
            ),
            Expanded(child: Divider(color: Color(0xFF6EA3F3), thickness: 2)),
            _NextStep(
              icon: Icons.local_shipping_outlined,
              label: '\uB300\uB9AC\uC810 \uBC30\uC1A1',
            ),
            Expanded(child: Divider(color: Color(0xFFDCE5F1), thickness: 2)),
            _NextStep(
              icon: Icons.notifications_none_rounded,
              label: '\uB3C4\uCC29 \uC54C\uB9BC',
            ),
          ],
        ),
        SizedBox(height: 18),
        Text(
          '\uB3C4\uCC29 \uD6C4 \uC5F0\uB3D9\uB41C \uC218\uB839 QR\uC744 \uC9C1\uC6D0\uC5D0\uAC8C \uBCF4\uC5EC\uC8FC\uC138\uC694.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.label,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 19,
        backgroundColor: active ? _blue : const Color(0xFFF0F4FA),
        child: Icon(icon, color: active ? Colors.white : _muted),
      ),
      const SizedBox(height: 7),
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

class _ReceiptNotice extends StatelessWidget {
  const _ReceiptNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      border: Border.all(color: const Color(0xFFD5E6FF)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Icon(Icons.check_circle_rounded, color: _blue),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\uACB0\uC81C \uC601\uC218\uC99D\uC744 \uB4F1\uB85D\uB41C \uC5F0\uB77D\uCC98\uB85C \uBCF4\uB0C8\uC5B4\uC694.',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 3),
              Text(
                '\uC8FC\uBB38 \uC0C1\uD0DC\uB294 \uC8FC\uBB38\uB0B4\uC5ED\uC5D0\uC11C \uC5B8\uC81C\uB4E0 \uD655\uC778\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _won(int value) =>
    value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    ) +
    '\uC6D0';
