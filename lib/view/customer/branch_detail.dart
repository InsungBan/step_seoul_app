import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/branch_directions.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class BranchDetailPage extends StatefulWidget {
  const BranchDetailPage({super.key, required this.store});
  final CustomerStore store;

  @override
  State<BranchDetailPage> createState() => _BranchDetailPageState();
}

class _BranchDetailPageState extends State<BranchDetailPage> {
  final _mapController = MapController();
  late final LatLng _branchPosition;
  String? _address;
  double? _distanceKm;
  bool _locating = true;

  @override
  void initState() {
    super.initState();
    _branchPosition = _coordinatesFor(widget.store);
    _loadLocationDetails();
  }

  LatLng _coordinatesFor(CustomerStore store) {
    if (store.latitude != null && store.longitude != null) {
      return LatLng(store.latitude!, store.longitude!);
    }
    const districtCentres = {
      '\uAC15\uB0A8\uAD6C': LatLng(37.4979, 127.0276),
      '\uC11C\uCD08\uAD6C': LatLng(37.4837, 127.0324),
      '\uC1A1\uD30C\uAD6C': LatLng(37.5145, 127.1059),
      '\uB9C8\uD3EC\uAD6C': LatLng(37.5663, 126.9019),
    };
    return districtCentres[store.district] ?? const LatLng(37.5665, 126.9780);
  }

  Future<void> _loadLocationDetails() async {
    await Future.wait([_loadAddress(), _loadDistance()]);
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _loadAddress() async {
    try {
      final places = await placemarkFromCoordinates(
        _branchPosition.latitude,
        _branchPosition.longitude,
      );
      if (places.isNotEmpty && mounted) {
        final place = places.first;
        final parts = [
          place.administrativeArea,
          place.locality,
          place.thoroughfare,
        ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
        setState(() => _address = parts.join(' '));
      }
    } catch (_) {
      // Reverse geocoding can be unavailable on emulators or offline devices.
    }
  }

  Future<void> _loadDistance() async {
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
      final current = await Geolocator.getCurrentPosition();
      final meters = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        _branchPosition.latitude,
        _branchPosition.longitude,
      );
      if (mounted) setState(() => _distanceKm = meters / 1000);
    } catch (_) {
      // Keep the map usable when a device does not provide a location.
    }
  }

  Future<void> _selectStore() async {
    final session = await SessionService.instance.readSession();
    if (session == null) return;
    await SessionService.instance.saveSelectedStoreId(
      userId: session.userId,
      storeId: widget.store.id,
    );
    if (mounted) Navigator.of(context).pop(widget.store);
  }

  String get _storeName =>
      widget.store.name.isEmpty ? widget.store.id : widget.store.name;

  String get _distanceText {
    if (_locating) return '\uAC70\uB9AC \uD655\uC778 \uC911';
    if (_distanceKm == null)
      return '\uD604\uC7AC \uC704\uCE58 \uD655\uC778 \uD544\uC694';
    if (_distanceKm! < 1) return '${(_distanceKm! * 1000).round()}m';
    return '${_distanceKm!.toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '\uB300\uB9AC\uC810 \uC0C1\uC138',
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
      actions: [
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '\uACF5\uC720 \uAE30\uB2A5\uC740 \uC900\uBE44 \uC911\uC785\uB2C8\uB2E4.',
              ),
            ),
          ),
          icon: const Icon(Icons.share_outlined, color: _muted),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: CartNavigationButton(),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 18),
          children: [
            _MapCard(
              controller: _mapController,
              branch: _branchPosition,
              name: _storeName,
              distance: _distanceText,
            ),
            const SizedBox(height: 22),
            _BranchSummary(
              store: widget.store,
              name: _storeName,
              address:
                  _address ?? '${widget.store.district} \uB300\uB9AC\uC810',
            ),
            const SizedBox(height: 26),
            const Text(
              '\uC218\uB839 \uD604\uD669',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const _PickupStatus(),
            const SizedBox(height: 26),
            const Text(
              '\uB300\uB9AC\uC810 \uC815\uBCF4',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _BranchInfo(store: widget.store),
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BranchDirectionsPage(store: widget.store),
                ),
              ),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('\uAE38\uCC3E\uAE30'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(122, 58),
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFDCE5F1)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _selectStore,
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  '\uC218\uB839 \uC9C0\uC810\uC73C\uB85C \uC120\uD0DD',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
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

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.controller,
    required this.branch,
    required this.name,
    required this.distance,
  });
  final MapController controller;
  final LatLng branch;
  final String name;
  final String distance;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 282,
      child: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(initialCenter: branch, initialZoom: 15.5),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.stepseoul.app',
                // The built-in persistent cache asks path_provider for an app
                // cache directory. Disable it so desktop/emulator platforms
                // without that directory can still open the detail screen.
                tileProvider: NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                ),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: branch,
                    width: 130,
                    height: 104,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: _blue,
                          size: 56,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF172D67),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
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
              RichAttributionWidget(
                attributions: const [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(left: 13, top: 13, child: _MapBadge(text: distance)),
          Positioned(
            right: 13,
            bottom: 13,
            child: FloatingActionButton.small(
              heroTag: 'mapZoom',
              backgroundColor: Colors.white,
              foregroundColor: _blue,
              onPressed: () => controller.move(branch, 16.5),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _BranchSummary extends StatelessWidget {
  const _BranchSummary({
    required this.store,
    required this.name,
    required this.address,
  });
  final CustomerStore store;
  final String name;
  final String address;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 27,
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(Icons.storefront_outlined, color: _blue, size: 29),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '\uD83D\uDFE2  \uC601\uC5C5\uC911     \uC624\uB298 10:00-20:00',
                    style: TextStyle(color: Color(0xFF35A36E), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Text(address, style: const TextStyle(color: _muted)),
        const SizedBox(height: 7),
        const Text(
          '\uAC00\uAE4C\uC6B4 \uC9C0\uD558\uCCA0\uC5ED\uC5D0\uC11C \uB3C4\uBCF4 8\uBD84',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const Divider(height: 23, color: Color(0xFFDCE5F1)),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryAction(
              icon: Icons.location_on_outlined,
              label: '\uAE38\uCC3E\uAE30',
            ),
            _SummaryAction(icon: Icons.call_outlined, label: '\uC804\uD654'),
            _SummaryAction(
              icon: Icons.copy_outlined,
              label: '\uC8FC\uC18C \uBCF5\uC0AC',
            ),
          ],
        ),
      ],
    ),
  );
}

class _SummaryAction extends StatelessWidget {
  const _SummaryAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _blue),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: _blue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _PickupStatus extends StatelessWidget {
  const _PickupStatus();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF142B66), Color(0xFF263C83)],
      ),
      borderRadius: BorderRadius.circular(21),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatusMetric(
                label: '\uD604\uC7AC \uC218\uB839 \uB300\uAE30',
                value: '32\uAC74',
              ),
            ),
            VerticalDivider(color: Color(0x557FA5F7)),
            Expanded(
              child: _StatusMetric(
                label: '\uC608\uC0C1 \uB300\uAE30\uC2DC\uAC04',
                value: '\uC57D 5\uBD84',
              ),
            ),
          ],
        ),
        SizedBox(height: 17),
        _PickupNotice(),
      ],
    ),
  );
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFFAFC5F0), fontSize: 12),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 25,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _PickupNotice extends StatelessWidget {
  const _PickupNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0x223B68B8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      children: [
        Icon(Icons.circle, color: Color(0xFF28D67B), size: 10),
        SizedBox(width: 8),
        Text(
          '\uC624\uB298 \uC8FC\uBB38\uD558\uBA74 \uC601\uC5C5\uC2DC\uAC04 \uB0B4 \uC218\uB839\uD560 \uC218 \uC788\uC5B4\uC694.',
          style: TextStyle(color: Color(0xFFC7D8FC), fontSize: 12),
        ),
      ],
    ),
  );
}

class _BranchInfo extends StatelessWidget {
  const _BranchInfo({required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        _InfoRow(
          icon: Icons.schedule_outlined,
          label: '\uC6B4\uC601\uC2DC\uAC04',
          value: '\uB9E4\uC77C 10:00-20:00',
        ),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: '\uC804\uD654\uBC88\uD638',
          value: store.phone.isEmpty ? '02-555-0123' : store.phone,
        ),
        const _InfoRow(
          icon: Icons.local_parking_outlined,
          label: '\uC8FC\uCC28 \uC548\uB0B4',
          value: '\uC0C1\uD488 \uC218\uB839 \uC2DC 1\uC2DC\uAC04 \uBB34\uB8CC',
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '\uD734\uBB34\uC77C\uACFC \uC6B4\uC601\uC2DC\uAC04\uC740 \uACF5\uD734\uC77C\uC5D0 \uBCC0\uACBD\uB420 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFDCE5F1))),
    ),
    child: Row(
      children: [
        Icon(icon, color: _blue, size: 21),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: _muted)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}
