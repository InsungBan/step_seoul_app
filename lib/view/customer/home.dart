import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/branch_home.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/customer_bottom_tabs.dart';
import 'package:step_seoul_app/view/customer/my_page.dart';
import 'package:step_seoul_app/view/customer/order_history.dart';
import 'package:step_seoul_app/view/customer/product_detail.dart';
import 'package:step_seoul_app/view/customer/shoe_image.dart';
import 'package:step_seoul_app/view/customer/product_list.dart';
import 'package:step_seoul_app/view/common/session_logout_button.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final _service = CustomerHomeService();
  late Future<CustomerHomeData> _homeFuture;
  int _selectedTab = 0;
  String _category = '\uC804\uCCB4';
  String _query = '';
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab < 0
        ? 0
        : widget.initialTab > 3
        ? 3
        : widget.initialTab;
    _reload();
  }

  void _reload() => _homeFuture = _service.loadHome(
    query: _query,
    category: _category == '\uC804\uCCB4' ? null : _category,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    body: SafeArea(
      child: FutureBuilder<CustomerHomeData>(
        future: _homeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: _blue));
          }
          if (snapshot.hasError) {
            return _LoadError(onRetry: () => setState(_reload));
          }
          final data = snapshot.requireData;
          CustomerStore? selectedStore = data.selectedStore;
          for (final store in data.stores) {
            if (store.id == _selectedStoreId) selectedStore = store;
          }
          return IndexedStack(
            index: _selectedTab,
            children: [
              _HomeTab(
                data: data,
                selectedStore: selectedStore,
                selectedCategory: _category,
                onCategoryChanged: (value) => setState(() {
                  _category = value;
                  _reload();
                }),
                onSearch: (value) => setState(() {
                  _query = value;
                  _reload();
                }),
                onRefresh: () => setState(_reload),
              ),
              BranchHome(
                stores: data.stores,
                selectedStoreId: selectedStore?.id,
                onStoreSelected: (store) =>
                    setState(() => _selectedStoreId = store.id),
              ),
              OrderHistory(orders: data.orders),
              MyPage(userId: data.userId, orders: data.orders),
            ],
          );
        },
      ),
    ),
    bottomNavigationBar: CustomerBottomTabs(
      selectedIndex: _selectedTab,
      onSelected: (index) => setState(() => _selectedTab = index),
    ),
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.data,
    required this.selectedStore,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSearch,
    required this.onRefresh,
  });
  final CustomerHomeData data;
  final CustomerStore? selectedStore;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    color: _blue,
    onRefresh: () async => onRefresh(),
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      children: [
        _TopBar(cartCount: data.cartCount),
        const SizedBox(height: 25),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: _blue, size: 28),
            const SizedBox(width: 6),
            Text(
              selectedStore == null
                  ? '\uD604\uC7AC \uC9C0\uC5ED\uC744 \uC124\uC815\uD574 \uC8FC\uC138\uC694'
                  : '\uD604\uC7AC \uC9C0\uC5ED \u00B7 ' +
                        selectedStore!.district,
              style: const TextStyle(color: _muted, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const Text(
          '\uACE0\uAC1D\uB2D8,\n\uC5B4\uB5A4 \uC2E0\uBC1C\uC744 \uCC3E\uC73C\uC138\uC694?',
          style: TextStyle(
            color: _ink,
            fontSize: 28,
            height: 1.23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 23),
        if (data.orders.isEmpty)
          const _EmptyOrderCard()
        else
          _PickupOrderCard(order: data.orders.last),
        const SizedBox(height: 21),
        _SearchField(onSubmitted: onSearch),
        const SizedBox(height: 21),
        Row(
          children: [
            const Text(
              '\uCE74\uD14C\uACE0\uB9AC',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductList(shoes: data.shoes),
                ),
              ),
              child: const Text(
                '\uC804\uCCB4\uBCF4\uAE30',
                style: TextStyle(color: _muted),
              ),
            ),
          ],
        ),
        _CategoryChips(
          selected: selectedCategory,
          onSelected: onCategoryChanged,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              '\uCD94\uCC9C \uC2E0\uBC1C',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductList(shoes: data.shoes),
                ),
              ),
              child: const Text(
                '\uB354\uBCF4\uAE30',
                style: TextStyle(color: _muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (data.shoes.isEmpty)
          const _EmptyPanel(
            icon: Icons.inventory_2_outlined,
            text:
                '\uAC80\uC0C9 \uC870\uAC74\uC5D0 \uB9DE\uB294 \uC2E0\uBC1C\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Two cards and one gap exactly fit in the visible area.
              final cardWidth = (constraints.maxWidth - 15) / 2;
              return SizedBox(
                height: 284,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.shoes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 15),
                  itemBuilder: (context, index) =>
                      _ProductCard(shoe: data.shoes[index], width: cardWidth),
                ),
              );
            },
          ),
      ],
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.cartCount});
  final int cartCount;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        height: 38,
        width: 38,
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
      const _RoundIcon(icon: Icons.notifications_none_rounded, badge: 0),
      const SizedBox(width: 9),
      _RoundIcon(
        icon: Icons.shopping_bag_outlined,
        badge: cartCount,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CartPage())),
      ),
    ],
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.badge, this.onTap});
  final IconData icon;
  final int badge;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFDCE5F1)),
          ),
          child: Icon(icon, color: const Color(0xFF536680)),
        ),
        if (badge > 0)
          Positioned(
            right: -3,
            top: -4,
            child: CircleAvatar(
              radius: 9,
              backgroundColor: const Color(0xFFFF4D60),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PickupOrderCard extends StatelessWidget {
  const _PickupOrderCard({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) {
    final shoeName =
        order.shoe?.name ?? '\uC0C1\uD488 \uC815\uBCF4 \uC5C6\uC74C';
    final storeName = order.store?.name.isNotEmpty == true
        ? order.store!.name
        : '\uB300\uB9AC\uC810 \uBC30\uC815 \uC911';
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11255B), Color(0xFF244FAF)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const _StatusDot(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x337FA5F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  order.id,
                  style: const TextStyle(
                    color: Color(0xFFC9D9FF),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E5997),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(9),
                  child: _MiniShoe(color: Color(0xFFDDEBFF)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoeName + ' \u00B7 ' + order.quantity,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      storeName + '\uC5D0\uC11C \uC218\uB839 \uAC00\uB2A5',
                      style: const TextStyle(
                        color: Color(0xFFC7D8FC),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '\uC218\uB839 QR \uBCF4\uAE30',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const _OrderProgress(),
        ],
      ),
    );
  }
}

class _EmptyOrderCard extends StatelessWidget {
  const _EmptyOrderCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFECF3FF),
      borderRadius: BorderRadius.circular(24),
    ),
    child: const Row(
      children: [
        Icon(Icons.local_shipping_outlined, color: _blue, size: 34),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            '\uC9C4\uD589 \uC911\uC778 \uC218\uB839 \uC8FC\uBB38\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
            style: TextStyle(
              color: Color(0xFF355486),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();
  @override
  Widget build(BuildContext context) =>
      const CircleAvatar(radius: 6, backgroundColor: Color(0xFF28D67B));
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _ProgressStep(label: '\uACB0\uC81C', complete: true),
      _ProgressLine(),
      _ProgressStep(label: '\uBC30\uC1A1', complete: true),
      _ProgressLine(),
      _ProgressStep(label: '\uB3C4\uCC29', active: true),
      _ProgressLine(),
      _ProgressStep(label: '\uC218\uB839'),
    ],
  );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();
  @override
  Widget build(BuildContext context) =>
      const Expanded(child: Divider(color: Color(0xFF6EA3F3), thickness: 2));
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
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
      Container(
        width: active ? 20 : 16,
        height: active ? 20 : 16,
        decoration: BoxDecoration(
          color: complete || active
              ? const Color(0xFF68AEFF)
              : const Color(0xFF7595D2),
          shape: BoxShape.circle,
          border: active ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: complete
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFFBBD0F7),
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ],
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onSubmitted});
  final ValueChanged<String> onSubmitted;
  @override
  Widget build(BuildContext context) => TextField(
    textInputAction: TextInputAction.search,
    onSubmitted: onSubmitted,
    decoration: InputDecoration(
      hintText: '\uC0C1\uD488\uBA85 \uB610\uB294 \uC0C1\uD488 ID \uAC80\uC0C9',
      hintStyle: const TextStyle(color: Color(0xFF9BAAC0)),
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Color(0xFF687C99),
        size: 30,
      ),
      suffixIcon: const Icon(Icons.grid_view_rounded, color: _blue),
      filled: true,
      fillColor: Colors.white,
      border: _searchBorder(),
      enabledBorder: _searchBorder(),
    ),
  );
  OutlineInputBorder _searchBorder() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(17),
    borderSide: const BorderSide(color: Color(0xFFDCE5F1), width: 1.3),
  );
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const values = [
    '\uC804\uCCB4',
    '\uB7EC\uB2DD',
    '\uC2A4\uB2C8\uCEE4\uC988',
    '\uAD6C\uB450',
    '\uD0A4\uC988',
  ];
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (context, index) {
        final value = values[index];
        final active = value == selected;
        return ChoiceChip(
          label: Text(value),
          selected: active,
          onSelected: (_) => onSelected(value),
          selectedColor: _blue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: active ? Colors.white : const Color(0xFF536680),
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: active ? _blue : const Color(0xFFDCE5F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        );
      },
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.shoe, required this.width});
  final CustomerShoe shoe;
  final double width;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProductDetail(shoe: shoe))),
    child: Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1F3C70),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 157,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ShoeImage(
                    imageUrl: shoe.imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Positioned(
                right: 8,
                top: 8,
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: Color(0xFF71839E),
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            shoe.name,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            'ID \u00B7 ' + shoe.id,
            style: const TextStyle(color: _muted, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Text(
                shoe.price + '\uC6D0',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _StockTag(stock: shoe.stock),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StockTag extends StatelessWidget {
  const _StockTag({required this.stock});
  final int stock;
  @override
  Widget build(BuildContext context) {
    final available = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F9F1) : const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        available ? '\uC7AC\uACE0' : '\uD488\uC808',
        style: TextStyle(
          color: available ? const Color(0xFF1D9B63) : const Color(0xFFDD4961),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StoreTab extends StatelessWidget {
  const _StoreTab({required this.stores});
  final List<CustomerStore> stores;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        '\uB300\uB9AC\uC810',
        style: TextStyle(
          color: _ink,
          fontSize: 27,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        '\uC218\uB839\uD560 \uAC00\uAE4C\uC6B4 \uB300\uB9AC\uC810\uC744 \uC120\uD0DD\uD558\uC138\uC694.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 22),
      if (stores.isEmpty)
        const _EmptyPanel(
          icon: Icons.storefront_outlined,
          text:
              '\uB4F1\uB85D\uB41C \uB300\uB9AC\uC810\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
        )
      else
        ...stores.map((store) => _StoreTile(store: store)),
    ],
  );
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E9F3)),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 23,
          backgroundColor: Color(0xFFE7F0FF),
          child: Icon(Icons.storefront_outlined, color: _blue),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                store.name.isEmpty ? store.id : store.name,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                store.district + '  ' + store.phone,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: _muted),
      ],
    ),
  );
}

class _OrderTab extends StatelessWidget {
  const _OrderTab({required this.orders});
  final List<CustomerOrder> orders;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        '\uC8FC\uBB38\uB0B4\uC5ED',
        style: TextStyle(
          color: _ink,
          fontSize: 27,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 22),
      if (orders.isEmpty)
        const _EmptyPanel(
          icon: Icons.receipt_long_outlined,
          text: '\uC8FC\uBB38\uB0B4\uC5ED\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
        )
      else
        ...orders.map((order) => _OrderTile(order: order)),
    ],
  );
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.status,
          style: const TextStyle(color: _blue, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          order.shoe?.name ?? '\uC0C1\uD488 \uC815\uBCF4 \uC5C6\uC74C',
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ORDER ' +
              order.id +
              ' \u00B7 ' +
              (order.store?.name ?? '\uB300\uB9AC\uC810 \uBC30\uC815 \uC911'),
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon, color: _blue, size: 40),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(color: _muted)),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, color: _blue, size: 55),
        const SizedBox(height: 14),
        const Text(
          '\uD648 \uC815\uBCF4\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRetry,
          child: const Text('\uB2E4\uC2DC \uC2DC\uB3C4'),
        ),
      ],
    ),
  );
}

class _MiniShoe extends StatelessWidget {
  const _MiniShoe({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ShoePainter(color), child: const SizedBox.expand());
}

class _ShoePainter extends CustomPainter {
  const _ShoePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final shoe = Paint()..color = color;
    final accent = Paint()
      ..color = const Color(0xFF9EC9FF)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .032;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .69)
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
        size.height * .69,
      )
      ..close();
    canvas.drawPath(path, shoe);
    canvas.drawLine(
      Offset(size.width * .37, size.height * .49),
      Offset(size.width * .65, size.height * .64),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * .27, size.height * .68),
      Offset(size.width * .75, size.height * .68),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * .17, size.height * .84),
      Offset(size.width * .82, size.height * .84),
      accent,
    );
  }

  @override
  bool shouldRepaint(covariant _ShoePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MyTab extends StatelessWidget {
  const _MyTab();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_outline_rounded, color: _blue, size: 62),
        SizedBox(height: 17),
        Text(
          'MY',
          style: TextStyle(
            color: _ink,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        SessionLogoutButton(),
      ],
    ),
  );
}
