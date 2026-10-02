import 'package:flutter/material.dart';
import 'hq_demo_data.dart';
import 'hq_palette.dart';

class HqConsole extends StatefulWidget {
  const HqConsole({super.key});
  @override
  State<HqConsole> createState() => _HqConsoleState();
}

class _HqConsoleState extends State<HqConsole> {
  final search = TextEditingController();
  final products = HqDemoData.products();
  final orders = HqDemoData.orders();
  final proposals = HqDemoData.proposals();
  final purchasing = HqDemoData.purchasing();
  final stores = HqDemoData.stores();
  final selected = <String>{};
  int section = 0, tab = 0, page = 0;
  String query = '', status = '전체 상태';
  static const labels = [
    '대시보드',
    '주문 · 배송',
    '전체 재고',
    '품의 관리',
    '발주 · 수주',
    '판매 현황',
    '기준 정보',
  ];
  static const icons = [
    Icons.dashboard_outlined,
    Icons.local_shipping_outlined,
    Icons.grid_view,
    Icons.description_outlined,
    Icons.inventory_2_outlined,
    Icons.bar_chart,
    Icons.my_location,
  ];
  static const subtitles = [
    '판매 · 재고 · 품의 · 발주 현황을 한 화면에서 확인합니다.',
    '고객 주문 접수부터 대리점 배송, 수령, 반품까지 관리합니다.',
    '본사 및 각 대리점의 신발 재고 현황을 확인합니다.',
    '재고 부족에 따른 발주 품의서를 작성하고 진행 상태를 확인합니다.',
    '승인된 품의를 기반으로 제조사 발주와 수주, 입고 현황을 관리합니다.',
    '제품별, 대리점별 판매 성과를 분석합니다.',
    '사용자, 직원, 대리점, 신발, 제조사의 기준 데이터를 관리합니다.',
  ];
  List<String> get tabs => switch (section) {
    1 => ['주문 목록', '배송 현황', '수령 현황', '반품 현황'],
    2 => ['상품별 재고', '대리점별 재고', '재고 변동 이력'],
    3 => ['품의서 목록', '결재 대기', '승인 완료', '반려'],
    4 => ['발주 목록', '수주 현황', '입고 현황'],
    6 => ['사용자 관리', '직원 관리', '대리점 관리', '신발 정보', '제조사 정보'],
    _ => [],
  };
  List<HqRecord> get records {
    if (section == 1) {
      return orders
          .where(
            (r) =>
                tab == 0 ||
                (tab == 1 && r.status == '배송중') ||
                (tab == 2 && ['대리점 도착', '수령완료'].contains(r.status)) ||
                (tab == 3 && r.status == '반품요청'),
          )
          .toList();
    }
    if (section == 3) {
      return proposals
          .where((r) => tab == 0 || r.status == ['', '결재대기', '승인완료', '반려'][tab])
          .toList();
    }
    if (section == 4) {
      return purchasing.where((r) => tab != 2 || r.status == '입고완료').toList();
    }
    if (section == 6) {
      return switch (tab) {
        3 => products,
        4 => manufacturers,
        0 => users,
        1 => employees,
        _ => stores,
      };
    }
    if (section == 2 && tab == 1) return stores;
    if (section == 2 && tab == 2) return movements;
    return products;
  }

  late final users = List.generate(
    8,
    (i) => HqRecord(
      'USER-${i + 1}',
      ['김민수', '이지은', '박서준', '최수빈'][i % 4],
      'customer${i + 1}@example.com',
      0,
      0,
      '활성',
    ),
  );
  late final employees = List.generate(
    8,
    (i) => HqRecord(
      'EMP-${i + 1}',
      ['김사원', '이팀장', '박이사', '정대리'][i % 4],
      ['구매팀', '영업팀', '본사', '물류팀'][i % 4],
      0,
      0,
      '재직중',
    ),
  );
  late final manufacturers = List.generate(
    8,
    (i) => HqRecord(
      'MFG-${i + 1}',
      ['나이키', '아디다스', '푸마', '뉴발란스'][i % 4],
      '국내 제조사',
      0,
      0,
      '거래중',
    ),
  );
  late final movements = List.generate(
    8,
    (i) => HqRecord(
      'LOG-${i + 1}',
      products[i].name,
      '본사 물류센터',
      i + 3,
      0,
      ['판매', '입고', '반품'][i % 3],
    ),
  );
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void navigate(int index) => setState(() {
    section = index;
    tab = index == 6 ? 2 : 0;
    page = 0;
    query = '';
    search.clear();
    status = '전체 상태';
    selected.clear();
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1050;
      return Scaffold(
        backgroundColor: HqPalette.canvas,
        drawer: wide ? null : Drawer(child: sidebar(true)),
        body: Row(
          children: [
            if (wide) SizedBox(width: 238, child: sidebar(false)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (!wide)
                          Builder(
                            builder: (context) => IconButton(
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section == 0 ? '본사 임원 대시보드' : labels[section],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: HqPalette.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitles[section],
                                style: const TextStyle(
                                  color: HqPalette.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (constraints.maxWidth > 760) ...[
                          chip(Icons.schedule, date()),
                          const SizedBox(width: 10),
                          chip(Icons.shield_outlined, '이사 권한'),
                        ],
                        IconButton(
                          tooltip: '알림',
                          onPressed: notifications,
                          icon: const Badge(
                            label: Text('3'),
                            child: Icon(
                              Icons.notifications_none,
                              color: HqPalette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: HqPalette.muted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '디자인 미리보기 · 예시 데이터',
                          style: TextStyle(
                            fontSize: 12,
                            color: HqPalette.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    metrics(),
                    const SizedBox(height: 18),
                    if (section == 0)
                      dashboard()
                    else if (section == 5)
                      sales()
                    else ...[
                      if (section == 2) chartPair(),
                      const SizedBox(height: 16),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ...List.generate(
                            tabs.length,
                            (i) => TextButton(
                              onPressed: () => setState(() {
                                tab = i;
                                page = 0;
                                status = '전체 상태';
                                selected.clear();
                              }),
                              style: TextButton.styleFrom(
                                foregroundColor: tab == i
                                    ? HqPalette.purple
                                    : HqPalette.muted,
                                backgroundColor: tab == i
                                    ? const Color(0xFFEEE9FF)
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                tabs[i],
                                style: TextStyle(
                                  fontWeight: tab == i
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => editRecord(),
                            icon: const Icon(Icons.add),
                            label: Text(
                              section == 3
                                  ? '품의서 작성'
                                  : section == 4
                                  ? '발주 등록'
                                  : section == 6
                                  ? '기준 정보 등록'
                                  : '신규 등록',
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: HqPalette.line),
                      filters(),
                      const SizedBox(height: 14),
                      table(),
                      const SizedBox(height: 18),
                      processPanel(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  String date() {
    final d = DateTime.now();
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  Widget sidebar(bool drawer) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [HqPalette.navy, Color(0xFF0B1421)],
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 20, 30),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HqPalette.purple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.show_chart,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STEP HQ',
                            style: TextStyle(color: Colors.white, fontSize: 22),
                          ),
                          Text(
                            'EXECUTIVE CONSOLE',
                            style: TextStyle(
                              color: Color(0xFF99B7D7),
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 30, bottom: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MANAGEMENT',
                  style: TextStyle(
                    color: Color(0xFF89A8CA),
                    letterSpacing: 2,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: List.generate(
                  labels.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: section == i ? HqPalette.purple : null,
                      leading: Icon(
                        icons[i],
                        color: section == i
                            ? Colors.white
                            : const Color(0xFFA9C8E2),
                      ),
                      title: Text(
                        labels[i],
                        style: TextStyle(
                          color: section == i
                              ? Colors.white
                              : const Color(0xFFA9C8E2),
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        navigate(i);
                        if (drawer) Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Divider(color: Color(0xFF2A3B52)),
            ),
            const ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: HqPalette.purple,
                child: Text('박', style: TextStyle(color: Colors.white)),
              ),
              title: Text('박이사', style: TextStyle(color: Colors.white)),
              subtitle: Text(
                '본사 · 영업총괄이사',
                style: TextStyle(color: Color(0xFF99B7D7), fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 24),
              child: OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('STEP HQ 미리보기'),
                    content: const Text(
                      '예시 데이터로 실행 중입니다. 로그인 기능은 서버 연동 시 제공됩니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF99B7D7),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: HqPalette.line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: HqPalette.purple),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
  Widget panel(String title, Widget child, {Widget? action}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: HqPalette.line),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: HqPalette.ink,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
  Widget metrics() {
    final data = switch (section) {
      1 => [
        ('전체 주문', '148건', '오늘 12건', Icons.shopping_cart_outlined),
        ('배송중', '27건', '대리점 이동 중', Icons.local_shipping_outlined),
        ('대리점 도착', '18건', '오늘 도착 5건', Icons.storefront),
        ('수령 완료', '92건', '전일 대비 +10건', Icons.check_circle_outline),
      ],
      2 => [
        ('전체 상품 수', '512개', '판매 가능 상품 기준', Icons.inventory_2_outlined),
        ('총 재고 수량', '12,482개', '전일 대비 +5.2%', Icons.layers_outlined),
        ('재고 30% 미만', '68개', '전체의 13.3%', Icons.warning_amber),
        ('자동 발주 대상', '32개', '오늘 신규 5개', Icons.shopping_cart_outlined),
      ],
      3 => [
        ('전체 품의서', '24건', '진행중 6건', Icons.description_outlined),
        ('결재 대기', '3건', '오늘 신규 1건', Icons.schedule),
        ('승인 완료', '18건', '이번 달 12건', Icons.check),
        ('반려', '2건', '재작성 필요', Icons.close),
      ],
      4 => [
        ('전체 발주', '28건', '발주금액 186,420,000원', Icons.description_outlined),
        ('제조사 수주 확인', '21건', '수주율 75%', Icons.local_shipping_outlined),
        ('입고 대기', '5건', '예정일 초과 2건', Icons.schedule),
        ('입고 완료', '18건', '이번 달 9건', Icons.check),
      ],
      6 => [
        ('사용자 수', '24명', '활성 22명', Icons.person_outline),
        ('직원 수', '38명', '영업 18명', Icons.people_outline),
        ('대리점 수', '42개', '서울 25개', Icons.storefront),
        ('등록 상품 수', '1,248개', '판매중 980개', Icons.inventory_2_outlined),
      ],
      _ => [
        ('오늘 판매금액', '18,420,000원', '전일 대비 +8.4%', Icons.bar_chart),
        ('결제완료 주문', '148건', '배송대기 27건', Icons.shopping_cart_outlined),
        ('재고 30% 미만', '6개', '신규 발생 2개', Icons.warning_amber),
        ('최종결재 대기', '3건', '오늘 접수 2건', Icons.schedule),
      ],
    };
    return LayoutBuilder(
      builder: (c, b) {
        final n = b.maxWidth > 1000
            ? 4
            : b.maxWidth > 600
            ? 2
            : 1;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(data.length, (i) {
            final d = data[i];
            final color = [
              HqPalette.purple,
              Colors.blue,
              HqPalette.red,
              HqPalette.orange,
            ][i];
            return SizedBox(
              width: (b.maxWidth - (n - 1) * 12) / n,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HqPalette.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(d.$4, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.$1),
                          const SizedBox(height: 12),
                          FittedBox(
                            child: Text(
                              d.$2,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: HqPalette.ink,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.$3,
                            style: TextStyle(
                              fontSize: 12,
                              color: i == 0 ? HqPalette.green : HqPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget pair(Widget a, Widget b) => LayoutBuilder(
    builder: (c, s) => s.maxWidth > 850
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: a),
              const SizedBox(width: 14),
              Expanded(flex: 5, child: b),
            ],
          )
        : Column(children: [a, const SizedBox(height: 14), b]),
  );
  Widget dashboard() => Column(
    children: [
      pair(
        panel(
          '최근 7일 판매금액',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('결제완료 기준', style: TextStyle(color: HqPalette.muted)),
              const SizedBox(height: 14),
              const Text(
                '112,860,000원',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              lineChart(),
            ],
          ),
        ),
        panel(
          '최종결재 대기',
          Column(
            children: [
              ...proposals
                  .where((r) => r.status == '결재대기')
                  .take(3)
                  .map(
                    (r) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(r.partner),
                      trailing: badge(r.status),
                      onTap: () => detail(r),
                    ),
                  ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => navigate(3),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('최종결재함 열기'),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      panel(
        '재고 부족 상품',
        Column(
          children: products
              .where((r) => r.ratio < 35)
              .map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: productIcon(),
                  title: Text(r.name),
                  subtitle: Text('${r.quantity} / 100 · ${r.partner}'),
                  trailing: badge('${r.ratio}%'),
                  onTap: () => detail(r),
                ),
              )
              .toList(),
        ),
        action: TextButton(
          onPressed: () => navigate(2),
          child: const Text('전체 재고 보기 ›'),
        ),
      ),
    ],
  );
  Widget sales() => Column(
    children: [
      chartPair(),
      const SizedBox(height: 16),
      panel(
        '인기 판매 상품 TOP 5',
        Column(
          children: products
              .take(5)
              .map(
                (r) => ListTile(
                  leading: productIcon(),
                  title: Text(r.name),
                  subtitle: Text(r.partner),
                  trailing: Text(
                    '${hqNumber(r.amount)}원',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
  Widget chartPair() => pair(
    panel(
      section == 2 ? '재고 상태 분포' : '일별 판매 매출 추이',
      section == 2
          ? Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 26,
              runSpacing: 24,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: 0.65,
                          strokeWidth: 22,
                          color: HqPalette.green,
                          backgroundColor: Color(0xFFFFD65A),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '총 재고',
                            style: TextStyle(color: HqPalette.muted),
                          ),
                          Text(
                            '12,482개',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '● 정상 65.1%',
                      style: TextStyle(color: HqPalette.green),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '● 주의 27.3%',
                      style: TextStyle(color: HqPalette.orange),
                    ),
                    SizedBox(height: 20),
                    Text('● 부족 7.6%', style: TextStyle(color: HqPalette.red)),
                  ],
                ),
              ],
            )
          : lineChart(),
    ),
    panel(
      '카테고리별 ${section == 2 ? '재고 현황' : '판매 매출'}',
      SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            5,
            (i) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      ['3,420', '2,840', '1,650', '1,230', '890'][i],
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 135.0 - i * 23,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            HqPalette.purple.withValues(alpha: 0.55),
                            HqPalette.purple.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ['러닝화', '스니커즈', '부츠', '로퍼', '샌들'][i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: HqPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget lineChart() => const SizedBox(
    height: 190,
    width: double.infinity,
    child: CustomPaint(painter: _SalesPainter()),
  );
  Widget filters() => Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 300,
        child: TextField(
          controller: search,
          onSubmitted: (v) => setState(() {
            query = v;
            page = 0;
          }),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search, color: HqPalette.muted),
            hintText: '번호, 상품명, 담당자로 검색...',
          ),
        ),
      ),
      SizedBox(
        width: 180,
        child: DropdownButtonFormField<String>(
          initialValue: status,
          key: ValueKey('$section-$tab-$status'),
          decoration: const InputDecoration(),
          items: {
            '전체 상태',
            ...records.map((r) => r.status),
          }.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() {
            status = v!;
            page = 0;
          }),
        ),
      ),
      FilledButton.icon(
        onPressed: () => setState(() {
          query = search.text;
          page = 0;
        }),
        icon: const Icon(Icons.search),
        label: const Text('검색'),
      ),
      OutlinedButton.icon(
        onPressed: () => setState(() {
          search.clear();
          query = '';
          status = '전체 상태';
          page = 0;
        }),
        icon: const Icon(Icons.refresh),
        label: const Text('초기화'),
      ),
    ],
  );
  Widget table() {
    final filtered = records
        .where(
          (r) =>
              (status == '전체 상태' || r.status == status) &&
              '${r.id} ${r.name} ${r.partner}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    final pages = (filtered.length / 8).ceil();
    final current = pages == 0 ? 0 : page.clamp(0, pages - 1);
    final rows = filtered.skip(current * 8).take(8).toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: HqPalette.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF0F5FF)),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 66,
              columnSpacing: 28,
              columns: [
                const DataColumn(label: Text('번호')),
                DataColumn(
                  label: Text(
                    section == 3
                        ? '제목 / 신청 사유'
                        : section == 6
                        ? '이름 / 명칭'
                        : '상품 정보',
                  ),
                ),
                DataColumn(label: Text(section == 6 ? '지역 / 소속' : '제조사 / 대리점')),
                const DataColumn(label: Text('수량')),
                DataColumn(label: Text(section == 2 ? '재고비율' : '금액')),
                const DataColumn(label: Text('상태')),
                const DataColumn(label: Text('작업')),
              ],
              rows: rows
                  .map(
                    (r) => DataRow(
                      selected: selected.contains(r.id),
                      onSelectChanged: (v) => setState(() {
                        v == true ? selected.add(r.id) : selected.remove(r.id);
                      }),
                      cells: [
                        DataCell(
                          Text(r.id, style: const TextStyle(fontSize: 12)),
                        ),
                        DataCell(
                          Row(
                            children: [
                              if (section != 3 && section != 6) ...[
                                productIcon(),
                                const SizedBox(width: 10),
                              ],
                              Text(
                                r.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(r.partner)),
                        DataCell(Text('${r.quantity}')),
                        DataCell(
                          section == 2
                              ? Text(
                                  '${r.ratio}%',
                                  style: TextStyle(
                                    color: r.ratio < 30
                                        ? HqPalette.red
                                        : HqPalette.muted,
                                  ),
                                )
                              : Text('${hqNumber(r.amount)}원'),
                        ),
                        DataCell(badge(r.status)),
                        DataCell(
                          OutlinedButton(
                            onPressed: () => detail(r),
                            child: const Text('상세보기'),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('검색 결과가 없습니다.'),
          ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          children: [
            Text(
              '전체 ${filtered.length}건 중 ${rows.isEmpty ? 0 : current * 8 + 1}-${current * 8 + rows.length}건 표시',
              style: const TextStyle(color: HqPalette.muted, fontSize: 12),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: current > 0
                      ? () => setState(() => page = current - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                ...List.generate(
                  pages,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        backgroundColor: i == current
                            ? HqPalette.purple
                            : Colors.white,
                        foregroundColor: i == current
                            ? Colors.white
                            : HqPalette.muted,
                      ),
                      onPressed: () => setState(() => page = i),
                      child: Text('${i + 1}'),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: current < pages - 1
                      ? () => setState(() => page = current + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget productIcon() => Container(
    width: 42,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F4FA),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(
      Icons.sports_soccer_outlined,
      color: HqPalette.muted,
      size: 22,
    ),
  );
  Widget badge(String text) {
    final color = ['부족', '반려', '반품요청'].contains(text) || text.contains('%')
        ? HqPalette.red
        : ['주의', '결재대기', '수주대기', '휴업중'].contains(text)
        ? HqPalette.orange
        : ['배송중', '대리점 도착'].contains(text)
        ? Colors.blue
        : HqPalette.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget processPanel() => panel(
    '진행 프로세스',
    Wrap(
      spacing: 24,
      runSpacing: 16,
      children: List.generate(
        5,
        (i) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFEEE9FF),
                  child: Icon(
                    [
                      Icons.description_outlined,
                      Icons.person_outline,
                      Icons.shield_outlined,
                      Icons.local_shipping_outlined,
                      Icons.check,
                    ][i],
                    color: HqPalette.purple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ['요청 등록', '담당자 확인', '승인 완료', '진행 처리', '완료'][i],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '0${i + 1}',
                  style: const TextStyle(color: HqPalette.muted, fontSize: 12),
                ),
              ],
            ),
            if (i < 4)
              const Padding(
                padding: EdgeInsets.only(left: 24),
                child: Icon(Icons.chevron_right, color: HqPalette.muted),
              ),
          ],
        ),
      ),
    ),
  );
  void notifications() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('알림'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.warning_amber, color: HqPalette.red),
            title: Text('재고 부족 상품 6개'),
          ),
          ListTile(
            leading: Icon(Icons.description_outlined, color: HqPalette.orange),
            title: Text('최종결재 대기 3건'),
          ),
          ListTile(
            leading: Icon(Icons.local_shipping_outlined, color: Colors.blue),
            title: Text('배송 대기 주문 27건'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('닫기')),
      ],
    ),
  );
  void detail(HqRecord r) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(
        section == 2
            ? '상품 재고 상세'
            : section == 3
            ? '품의서 상세 정보'
            : section == 4
            ? '발주 상세'
            : '상세 정보',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              badge(r.status),
              const Divider(height: 32),
              ...[
                '번호: ${r.id}',
                '제조사 / 소속: ${r.partner}',
                '수량: ${r.quantity}',
                '금액: ${hqNumber(r.amount)}원',
              ].map(
                (v) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(v),
                ),
              ),
              if (section == 2) ...[
                Text('기준재고 대비 ${r.ratio}%'),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (r.ratio / 100).clamp(0, 1),
                  color: r.ratio < 30 ? HqPalette.red : HqPalette.purple,
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '예시 데이터입니다. 변경은 현재 실행 중인 미리보기에만 적용됩니다.',
                style: TextStyle(color: HqPalette.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('닫기')),
        OutlinedButton(
          onPressed: () {
            Navigator.pop(c);
            editRecord(record: r);
          },
          child: const Text('수정'),
        ),
        if (section == 3 && r.status == '결재대기')
          FilledButton(
            onPressed: () {
              setState(() => r.status = '승인완료');
              Navigator.pop(c);
            },
            child: const Text('최종 승인'),
          ),
      ],
    ),
  );
  Future<void> editRecord({HqRecord? record}) async {
    final name = TextEditingController(text: record?.name ?? '');
    final partner = TextEditingController(text: record?.partner ?? '');
    final quantity = TextEditingController(text: '${record?.quantity ?? 1}');
    final amount = TextEditingController(text: '${record?.amount ?? 0}');
    final form = GlobalKey<FormState>();
    final route = DialogRoute<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(record == null ? '신규 등록' : '정보 수정'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '이름 / 제목'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '이름을 입력하세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: partner,
                    decoration: const InputDecoration(
                      labelText: '제조사 / 대리점 / 소속',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '소속을 입력하세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantity,
                    decoration: const InputDecoration(labelText: '수량'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        int.tryParse(v ?? '') == null || int.parse(v!) < 0
                        ? '0 이상의 정수를 입력하세요'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amount,
                    decoration: const InputDecoration(labelText: '금액 (원)'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        int.tryParse(v ?? '') == null || int.parse(v!) < 0
                        ? '0 이상의 정수를 입력하세요'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '예시 데이터에 저장됩니다.',
                    style: TextStyle(color: HqPalette.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              setState(() {
                if (record != null) {
                  record.name = name.text;
                  record.partner = partner.text;
                  record.quantity = int.parse(quantity.text);
                  record.amount = int.parse(amount.text);
                } else {
                  final r = HqRecord(
                    'NEW-${DateTime.now().millisecondsSinceEpoch}',
                    name.text,
                    partner.text,
                    int.parse(quantity.text),
                    int.parse(amount.text),
                    section == 3
                        ? '결재대기'
                        : section == 4
                        ? '수주대기'
                        : section == 6
                        ? '활성'
                        : section == 2
                        ? '정상'
                        : '배송중',
                  );
                  final target = section == 3
                      ? proposals
                      : section == 4
                      ? purchasing
                      : section == 1
                      ? orders
                      : section == 6
                      ? switch (tab) {
                          0 => users,
                          1 => employees,
                          2 => stores,
                          3 => products,
                          _ => manufacturers,
                        }
                      : section == 2 && tab == 1
                      ? stores
                      : section == 2 && tab == 2
                      ? movements
                      : products;
                  target.insert(0, r);
                  page = 0;
                }
              });
              Navigator.pop(c);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    name.dispose();
    partner.dispose();
    quantity.dispose();
    amount.dispose();
  }
}

class _SalesPainter extends CustomPainter {
  const _SalesPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(36, 10, size.width - 48, size.height - 35);
    final grid = Paint()
      ..color = HqPalette.line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = plot.top + plot.height * i / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    const values = [0.27, 0.43, 0.35, 0.58, 0.72, 0.54, 0.88];
    final points = List.generate(
      values.length,
      (i) => Offset(
        plot.left + i * plot.width / 6,
        plot.bottom - values[i] * plot.height,
      ),
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final area = Path.from(path)
      ..lineTo(plot.right, plot.bottom)
      ..lineTo(plot.left, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HqPalette.purple.withValues(alpha: 0.2),
            HqPalette.purple.withValues(alpha: 0.01),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = HqPalette.purple
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, Paint()..color = HqPalette.purple);
      final t = TextPainter(
        text: TextSpan(
          text: '9/${22 + i}',
          style: const TextStyle(color: HqPalette.muted, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, Offset(points[i].dx - 12, plot.bottom + 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
