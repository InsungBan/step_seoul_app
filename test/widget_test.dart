import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:step_seoul_app/hq/hq_console.dart';
import 'package:step_seoul_app/hq/hq_repository.dart';
import 'package:step_seoul_app/hq/hq_view_data.dart';

Map<String, dynamic> snapshot() => {
  for (final t in [
    'shoe',
    'purchase',
    'shipment',
    'receive',
    'return_record',
    'approval',
    'approval_process',
    'purchase_order',
    'get_order',
    'payment',
    'user',
    'employee',
    'store',
    'shoe_manufacturer',
    'manufacturing',
    'recall',
    'refund',
  ])
    t: <dynamic>[],
};
Map<String, dynamic> records() {
  final data = snapshot();
  final now = DateTime.now().toIso8601String();
  data['shoe'] = [
    {
      'shoe_id': 's1',
      'brand_name': 'DB 상품',
      'shoe_price': '89000',
      'stock_quantity': 5,
      'standard_stock': 20,
    },
  ];
  data['purchase'] = [
    {
      'purchase_id': 'p1',
      'shoe_shoe_id': 's1',
      'quantity': '2',
      'sale_price': '89000',
      'payment_id': 'pay1',
      'user_user_id': 'u1',
      'store_store_id': 'st1',
    },
  ];
  data['payment'] = [
    {
      'payment_id': 'pay1',
      'payment_amount': 178000,
      'payment_status': 1,
      'payment_date': now,
    },
  ];
  data['user'] = [
    {'user_id': 'u1', 'user_name': 'DB 고객', 'user_phone': '01012345678'},
  ];
  data['store'] = [
    {
      'store_id': 'st1',
      'agency_name': 'DB 대리점',
      'district_name': '강남구',
      'phone': '0212345678',
    },
  ];
  data['receive'] = [
    {
      'receive_id': 'rv1',
      'receive_payment_id': 'pay1',
      'user_user_id': 'u1',
      'store_store_id': 'st1',
      'receive_status': '수령완료',
      'receive_date': now,
    },
  ];
  data['approval'] = [
    {
      'approval_id': 'a1',
      'approval_name': 'DB 품의',
      'approval_content': 'DB 사유',
    },
  ];
  data['approval_process'] = [
    {
      'approval_process_id': 'ap1',
      'approval_approval_id': 'a1',
      'approval_status': '승인',
      'team_leader_approval': '승인',
      'director_approval': '승인',
    },
  ];
  data['purchase_order'] = [
    {
      'order_id': 'po1',
      'shoe_shoe_id': 's1',
      'order_quantity': '10',
      'get_amount': '890000',
      'order_date': now,
    },
  ];
  data['hq_reports'] = [
    {
      'final-approvals': {
        'available': true,
        'result': [
          {
            'approval_id': 'a2',
            'approval_name': '최종 승인 요청',
            'approval_status': '결재대기',
            'employee_name': 'DB 직원',
          },
        ],
      },
      'completed-receipts': {'available': true, 'result': data['receive']},
      'auto-order-targets': {'available': true, 'result': data['shoe']},
      'inventory-by-category': {
        'available': true,
        'result': [
          {'category': '러닝화', 'quantity': 5},
        ],
      },
      'sales-by-category': {
        'available': true,
        'result': [
          {'category': '러닝화', 'amount': 178000},
        ],
      },
    },
  ];
  return data;
}

http.Response response(Map<String, dynamic> data) => http.Response(
  jsonEncode({'result': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  testWidgets('Reference layout, DB details, missing cells and tablet widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = HqRepository(
      client: MockClient((_) async => response(records())),
    );
    addTearDown(repo.close);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundary,
          child: HqConsole(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('本社'), findsNothing);
    expect(find.text('본사 임원 대시보드'), findsOneWidget);
    expect(find.text('최근 7일 판매금액'), findsOneWidget);
    expect(find.text('최종 승인 요청'), findsOneWidget);
    expect(find.text('178,000원'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build').create(recursive: true);
      await File(
        'build/hq_dashboard_preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.text('주문 · 배송').first);
    await tester.pumpAndSettle();
    expect(find.text('DB 고객'), findsOneWidget);
    expect(find.text('주문 처리 흐름'), findsNothing);
    expect(find.text('DB 대리점'), findsOneWidget);
    await tester.tap(find.text('상세보기').first);
    await tester.pumpAndSettle();
    expect(find.text('주문 상세'), findsOneWidget);
    expect(find.text('고객 정보'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('목록으로 돌아가기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '없는 상품');
    await tester.pumpAndSettle();
    expect(find.text('DB 상품'), findsNothing);
    for (final title in ['전체 재고', '품의 관리', '발주 · 수주', '판매 현황', '기준 정보']) {
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: title);
    }
    await tester.tap(find.text('전체 재고').first);
    await tester.pumpAndSettle();
    expect(find.text('대리점별 재고'), findsNothing);
    expect(find.text('재고 변동 이력'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text(hqMissing), findsWidgets);
    expect(find.text('DB 대리점'), findsNothing);
    for (final size in [
      const Size(1280, 800),
      const Size(800, 1280),
      const Size(390, 844),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size');
      if (size.width == 390) {
        for (final name in [
          '대시보드',
          '주문 · 배송',
          '품의 관리',
          '발주 · 수주',
          '판매 현황',
          '기준 정보',
        ]) {
          await tester.ensureVisible(find.byIcon(Icons.menu));
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();
          await tester.tap(find.text(name).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'phone $name');
        }
      }
    }
  });
  testWidgets('Proposal saves actual title and reason through CRUD', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var saved = false;
    final repo = HqRepository(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          expect(request.url.path, '/approval/upload');
          expect(request.bodyFields['approval_name'], '새 품의');
          expect(request.bodyFields['approval_content'], '재고 확보');
          expect(
            request.bodyFields['approval_id']!.length,
            lessThanOrEqualTo(20),
          );
          saved = true;
          return http.Response('{"result":"CREATE OK"}', 200);
        }
        return response(records());
      }),
    );
    addTearDown(repo.close);
    await tester.pumpWidget(MaterialApp(home: HqConsole(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('품의 관리').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '품의서 작성'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '새 품의');
    await tester.enterText(find.byType(TextField).at(1), '재고 확보');
    await tester.ensureVisible(find.text('품의 저장'));
    await tester.tap(find.text('품의 저장'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Failed API shows retry, successful empty API shows missing data',
    (tester) async {
      var calls = 0;
      final repo = HqRepository(
        client: MockClient(
          (_) async => ++calls == 1
              ? http.Response('offline', 503)
              : response(snapshot()),
        ),
      );
      addTearDown(repo.close);
      await tester.pumpWidget(MaterialApp(home: HqConsole(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('연결 오류'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('연결 오류'), findsNothing);
      expect(find.text(hqMissing), findsWidgets);
      expect(find.text('0원'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'Receipt join does not guess between several receipts; rankings exclude unpaid purchases',
    () {
      final tables = records().map(
        (k, v) => MapEntry(
          k,
          (v as List).map((r) => Map<String, dynamic>.from(r as Map)).toList(),
        ),
      );
      final db = HqViewData(tables);
      expect(db.receipt(db.rows('purchase').first)?['receive_id'], 'rv1');
      tables['receive']!.add({
        ...tables['receive']!.first,
        'receive_id': 'rv2',
      });
      expect(db.receipt(db.rows('purchase').first), isNull);
      tables['purchase']!.add({
        'shoe_shoe_id': 's2',
        'quantity': '100',
        'sale_price': '10000',
        'payment_id': 'unpaid',
      });
      final now = DateTime.now();
      final top = db.bestProducts(
        DateTime(now.year, now.month),
        now.add(const Duration(days: 1)),
      );
      expect(top.length, 1);
      expect(top.first['amount'], 178000);
    },
  );
}
