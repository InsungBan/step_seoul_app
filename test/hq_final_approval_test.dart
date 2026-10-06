import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:step_seoul_app/hq/hq_repository.dart';

void main() {
  final row = <String, dynamic>{
    'employee_employee_id': 'e1',
    'approval_approval_id': 'a1',
    'approval_process_id': 'p1',
  };

  test(
    'final approval updates the selected process and completion status',
    () async {
      final repository = HqRepository(
        client: MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, '/approval_process/update/e1/a1/p1');
          expect(request.bodyFields['director_approval'], '승인');
          expect(request.bodyFields['approval_status'], '승인완료');
          expect(
            DateTime.tryParse(request.bodyFields['processed_at']!),
            isNotNull,
          );
          expect(
            request.bodyFields.containsKey('team_leader_approval'),
            isFalse,
          );
          return http.Response(jsonEncode({'result': 'UPDATE OK'}), 200);
        }),
      );
      addTearDown(repository.close);
      await repository.approveFinal(row);
    },
  );

  test('missing process identity cannot send an approval', () async {
    final repository = HqRepository(
      client: MockClient((request) async {
        fail('Incomplete identity must not send a request');
      }),
    );
    addTearDown(repository.close);
    await expectLater(repository.approveFinal({}), throwsFormatException);
  });

  test('failed approval is reported to the caller', () async {
    final repository = HqRepository(
      client: MockClient((request) async => http.Response('Conflict', 409)),
    );
    addTearDown(repository.close);
    await expectLater(repository.approveFinal(row), throwsException);
  });
}
