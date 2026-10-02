import 'package:flutter/material.dart';
import 'package:get/get.dart';

const _blue = Color(0xFF2F67E8);

/// Shared customer navigation shown on the primary customer screens.
///
/// When no callback is supplied, the selected customer tab becomes the new
/// root route. This lets list pages keep the same navigation behaviour as the
/// home screen without owning a duplicate bottom bar.
class CustomerBottomTabs extends StatelessWidget {
  const CustomerBottomTabs({
    super.key,
    required this.selectedIndex,
    this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  static const _tabs = [
    (Icons.home_outlined, '\uD648'),
    (Icons.location_on_outlined, '\uB300\uB9AC\uC810'),
    (Icons.receipt_long_outlined, '\uC8FC\uBB38\uB0B4\uC5ED'),
    (Icons.person_outline_rounded, 'MY'),
  ];

  void _select(int index) {
    if (onSelected != null) {
      if (index == selectedIndex) return;
      onSelected!(index);
      return;
    }
    Get.offAllNamed('/customer/home', arguments: index);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 82,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final active = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => _select(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFEAF2FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      tab.$1,
                      color: active ? _blue : const Color(0xFF8A9AB1),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tab.$2,
                    style: TextStyle(
                      color: active ? _blue : const Color(0xFF7E8FA8),
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  );
}
