import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/customer/branch_detail.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/customer_bottom_tabs.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class BranchListPage extends StatefulWidget {
  const BranchListPage({super.key, required this.stores, this.selectedStoreId});
  final List<CustomerStore> stores;
  final String? selectedStoreId;

  @override
  State<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends State<BranchListPage> {
  final _searchController = TextEditingController();
  String _district = '\uC804\uCCB4 \uC9C0\uC5ED';
  String _query = '';
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.selectedStoreId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerStore> get _visibleStores => widget.stores.where((store) {
    final matchesDistrict =
        _district == '\uC804\uCCB4 \uC9C0\uC5ED' || store.district == _district;
    final keyword = _query.trim().toLowerCase();
    final matchesQuery =
        keyword.isEmpty ||
        store.name.toLowerCase().contains(keyword) ||
        store.district.toLowerCase().contains(keyword) ||
        store.id.toLowerCase().contains(keyword);
    return matchesDistrict && matchesQuery;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final stores = _visibleStores;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                _AppBar(onBack: () => Navigator.of(context).pop()),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
                    children: [
                      _SearchBox(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      const SizedBox(height: 19),
                      _DistrictChips(
                        selected: _district,
                        onSelected: (value) =>
                            setState(() => _district = value),
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Text(
                            '\uAC80\uC0C9 \uACB0\uACFC ${stores.length}',
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          _SortChip(),
                          const SizedBox(width: 8),
                          const _ViewMode(),
                        ],
                      ),
                      const SizedBox(height: 13),
                      if (stores.isEmpty)
                        const _EmptyState()
                      else
                        ...List.generate(
                          stores.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _BranchCard(
                              store: stores[index],
                              index: index,
                              selected: _selectedStoreId == stores[index].id,
                              onSelect: () => _selectStore(stores[index]),
                              onDetails: () => _openDetails(stores[index]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomTabs(selectedIndex: 1),
    );
  }

  Future<void> _selectStore(CustomerStore store) async {
    final session = await SessionService.instance.readSession();
    if (session == null) return;
    await SessionService.instance.saveSelectedStoreId(
      userId: session.userId,
      storeId: store.id,
    );
    if (mounted) Navigator.of(context).pop(store);
  }

  Future<void> _openDetails(CustomerStore store) async {
    final selected = await Navigator.of(context).push<CustomerStore>(
      MaterialPageRoute(builder: (_) => BranchDetailPage(store: store)),
    );
    if (selected != null && mounted) Navigator.of(context).pop(selected);
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: _muted,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFDCE5F1)),
          ),
        ),
        const Expanded(
          child: Text(
            '\uC804\uCCB4 \uB300\uB9AC\uC810',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const CartNavigationButton(),
      ],
    ),
  );
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText:
          '\uC790\uCE58\uAD6C \uB610\uB294 \uB300\uB9AC\uC810\uBA85 \uAC80\uC0C9',
      hintStyle: const TextStyle(color: Color(0xFF9BAAC0)),
      prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 30),
      suffixIcon: const Icon(
        Icons.location_on_outlined,
        color: _blue,
        size: 31,
      ),
      filled: true,
      fillColor: Colors.white,
      border: _border(),
      enabledBorder: _border(),
      focusedBorder: _border(color: _blue),
    ),
  );

  OutlineInputBorder _border({Color color = const Color(0xFFDCE5F1)}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: color, width: 1.3),
      );
}

class _DistrictChips extends StatelessWidget {
  const _DistrictChips({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const _items = [
    '\uC804\uCCB4 \uC9C0\uC5ED',
    '\uAC15\uB0A8\uAD6C',
    '\uC11C\uCD08\uAD6C',
    '\uC1A1\uD30C\uAD6C',
    '\uB9C8\uD3EC\uAD6C',
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
          side: BorderSide(color: active ? _blue : const Color(0xFFDCE5F1)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          labelStyle: TextStyle(
            color: active ? Colors.white : const Color(0xFF536680),
            fontWeight: FontWeight.w700,
          ),
        );
      },
    ),
  );
}

class _SortChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDCE5F1)),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Row(
      children: [
        Icon(Icons.swap_vert_rounded, color: _muted),
        SizedBox(width: 3),
        Text(
          '\uAC00\uAE4C\uC6B4 \uC21C',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ViewMode extends StatelessWidget {
  const _ViewMode();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        '\uBAA9\uB85D',
        style: TextStyle(
          color: _blue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.store,
    required this.index,
    required this.selected,
    required this.onSelect,
    required this.onDetails,
  });
  final CustomerStore store;
  final int index;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final featured = index == 0;
    final name = store.name.isEmpty ? store.id : store.name;
    if (featured) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onDetails,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF11255B), Color(0xFF244FAF)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 19,
                      backgroundColor: Color(0x334D83DC),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFD7E6FF),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDetails,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFC7D8FC),
                      ),
                    ),
                    const _DistanceTag(text: '0.8km'),
                  ],
                ),
                const SizedBox(height: 13),
                const Text(
                  '\uD83D\uDFE2  \uC601\uC5C5\uC911      \uC624\uB298 10:00-20:00',
                  style: TextStyle(color: Color(0xFFC7D8FC)),
                ),
                const SizedBox(height: 10),
                Text(
                  '${store.district}  ${store.phone.isEmpty ? '\uB300\uB9AC\uC810 \uC815\uBCF4' : store.phone}',
                  style: const TextStyle(color: Color(0xFFC7D8FC)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '\uC218\uB839 \uB300\uAE30 32\uAC74 \u00B7 \uC8FC\uCC28 1\uC2DC\uAC04 \uBB34\uB8CC',
                        style: TextStyle(
                          color: Color(0xFFAFC5F0),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: onSelect,
                      icon: Icon(
                        selected ? Icons.check_rounded : Icons.add_rounded,
                        size: 18,
                      ),
                      label: Text(
                        selected
                            ? '\uC120\uD0DD\uB428'
                            : '\uC9C0\uC810 \uC120\uD0DD',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    final colors = [
      const Color(0xFF2F67E8),
      const Color(0xFF8C56F6),
      const Color(0xFFFFA319),
    ];
    final color = colors[(index - 1) % colors.length];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withValues(alpha: .08),
                child: Icon(Icons.storefront_outlined, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${store.district} \u00B7 ${(index * 2.4).toStringAsFixed(1)}km',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '\uD83D\uDFE2  \uC601\uC5C5\uC911     \uC218\uB839 \uB300\uAE30 18\uAC74',
                      style: TextStyle(color: Color(0xFF35A36E), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      store.phone.isEmpty
                          ? '\uC8FC\uCC28 \uC815\uBCF4 \uBB38\uC758'
                          : store.phone,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  OutlinedButton(
                    onPressed: onSelect,
                    child: Text(
                      selected ? '\uC120\uD0DD\uB428' : '\uC120\uD0DD',
                    ),
                  ),
                  IconButton(
                    onPressed: onDetails,
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF97A8BF),
                      size: 29,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DistanceTag extends StatelessWidget {
  const _DistanceTag({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x337FA5F7),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFFC7D8FC), fontSize: 12),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 90),
    child: Column(
      children: [
        Icon(Icons.storefront_outlined, size: 48, color: _blue),
        SizedBox(height: 12),
        Text(
          '\uC870\uAC74\uC5D0 \uB9DE\uB294 \uB300\uB9AC\uC810\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
          style: TextStyle(color: _muted),
        ),
      ],
    ),
  );
}
