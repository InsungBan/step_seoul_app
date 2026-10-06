import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class BranchHome extends StatefulWidget {
  const BranchHome({
    super.key,
    required this.stores,
    required this.selectedStoreId,
    required this.onStoreSelected,
  });
  final List<CustomerStore> stores;
  final String? selectedStoreId;
  final ValueChanged<CustomerStore> onStoreSelected;

  @override
  State<BranchHome> createState() => _BranchHomeState();
}

class _BranchHomeState extends State<BranchHome> {
  String _district = '\uC804\uCCB4 \uC9C0\uC5ED';
  String? _selectedStoreId;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.selectedStoreId;
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = position);
    } catch (_) {
      // Location permission is optional; Seoul centre is used as a fallback.
    }
  }

  ({double latitude, double longitude}) _coordinatesFor(CustomerStore store) {
    if (store.latitude != null && store.longitude != null) {
      return (latitude: store.latitude!, longitude: store.longitude!);
    }
    const districtCentres = {
      '\uAC15\uB0A8\uAD6C': (latitude: 37.4979, longitude: 127.0276),
      '\uC11C\uCD08\uAD6C': (latitude: 37.4837, longitude: 127.0324),
      '\uC1A1\uD30C\uAD6C': (latitude: 37.5145, longitude: 127.1059),
      '\uB9C8\uD3EC\uAD6C': (latitude: 37.5663, longitude: 126.9019),
    };
    return districtCentres[store.district] ??
        (latitude: 37.5665, longitude: 126.9780);
  }

  double _distanceInMeters(CustomerStore store) {
    final branch = _coordinatesFor(store);
    return Geolocator.distanceBetween(
      _currentPosition?.latitude ?? 37.5665,
      _currentPosition?.longitude ?? 126.9780,
      branch.latitude,
      branch.longitude,
    );
  }

  String _distanceLabel(CustomerStore store) {
    final meters = _distanceInMeters(store);
    return meters < 1000
        ? '${meters.round()}m'
        : '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final visibleStores =
        widget.stores
            .where(
              (store) =>
                  _district == '\uC804\uCCB4 \uC9C0\uC5ED' ||
                  store.district == _district,
            )
            .toList()
          ..sort(
            (first, second) =>
                _distanceInMeters(first).compareTo(_distanceInMeters(second)),
          );
    CustomerStore? selectedStore;
    for (final store in widget.stores) {
      if (store.id == _selectedStoreId) selectedStore = store;
    }
    final featured =
        selectedStore ??
        (visibleStores.isNotEmpty ? visibleStores.first : null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        const _BrandHeader(),
        const SizedBox(height: 28),
        const Text(
          '\uB300\uB9AC\uC810 \uCC3E\uAE30',
          style: TextStyle(
            color: _ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          '\uAC00\uAE4C\uC6B4 \uB300\uB9AC\uC810\uC744 \uD655\uC778\uD558\uACE0 \uC218\uB839 \uC9C0\uC810\uC73C\uB85C \uC120\uD0DD\uD558\uC138\uC694.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 21),
        const _SearchBox(
          hint:
              '\uC790\uCE58\uAD6C \uB610\uB294 \uB300\uB9AC\uC810\uBA85 \uAC80\uC0C9',
        ),
        const SizedBox(height: 17),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFDDEBFF),
                child: Icon(Icons.check_rounded, color: _blue),
              ),
              SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\uC11C\uC6B8 25\uAC1C \uC790\uCE58\uAD6C',
                    style: TextStyle(
                      color: Color(0xFF33568D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '\uC790\uCE58\uAD6C\uB9C8\uB2E4 \uB300\uB9AC\uC810 1\uAC1C \uC6B4\uC601',
                    style: TextStyle(color: Color(0xFF7187A9), fontSize: 11),
                  ),
                ],
              ),
              Spacer(),
              Icon(Icons.sort_rounded, color: _muted),
              SizedBox(width: 5),
              Text(
                '\uAC00\uAE4C\uC6B4 \uC21C',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DistrictChips(
          selected: _district,
          onSelected: (value) => setState(() => _district = value),
        ),
        const SizedBox(height: 21),
        if (featured == null)
          const _EmptyStores()
        else ...[
          _FeaturedBranch(
            store: featured,
            distance: _distanceLabel(featured),
            onTap: () => _openDetails(featured),
            onDirections: () => _openDirections(featured),
          ),
          const SizedBox(height: 23),
          Row(
            children: [
              const Text(
                '\uB2E4\uB978 \uB300\uB9AC\uC810',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openBranchList,
                child: const Text(
                  '\uC804\uCCB4\uBCF4\uAE30',
                  style: TextStyle(color: _muted),
                ),
              ),
            ],
          ),
          ...visibleStores
              .where((store) => store.id != featured.id)
              .map(
                (store) => _BranchTile(
                  store: store,
                  distance: _distanceLabel(store),
                  onTap: () => _openDetails(store),
                ),
              ),
        ],
      ],
    );
  }

  Future<void> _openBranchList() async {
    final store = await Get.toNamed(
      AppRoutes.branchList,
      arguments: BranchListArguments(
        stores: widget.stores,
        selectedStoreId: _selectedStoreId,
      ),
    );
    if (store is! CustomerStore || !mounted) return;
    setState(() {
      _selectedStoreId = store.id;
    });
    widget.onStoreSelected(store);
  }

  Future<void> _openDetails(CustomerStore store) async {
    final selected = await Get.toNamed(
      AppRoutes.branchDetail,
      arguments: store,
    );
    if (selected is! CustomerStore || !mounted) return;
    setState(() {
      _selectedStoreId = selected.id;
    });
    widget.onStoreSelected(selected);
  }

  void _openDirections(CustomerStore store) {
    Get.toNamed(AppRoutes.branchDirections, arguments: store);
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
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

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint});
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
    readOnly: true,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9BAAC0)),
      prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 30),
      suffixIcon: const Icon(
        Icons.location_on_outlined,
        color: _blue,
        size: 31,
      ),
      filled: true,
      fillColor: Colors.white,
      border: _outline(),
      enabledBorder: _outline(),
    ),
  );
  OutlineInputBorder _outline() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(17),
    borderSide: const BorderSide(color: Color(0xFFDCE5F1), width: 1.3),
  );
}

class _DistrictChips extends StatelessWidget {
  const _DistrictChips({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const _items = [
    '\uAC15\uB0A8\uAD6C',
    '\uC11C\uCD08\uAD6C',
    '\uC1A1\uD30C\uAD6C',
    '\uB9C8\uD3EC\uAD6C',
    '\uC804\uCCB4 \uC9C0\uC5ED',
  ];
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (_, index) {
        final item = _items[index];
        final active = item == selected;
        return ChoiceChip(
          label: Text(item),
          selected: active,
          onSelected: (_) => onSelected(item),
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

class _FeaturedBranch extends StatelessWidget {
  const _FeaturedBranch({
    required this.store,
    required this.distance,
    required this.onTap,
    required this.onDirections,
  });
  final CustomerStore store;
  final String distance;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(25),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF11255B), Color(0xFF244FAF)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0x334D83DC),
                child: Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFFD7E6FF),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  store.name.isEmpty ? store.id : store.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(distance, style: const TextStyle(color: Color(0xFFC7D8FC))),
            ],
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: Color(0xFF27D579)),
              SizedBox(width: 8),
              Text(
                '\uC601\uC5C5\uC911    \uC624\uB298 10:00-20:00',
                style: TextStyle(color: Color(0xFFC7D8FC)),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            store.district +
                '  ' +
                (store.phone.isEmpty
                    ? '\uB300\uB9AC\uC810 \uC815\uBCF4'
                    : store.phone),
            style: const TextStyle(color: Color(0xFFC7D8FC)),
          ),
          const Divider(color: Color(0x447FA5F7), height: 25),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\uD604\uC7AC \uC218\uB839 \uB300\uAE30',
                      style: TextStyle(color: Color(0xFFAFC5F0), fontSize: 12),
                    ),
                    Text(
                      '32\uAC74',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('\uAE38\uCC3E\uAE30'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF7FA5F7)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_rounded),
                label: const Text('\uC9C0\uC810 \uC120\uD0DD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({
    required this.store,
    required this.distance,
    required this.onTap,
  });
  final CustomerStore store;
  final String distance;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(19),
    child: Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [BoxShadow(color: Color(0x0A1F3C70), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFF0F5FF),
            child: Icon(Icons.storefront_outlined, color: _blue, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.district + ' \u00B7 ' + distance,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                Text(
                  store.name.isEmpty ? store.id : store.name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  '\uC601\uC5C5\uC911    \uC218\uB839 \uB300\uAE30 18\uAC74',
                  style: TextStyle(color: Color(0xFF35A36E), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF97A8BF),
            size: 30,
          ),
        ],
      ),
    ),
  );
}

class _EmptyStores extends StatelessWidget {
  const _EmptyStores();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(35),
    child: Center(
      child: Text(
        '\uC120\uD0DD\uD55C \uC9C0\uC5ED\uC5D0 \uB300\uB9AC\uC810\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
        style: TextStyle(color: _muted),
      ),
    ),
  );
}
