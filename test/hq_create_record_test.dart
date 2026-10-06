import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:step_seoul_app/hq/hq_create_record_dialog.dart';
import 'package:step_seoul_app/hq/hq_repository.dart';

void main() {
  testWidgets('registered districts cannot be selected and store is saved', (
    tester,
  ) async {
    Map<String, String>? saved;
    final repo = HqRepository(
      client: MockClient((request) async {
        expect(request.url.path, '/store/upload');
        saved = request.bodyFields;
        return http.Response('{"result":"CREATE OK"}', 200);
      }),
    );
    addTearDown(repo.close);
    await tester.pumpWidget(
      MaterialApp(
        home: HqCreateRecordDialog(
          repository: repo,
          type: 'store',
          occupiedDistricts: {'강남구'},
        ),
      ),
    );
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    final button = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>),
    );
    expect(
      button.items!.firstWhere((item) => item.value == '강남구').enabled,
      isFalse,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(dropdown, isNotNull);
    await tester.tap(find.text('종로구').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '새 대리점');
    await tester.tap(find.widgetWithText(FilledButton, '추가'));
    await tester.pumpAndSettle();
    expect(saved?['district_name'], '종로구');
    expect(saved?['agency_name'], '새 대리점');
    expect(saved?['store_id']?.length, lessThanOrEqualTo(20));
  });

  test('duplicate district response is reported clearly', () async {
    final repo = HqRepository(
      client: MockClient((_) async => http.Response('Conflict', 409)),
    );
    addTearDown(repo.close);
    await expectLater(
      repo.createMasterRecord('store', {'district_name': '강남구'}),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('이미 등록된 자치구'),
        ),
      ),
    );
  });
}
