import 'package:flutter_test/flutter_test.dart';
import 'package:step_seoul_app/view/auth/login.dart';

void main() {
  test('본사 부서만 임원으로 판정한다', () {
    expect(isExecutiveDepartment('본사'), isTrue);
    expect(isExecutiveDepartment('  본사  '), isTrue);

    expect(isExecutiveDepartment('강남대리점'), isFalse);
    expect(isExecutiveDepartment('영업본부'), isFalse);
    expect(isExecutiveDepartment(''), isFalse);
    expect(isExecutiveDepartment(null), isFalse);
  });
}
