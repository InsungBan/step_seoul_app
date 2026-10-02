import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/order_detail_service.dart';
import 'package:step_seoul_app/view/customer/branch_detail.dart';
import 'package:step_seoul_app/view/customer/product_detail.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _service = OrderDetailService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.load(widget.orderId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '\uC8FC\uBB38 \uC0C1\uC138',
        style: TextStyle(
          color: _ink,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDCE5F1)),
          ),
        ),
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _blue));
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              '\uC8FC\uBB38\uC744 \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
              style: TextStyle(color: _muted),
            ),
          );
        }
        final data = snapshot.requireData;
        final items = (data['items'] as List? ?? [])
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
        final store = data['store'] is Map
            ? Map<String, dynamic>.from(data['store'] as Map)
            : <String, dynamic>{};
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            _StatusCard(
              status: data['status']?.toString() ?? '',
              id: widget.orderId,
            ),
            const SizedBox(height: 25),
            const _SectionTitle('\uC8FC\uBB38 \uC0C1\uD488'),
            const SizedBox(height: 12),
            ...items.map((item) => _ItemCard(item: item)),
            const SizedBox(height: 25),
            const _SectionTitle('\uC218\uB839 \uC815\uBCF4'),
            const SizedBox(height: 12),
            _StoreCard(store: store),
            const SizedBox(height: 25),
            const _SectionTitle('\uACB0\uC81C \uC815\uBCF4'),
            const SizedBox(height: 12),
            _PaymentCard(total: _asInt(data['total'])),
          ],
        );
      },
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
        ),
        child: FilledButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\uC218\uB839 QR\uC740 \uB300\uB9AC\uC810 \uB3C4\uCC29 \uD6C4 \uBC1C\uAE09\uB429\uB2C8\uB2E4.',
              ),
            ),
          ),
          icon: const Icon(Icons.qr_code_rounded),
          label: const Text('\uC218\uB839 QR \uBCF4\uAE30'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(57),
            backgroundColor: _blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ),
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
      fontSize: 20,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status, required this.id});
  final String status, id;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF11255B), Color(0xFF244FAF)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: Color(0xFF28D67B), size: 14),
            const SizedBox(width: 8),
            Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                id,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC7D8FC), fontSize: 11),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        const Text(
          '\uB300\uB9AC\uC810\uC5D0\uC11C \uC0C1\uD488\uC744 \uC218\uB839\uD574 \uC8FC\uC138\uC694.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),
        const _Progress(),
      ],
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Icon(Icons.check_circle, color: Color(0xFF79B7FF), size: 19),
      Expanded(child: Divider(color: Color(0xFF79B7FF))),
      Icon(Icons.check_circle, color: Color(0xFF79B7FF), size: 19),
      Expanded(child: Divider(color: Color(0xFF79B7FF))),
      Icon(Icons.radio_button_checked, color: Colors.white, size: 21),
      Expanded(child: Divider(color: Color(0xFF6F92D0))),
      Icon(Icons.circle, color: Color(0xFF6F92D0), size: 17),
    ],
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final shoe = CustomerShoe(
      id: item['shoe_id']?.toString() ?? '',
      name: item['name']?.toString() ?? '',
      category: item['category']?.toString() ?? '',
      imageUrl: item['shoe_image_url']?.toString(),
      price: item['price']?.toString() ?? '0',
      stock: _asInt(item['stock']),
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 94,
            decoration: BoxDecoration(
              color: const Color(0xFFD5E8FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\uC218\uB839 \uAC00\uB2A5',
                  style: TextStyle(
                    color: Color(0xFF28A86C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  shoe.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${shoe.id} \u00B7 ${item['quantity'] ?? 1}\uAC1C',
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 7),
                Text(
                  _won(
                    _asInt(item['price']) *
                        _asInt(item['quantity'], fallback: 1),
                  ),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetail(shoe: shoe)),
            ),
            child: const Text('\uC0C1\uD488 \uBCF4\uAE30'),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final Map<String, dynamic> store;
  @override
  Widget build(BuildContext context) {
    final canOpen = store['store_id'] != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDCE5F1)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: _blue, size: 42),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['agency_name']?.toString() ??
                      store['name']?.toString() ??
                      '\uB300\uB9AC\uC810',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${store['district_name'] ?? store['district'] ?? ''} \u00B7 \uC601\uC5C5 \uC911',
                  style: const TextStyle(
                    color: Color(0xFF28A86C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: canOpen
                ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BranchDetailPage(
                        store: CustomerStore.fromJson(store),
                      ),
                    ),
                  )
                : null,
            child: const Text('\uC0C1\uC138\uBCF4\uAE30'),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.total});
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
        _row('\uC0C1\uD488 \uAE08\uC561', _won(total)),
        const SizedBox(height: 12),
        _row('\uD560\uC778 \uAE08\uC561', '0\uC6D0'),
        const SizedBox(height: 12),
        _row('\uB300\uB9AC\uC810 \uC218\uB839', '\uBB34\uB8CC', green: true),
        const Divider(height: 25, color: Color(0xFFDCE5F1)),
        _row('\uCD1D \uACB0\uC81C\uAE08\uC561', _won(total), bold: true),
      ],
    ),
  );
  Widget _row(
    String label,
    String value, {
    bool green = false,
    bool bold = false,
  }) => Row(
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

int _asInt(dynamic value, {int fallback = 0}) =>
    int.tryParse(value?.toString() ?? '') ?? fallback;
String _won(int value) =>
    value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)},',
    ) +
    '\uC6D0';
