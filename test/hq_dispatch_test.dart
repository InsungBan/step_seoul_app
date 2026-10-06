import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:step_seoul_app/hq/hq_console.dart';
import 'package:step_seoul_app/hq/hq_repository.dart';
import 'widget_test.dart' as fixtures;

void main() {
  testWidgets('selected shipments are dispatched through the update API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final data = fixtures.records();
    final shipments = [
      for (final id in ['sh1', 'sh2'])
        {
          'shoe_shoe_id': 's1',
          'employee_employee_id': 'e1',
          'shipment_id': id,
          'store_store_id': 'st1',
          'delivery_status': '출고 대기중',
        },
    ];
    data['shipment'] = shipments;
    var updated = false;
    final repo = HqRepository(
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          expect(request.url.path, '/shipment/dispatch');
          final body = jsonDecode(request.body) as Map;
          expect((body['shipments'] as List).length, 2);
          for (final row in shipments) {
            row['delivery_status'] = '배송 중';
          }
          updated = true;
          return http.Response('{"result":"UPDATE OK"}', 200);
        }
        return fixtures.response(data);
      }),
    );
    addTearDown(repo.close);
    await tester.pumpWidget(MaterialApp(home: HqConsole(repository: repo)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주문 · 배송').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('배송 현황').first);
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      await tester.ensureVisible(find.byType(Checkbox).at(index));
      await tester.tap(find.byType(Checkbox).at(index));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('배송 (2)'));
    await tester.tap(find.text('배송 (2)'));
    await tester.pumpAndSettle();
    expect(updated, isTrue);
    expect(find.text('배송 중'), findsNWidgets(2));
    expect(find.text('배송 (0)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
