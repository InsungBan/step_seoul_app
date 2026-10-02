import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/profile_edit.dart';
import 'package:step_seoul_app/view/common/session_logout_button.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class MyPage extends StatelessWidget {
  const MyPage({super.key, required this.userId, required this.orders});
  final String userId;
  final List<CustomerOrder> orders;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      const _MyBrandHeader(),
      const SizedBox(height: 29),
      const Text(
        'MY',
        style: TextStyle(
          color: _ink,
          fontSize: 27,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        '\uB0B4 \uC815\uBCF4\uC640 \uC1FC\uD551 \uB0B4\uC5ED\uC744 \uAD00\uB9AC\uD558\uC138\uC694.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 21),
      _ProfileCard(userId: userId, orders: orders),
      const SizedBox(height: 17),
      if (orders.isNotEmpty) _PickupMiniCard(order: orders.last),
      const SizedBox(height: 23),
      const Text(
        '\uC1FC\uD551 \uAD00\uB9AC',
        style: TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      _MenuGroup(
        items: [
          _MenuItem(
            Icons.receipt_long_outlined,
            '\uC804\uCCB4 \uC8FC\uBB38\uB0B4\uC5ED',
            orders.length.toString() + '\uAC74',
            _blue,
          ),
          const _MenuItem(
            Icons.assignment_return_outlined,
            '\uBC18\uD488\u00B7\uD658\uBD88 \uB0B4\uC5ED',
            '0\uAC74',
            Color(0xFFFFA119),
          ),
          const _MenuItem(
            Icons.location_on_outlined,
            '\uCD5C\uADFC \uC218\uB839 \uB300\uB9AC\uC810',
            '\uB300\uB9AC\uC810',
            Color(0xFF19B979),
          ),
        ],
      ),
      const SizedBox(height: 23),
      const Text(
        '\uACC4\uC815 \uBC0F \uC548\uB0B4',
        style: TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 12),
      const _MenuGroup(
        items: [
          _MenuItem(
            Icons.support_agent_rounded,
            '\uACE0\uAC1D\uC13C\uD130',
            '1588-2026',
            _blue,
          ),
        ],
      ),
      const SizedBox(height: 16),
      const SessionLogoutButton(labeled: true),
    ],
  );
}

class _MyBrandHeader extends StatelessWidget {
  const _MyBrandHeader();
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.userId, required this.orders});
  final String userId;
  final List<CustomerOrder> orders;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF142A65), Color(0xFF2859CA)],
      ),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 31,
              backgroundColor: Color(0x335E93E6),
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 43,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '\uC548\uB155\uD558\uC138\uC694',
                    style: TextStyle(color: Color(0xFFBDD2FF)),
                  ),
                  Text(
                    userId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    userId + ' \u00B7 STEP SEOUL',
                    style: const TextStyle(
                      color: Color(0xFFC7D8FC),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileEditPage()),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('\uC815\uBCF4 \uC218\uC815'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ],
        ),
        const Divider(color: Color(0x447FA5F7), height: 25),
        Row(
          children: [
            _Stat(
              value: orders.length.toString(),
              label: '\uCD1D \uC8FC\uBB38',
            ),
            _Stat(
              value: orders.length.toString(),
              label: '\uC9C4\uD589 \uC911',
            ),
            const _Stat(value: '0', label: '\uBC18\uD488\u00B7\uD658\uBD88'),
          ],
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFBBD0F7), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PickupMiniCard extends StatelessWidget {
  const _PickupMiniCard({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: Color(0xFFEAF3FF),
          child: Icon(Icons.location_on_outlined, color: _blue, size: 31),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.status,
                style: const TextStyle(
                  color: Color(0xFF2DA672),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                (order.store?.name ?? '\uB300\uB9AC\uC810') +
                    '\uC5D0\uC11C \uC218\uB839 \uAC00\uB2A5',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                order.id + ' \u00B7 ' + (order.shoe?.name ?? ''),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
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
  );
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, this.trailing, this.color);
  final IconData icon;
  final String label;
  final String trailing;
  final Color color;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});
  final List<_MenuItem> items;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: item.color.withValues(alpha: .10),
                child: Icon(item.icon, color: item.color, size: 21),
              ),
              title: Text(
                item.label,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.trailing, style: const TextStyle(color: _muted)),
                  const Icon(Icons.chevron_right_rounded, color: _muted),
                ],
              ),
            ),
            if (index != items.length - 1)
              const Divider(height: 1, indent: 65, color: Color(0xFFE9EEF5)),
          ],
        );
      }),
    ),
  );
}
