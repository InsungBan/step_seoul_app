import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class OrderHistory extends StatelessWidget {
  const OrderHistory({super.key, required this.orders});
  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      const _OrderBrandHeader(),
      const SizedBox(height: 28),
      Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\uC8FC\uBB38\uB0B4\uC5ED',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  '\uC8FC\uBB38 \uC0C1\uD0DC\uC640 \uB300\uB9AC\uC810 \uC218\uB839 \uC815\uBCF4\uB97C \uD655\uC778\uD558\uC138\uC694.',
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            label: const Text('\uCD5C\uADFC 3\uAC1C\uC6D4'),
          ),
        ],
      ),
      const SizedBox(height: 21),
      const _OrderSearch(),
      const SizedBox(height: 18),
      _OrderFilters(total: orders.length),
      const SizedBox(height: 20),
      if (orders.isEmpty)
        const _NoOrders()
      else
        ...orders.reversed.map((order) => _OrderCard(order: order)),
    ],
  );
}

class _OrderBrandHeader extends StatelessWidget {
  const _OrderBrandHeader();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _blue,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.show_chart_rounded, color: Colors.white),
      ),
      const SizedBox(width: 10),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP SEOUL',
            style: TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'ONLINE PICKUP',
            style: TextStyle(
              color: Color(0xFF9AAAC0),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      const Spacer(),
      const CircleAvatar(
        radius: 21,
        backgroundColor: Colors.white,
        child: Icon(Icons.notifications_none_rounded, color: _muted),
      ),
      const SizedBox(width: 9),
      const CartNavigationButton(),
    ],
  );
}

class _OrderSearch extends StatelessWidget {
  const _OrderSearch();
  @override
  Widget build(BuildContext context) => TextField(
    readOnly: true,
    decoration: InputDecoration(
      hintText:
          '\uC8FC\uBB38\uBC88\uD638 \uB610\uB294 \uC0C1\uD488\uBA85 \uAC80\uC0C9',
      hintStyle: const TextStyle(color: Color(0xFF9BAAC0)),
      prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 30),
      filled: true,
      fillColor: Colors.white,
      border: _border(),
      enabledBorder: _border(),
    ),
  );
  OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(17),
    borderSide: const BorderSide(color: Color(0xFFDCE5F1), width: 1.3),
  );
}

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0F9),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '\uC804\uCCB4 ' + total.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const Expanded(
          child: Text(
            '\uC9C4\uD589\uC911',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ),
        const Expanded(
          child: Text(
            '\uC218\uB839\uC644\uB8CC',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ),
      ],
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) {
    final storeName =
        order.store?.name ?? '\uB300\uB9AC\uC810 \uBC30\uC815 \uC911';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [BoxShadow(color: Color(0x0A1F3C70), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ORDER-' + order.id,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9FAF1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  order.status,
                  style: const TextStyle(
                    color: Color(0xFF239C62),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 23, color: Color(0xFFE6EDF6)),
          Row(
            children: [
              Container(
                width: 88,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: _blue,
                  size: 43,
                ),
              ),
              const SizedBox(width: 17),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.shoe?.name ??
                          '\uC0C1\uD488 \uC815\uBCF4 \uC5C6\uC74C',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '\uC218\uB7C9 ' + order.quantity + '\uAC1C',
                      style: const TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (order.shoe?.price ?? '0') + '\uC6D0',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => Get.toNamed(
                  AppRoutes.orderDetail,
                  arguments: order.id,
                ),
                child: const Text('\uC0C1\uC138\uBCF4\uAE30'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _ProgressLine(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    storeName + ' \u00B7 \uC218\uB839 \uAC00\uB2A5',
                    style: const TextStyle(
                      color: Color(0xFF3B5F98),
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.qr_code_rounded),
                label: const Text('QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: order.shoe == null
                  ? null
                  : () => Get.toNamed(
                      AppRoutes.returnRequest,
                      arguments: order,
                    ),
              icon: const Icon(Icons.keyboard_return_rounded, size: 19),
              label: const Text('\uBC18\uD488 \uC2E0\uCCAD'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF08B20),
                side: const BorderSide(color: Color(0xFFFFD9AE)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: Color(0xFF67A8FF), thickness: 3)),
      Icon(Icons.radio_button_checked, color: _blue, size: 19),
      Expanded(child: Divider(color: Color(0xFFD5DFEF), thickness: 3)),
    ],
  );
}

class _NoOrders extends StatelessWidget {
  const _NoOrders();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(35),
    child: Center(
      child: Text(
        '\uC8FC\uBB38\uB0B4\uC5ED\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
        style: TextStyle(color: _muted),
      ),
    ),
  );
}
