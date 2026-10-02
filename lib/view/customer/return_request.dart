import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/refund_request_service.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class ReturnRequestPage extends StatefulWidget {
  const ReturnRequestPage({super.key, required this.order});
  final CustomerOrder order;

  @override
  State<ReturnRequestPage> createState() => _ReturnRequestPageState();
}

class _ReturnRequestPageState extends State<ReturnRequestPage> {
  static const _reasons = [
    '\uC0AC\uC774\uC988\uAC00 \uB9DE\uC9C0 \uC54A\uC544\uC694',
    '\uC0C1\uD488\uC774 \uC0C1\uC138 \uC815\uBCF4\uC640 \uB2EC\uB77C\uC694',
    '\uC0C1\uD488 \uD558\uC790',
    '\uB2E8\uC21C \uBCC0\uC2EC',
  ];
  final _service = RefundRequestService();
  final _detailController = TextEditingController();
  late int _quantity;
  String _reason = _reasons.first;
  bool _agreed = true;
  bool _submitting = false;

  CustomerShoe? get _shoe => widget.order.shoe;
  int get _maximum => int.tryParse(widget.order.quantity) ?? 1;
  int get _unitPrice => int.tryParse(_shoe?.price ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _quantity = 1;
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreed || _shoe == null) return;
    setState(() => _submitting = true);
    try {
      final result = await _service.submit(
        orderId: widget.order.id,
        shoeId: _shoe!.id,
        quantity: _quantity,
        reason: _reason,
        detailReason: _detailController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('\uBC18\uD488 \uC2E0\uCCAD \uC644\uB8CC'),
          content: Text(
            '\uC2E0\uCCAD\uBC88\uD638 ${result.id}\uB85C \uBC18\uD488\uC744 \uC811\uC218\uD588\uC2B5\uB2C8\uB2E4.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('\uD655\uC778'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on RefundRequestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
      ),
      title: const Text(
        '\uBC18\uD488 \uC2E0\uCCAD',
        style: TextStyle(
          color: _ink,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text(
            '\uB3C4\uC6C0\uB9D0',
            style: TextStyle(color: _muted),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      children: [
        const _Steps(),
        const SizedBox(height: 25),
        const _Heading('\uBC18\uD488 \uC0C1\uD488'),
        const SizedBox(height: 12),
        _ProductCard(order: widget.order),
        const SizedBox(height: 25),
        const _Heading('\uBC18\uD488 \uC815\uBCF4'),
        const SizedBox(height: 12),
        _FormCard(
          quantity: _quantity,
          maximum: _maximum,
          reason: _reason,
          detailController: _detailController,
          onMinus: _quantity > 1 ? () => setState(() => _quantity--) : null,
          onPlus: _quantity < _maximum
              ? () => setState(() => _quantity++)
              : null,
          onReason: (value) => setState(() => _reason = value),
        ),
        const SizedBox(height: 25),
        const _Heading('\uBC29\uBB38 \uB300\uB9AC\uC810'),
        const SizedBox(height: 12),
        _StoreCard(store: widget.order.store),
        const SizedBox(height: 25),
        const _Heading('\uC608\uC0C1 \uD658\uBD88\uAE08\uC561'),
        const SizedBox(height: 12),
        _AmountCard(amount: _unitPrice * _quantity),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                '\uC0C1\uD488\uC774 \uBBF8\uC0AC\uC6A9 \uC0C1\uD0DC\uC774\uBA70 \uAD6C\uC131\uD488\uC744 \uBCF4\uC720\uD558\uACE0 \uC788\uC2B5\uB2C8\uB2E4.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              activeColor: _blue,
            ),
            FilledButton(
              onPressed: _submitting || !_agreed || _shoe == null
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(57),
                backgroundColor: _blue,
              ),
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('\uBC18\uD488 \uC2E0\uCCAD\uD558\uAE30'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _ink,
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        _Step(number: '1', label: '\uC0C1\uD488 \uC120\uD0DD'),
        Expanded(child: Divider(color: _blue, thickness: 2)),
        _Step(number: '2', label: '\uC0AC\uC720 \uC785\uB825'),
        Expanded(child: Divider(color: Color(0xFFDCE5F1), thickness: 2)),
        _Step(number: '3', label: '\uD655\uC778', active: false),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label, this.active = true});
  final String number, label;
  final bool active;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 13,
        backgroundColor: active ? _blue : const Color(0xFFE2E9F3),
        child: Text(
          number,
          style: TextStyle(
            color: active ? Colors.white : _muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          color: active ? _blue : _muted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${order.id} \u00B7 \uC218\uB839 \uC644\uB8CC',
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        const Divider(height: 22),
        Row(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFD9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.directions_walk_rounded,
                color: Color(0xFFFFB263),
                size: 58,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\uBC18\uD488 \uAC00\uB2A5',
                    style: TextStyle(
                      color: Color(0xFF28A86C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    order.shoe?.name ?? '\uC0C1\uD488',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\uC218\uB7C9 ${order.quantity}\uAC1C',
                    style: const TextStyle(color: _muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _won(int.tryParse(order.shoe?.price ?? '') ?? 0),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.quantity,
    required this.maximum,
    required this.reason,
    required this.detailController,
    required this.onMinus,
    required this.onPlus,
    required this.onReason,
  });
  final int quantity, maximum;
  final String reason;
  final TextEditingController detailController;
  final VoidCallback? onMinus, onPlus;
  final ValueChanged<String> onReason;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '\uBC18\uD488 \uC218\uB7C9',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onMinus,
              child: const Icon(Icons.remove, size: 17),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton(
              onPressed: onPlus,
              child: const Icon(Icons.add, size: 17),
            ),
          ],
        ),
        const Divider(height: 28),
        const Text(
          '\uBC18\uD488 \uC0AC\uC720',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          initialValue: reason,
          items: _ReturnRequestPageState._reasons
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onReason(value);
          },
          decoration: _inputDecoration(),
        ),
        const SizedBox(height: 17),
        const Text(
          '\uC0C1\uC138 \uC0AC\uC720 (\uC120\uD0DD)',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: detailController,
          maxLines: 2,
          decoration: _inputDecoration(
            hint:
                '\uC0C1\uC138 \uC0AC\uD56D\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694.',
          ),
        ),
      ],
    ),
  );
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final CustomerStore? store;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE5F1)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.location_on_outlined, color: _blue, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store?.name ?? '\uC218\uB839 \uB300\uB9AC\uC810',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${store?.district ?? ''} \uB300\uB9AC\uC810\uC5D0 \uC0C1\uD488\uC744 \uBC29\uBB38 \uBC18\uD488\uD574 \uC8FC\uC138\uC694.',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('\uBCC0\uACBD')),
      ],
    ),
  );
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount});
  final int amount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\uC6D0\uACB0\uC81C \uC218\uB2E8\uC73C\uB85C \uD658\uBD88',
              style: TextStyle(color: _muted),
            ),
            SizedBox(height: 5),
            Text(
              '\uB300\uB9AC\uC810 \uBC29\uBB38 \uBC18\uD488 \uC218\uC218\uB8CC \uC5C6\uC74C',
              style: TextStyle(color: Color(0xFF28A86C), fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        Text(
          _won(amount),
          style: const TextStyle(
            color: _blue,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

InputDecoration _inputDecoration({String? hint}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFF9BAAC0)),
  filled: true,
  fillColor: const Color(0xFFF9FBFE),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFDCE5F1)),
  ),
);
String _won(int value) =>
    value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    ) +
    '\uC6D0';
