import 'package:flutter_test/flutter_test.dart';
import 'package:step_seoul_app/hq/hq_view_data.dart';

void main() {
  final db = HqViewData({});
  test('shoe code extracts color and size from the end', () {
    expect(db.shoeCodeOptions('airforce_black_m_280_00'), {
      'color': 'black',
      'size': '280',
    });
    expect(db.shoeCodeOptions('air_force_white_f_240_01'), {
      'color': 'white',
      'size': '240',
    });
  });
  test('missing or malformed code has no options', () {
    for (final code in [
      null,
      's1',
      'airforce__m_280_00',
      'airforce_black_m_unknown_00',
    ]) {
      expect(db.shoeCodeOptions(code), isNull);
    }
  });
}
