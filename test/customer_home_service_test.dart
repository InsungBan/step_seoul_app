import 'package:flutter_test/flutter_test.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';

CustomerShoe _shoe(String id, {int stock = 10}) => CustomerShoe(
  id: id,
  name: id,
  category: '러닝',
  imageUrl: null,
  price: '100000',
  stock: stock,
);

void main() {
  test('같은 제품, 색상, 성별의 사이즈는 대표 카드 하나로 묶는다', () {
    final grouped = groupShoeSizeVariants([
      _shoe('airforce_white_m_250_00'),
      _shoe('airforce_white_m_280_00'),
      _shoe('airforce_white_m_290_00'),
      _shoe('airforce_black_m_280_00'),
      _shoe('sneakers_black_m_250_00'),
      _shoe('sneakers_black_m_280_00'),
    ]);

    expect(grouped.map((shoe) => shoe.id), [
      'airforce_white_m_280_00',
      'airforce_black_m_280_00',
      'sneakers_black_m_280_00',
    ]);
  });

  test('280 사이즈가 품절이면 재고가 있는 사이즈를 대표로 사용한다', () {
    final grouped = groupShoeSizeVariants([
      _shoe('airforce_white_m_280_00', stock: 0),
      _shoe('airforce_white_m_260_00', stock: 5),
    ]);

    expect(grouped.single.id, 'airforce_white_m_260_00');
  });

  test('색상과 성별이 다르거나 사이즈 형식이 아니면 별도 카드로 유지한다', () {
    final grouped = groupShoeSizeVariants([
      _shoe('airforce_white_m_280_00'),
      _shoe('airforce_white_f_280_00'),
      _shoe('airforce_black_m_280_00'),
      _shoe('legacy_shoe'),
    ]);

    expect(grouped, hasLength(4));
  });
}
