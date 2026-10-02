import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class BranchDirectionsPage extends StatefulWidget {
  const BranchDirectionsPage({super.key, required this.store});
  final CustomerStore store;

  @override
  State<BranchDirectionsPage> createState() => _BranchDirectionsPageState();
}

class _BranchDirectionsPageState extends State<BranchDirectionsPage> {
  final _mapController = MapController();
  late final LatLng _branch;
  late LatLng _origin;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _branch = _coordinatesFor(widget.store);
    _origin = const LatLng(37.5665, 126.9780);
    _loadCurrentPosition();
  }

  LatLng _coordinatesFor(CustomerStore store) {
    if (store.latitude != null && store.longitude != null) {
      return LatLng(store.latitude!, store.longitude!);
    }
    const centres = {
      '\uAC15\uB0A8\uAD6C': LatLng(37.4979, 127.0276),
      '\uC11C\uCD08\uAD6C': LatLng(37.4837, 127.0324),
      '\uC1A1\uD30C\uAD6C': LatLng(37.5145, 127.1059),
      '\uB9C8\uD3EC\uAD6C': LatLng(37.5663, 126.9019),
    };
    return centres[store.district] ?? const LatLng(37.5665, 126.9780);
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
      if (!mounted) return;
      setState(() => _origin = LatLng(position.latitude, position.longitude));
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [_origin, _branch],
          padding: const EdgeInsets.all(46),
        ),
      );
    } catch (_) {
      // The map remains available with a Seoul-centre fallback origin.
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  double get _meters => Geolocator.distanceBetween(
    _origin.latitude,
    _origin.longitude,
    _branch.latitude,
    _branch.longitude,
  );

  int get _walkMinutes => (_meters / 75).ceil().clamp(1, 999);

  String get _distanceLabel => _meters < 1000
      ? '${_meters.round()}m'
      : '${(_meters / 1000).toStringAsFixed(1)}km';

  String get _storeName =>
      widget.store.name.isEmpty ? widget.store.id : widget.store.name;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '\uB300\uB9AC\uC810 \uAE38\uCC3E\uAE30',
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
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 18),
          child: Icon(Icons.receipt_long_outlined, color: _muted),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 7, 20, 20),
          children: [
            _LocationSummary(name: _storeName),
            const SizedBox(height: 17),
            _TravelModes(minutes: _walkMinutes),
            const SizedBox(height: 18),
            _RouteMap(
              controller: _mapController,
              origin: _origin,
              destination: _branch,
              name: _storeName,
              distance: _distanceLabel,
              minutes: _walkMinutes,
              loading: _loadingLocation,
            ),
            const SizedBox(height: 27),
            const Text(
              '\uACBD\uB85C \uC548\uB0B4',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _DirectionsSteps(
              name: _storeName,
              firstMeters: (_meters * .25).round(),
              secondMeters: (_meters * .75).round(),
            ),
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
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '\uC5F0\uACB0\uD560 \uC9C0\uB3C4 \uC571\uC744 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694.',
                  ),
                ),
              ),
              icon: const Icon(Icons.apps_outlined),
              label: const Text('\uB2E4\uB978 \uC571'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(130, 58),
                foregroundColor: _ink,
                side: const BorderSide(color: Color(0xFFDCE5F1)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '\uC2E4\uC2DC\uAC04 \uAE38\uC548\uB0B4\uB97C \uC900\uBE44 \uC911\uC785\uB2C8\uB2E4.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.near_me_outlined),
                label: const Text(
                  '\uC9C0\uB3C4 \uC571\uC5D0\uC11C \uC2DC\uC791',
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

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Column(
          children: [
            Icon(Icons.circle, color: _blue, size: 14),
            SizedBox(height: 17),
            Icon(Icons.location_on_rounded, color: _blue, size: 29),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '\uCD9C\uBC1C     \uD604\uC7AC \uC704\uCE58',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 21),
              Text(
                '\uB3C4\uCC29     $name',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.swap_vert_rounded, color: _blue, size: 31),
      ],
    ),
  );
}

class _TravelModes extends StatelessWidget {
  const _TravelModes({required this.minutes});
  final int minutes;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF0F9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Mode(
            icon: Icons.directions_walk_rounded,
            label: '\uB3C4\uBCF4 $minutes\uBD84',
            active: true,
          ),
        ),
        const Expanded(
          child: _Mode(
            icon: Icons.directions_car_outlined,
            label: '\uC790\ub3d9\ucc28',
          ),
        ),
        const Expanded(
          child: _Mode(
            icon: Icons.subway_outlined,
            label: '\uB300\uc911\uad50\ud1b5',
          ),
        ),
      ],
    ),
  );
}

class _Mode extends StatelessWidget {
  const _Mode({required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? _blue : _muted, size: 23),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? _blue : _muted,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({
    required this.controller,
    required this.origin,
    required this.destination,
    required this.name,
    required this.distance,
    required this.minutes,
    required this.loading,
  });
  final MapController controller;
  final LatLng origin;
  final LatLng destination;
  final String name;
  final String distance;
  final int minutes;
  final bool loading;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 430,
      child: Stack(
        children: [
          FlutterMap(
            mapController: controller,
            options: MapOptions(initialCenter: destination, initialZoom: 13.2),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.stepseoul.app',
                tileProvider: NetworkTileProvider(
                  cachingProvider: const DisabledMapCachingProvider(),
                ),
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [origin, destination],
                    color: _blue,
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: origin,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: _blue,
                      size: 34,
                    ),
                  ),
                  Marker(
                    point: destination,
                    width: 138,
                    height: 105,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF192D66),
                          size: 54,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF192D66),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
          Positioned(
            right: 13,
            top: 13,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'plus',
                  backgroundColor: Colors.white,
                  foregroundColor: _blue,
                  onPressed: () => controller.move(destination, 15),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'minus',
                  backgroundColor: Colors.white,
                  foregroundColor: _muted,
                  onPressed: () => controller.move(destination, 12),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 19,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Text(
                    '$minutes\uBD84',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '\u00B7  $distance',
                    style: const TextStyle(color: _muted),
                  ),
                  const Spacer(),
                  if (loading)
                    const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _blue,
                      ),
                    )
                  else
                    const Icon(Icons.navigation_outlined, color: _blue),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DirectionsSteps extends StatelessWidget {
  const _DirectionsSteps({
    required this.name,
    required this.firstMeters,
    required this.secondMeters,
  });
  final String name;
  final int firstMeters;
  final int secondMeters;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      children: [
        _Step(
          icon: Icons.add_rounded,
          title:
              '\uD604\uC7AC \uC704\uCE58\uC5D0\uC11C \uB300\uB9AC\uC810 \uBC29\uD5A5',
          detail: '\uC57D ${firstMeters}m \uc9c1\uc9c4',
          first: true,
        ),
        _Step(
          icon: Icons.turn_right_rounded,
          title:
              '\uAD50\ucc28\ub85c\uc5d0\uc11c \uc624\ub978\ucabd\uc73c\ub85c \uc774\ub3d9',
          detail: '\uC57D ${secondMeters}m \uc774\ub3d9',
        ),
        _Step(
          icon: Icons.location_on_rounded,
          title: '$name \uB3C4\ucc29',
          detail: '\uC785\uAD6C\ub97c \ud655\uc778\ud574 \uc8fc\uc138\uc694.',
          last: true,
        ),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.detail,
    this.first = false,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String detail;
  final bool first;
  final bool last;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: last
                ? const Color(0xFF192D66)
                : const Color(0xFFEAF2FF),
            child: Icon(icon, color: last ? Colors.white : _blue, size: 19),
          ),
          if (!last)
            Container(width: 2, height: 32, color: const Color(0xFFDCE5F1)),
        ],
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    ],
  );
}
