import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/customer_cart_service.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/customer/cart.dart';

const _shoe = CustomerShoe(
  id: 'airforce_white_m_280_00',
  name: '아주 긴 이름의 에어포스 화이트 테스트 상품',
  category: '러닝',
  imageUrl: null,
  price: '139000',
  stock: 40,
);

const _store = CustomerStore(
  id: 'store-1',
  name: 'STEP SEOUL 강남 플래그십 스토어',
  district: '강남구',
  phone: '02-1234-5678',
  latitude: null,
  longitude: null,
);

class _FakeCartService extends CustomerCartService {
  _FakeCartService()
    : item = CustomerCartItem(shoe: _shoe, cartIds: ['cart-1']);

  final CustomerCartItem item;

  CustomerCartData get data => CustomerCartData(
    userId: 'user-1',
    items: [item],
    stores: const [_store],
    selectedStore: _store,
  );

  @override
  Future<CustomerCartData> loadCart() async => data;

  @override
  Future<void> addShoe(CustomerShoe shoe, {int quantity = 1}) async {
    item.cartIds.add('cart-${item.cartIds.length + 1}');
  }

  @override
  Future<void> removeOne(CustomerCartData data, CustomerCartItem item) async {
    item.cartIds.removeLast();
  }

  @override
  Future<void> removeAll(CustomerCartData data, CustomerCartItem item) async {
    item.cartIds.clear();
  }
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('작은 화면에서 장바구니 카드와 하단 결제 바가 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(home: CartPage(service: _FakeCartService())),
    );
    await tester.pumpAndSettle();

    expect(find.text('장바구니'), findsOneWidget);
    expect(find.text('사이즈 280'), findsOneWidget);
    expect(find.text('1개 주문하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('수량 변경과 결제 이동에 실제 장바구니 수량을 사용한다', (tester) async {
    final service = _FakeCartService();
    CheckoutArguments? checkout;
    await tester.pumpWidget(
      GetMaterialApp(
        home: CartPage(service: service),
        getPages: [
          GetPage(
            name: AppRoutes.checkoutPayment,
            page: () {
              checkout = Get.arguments as CheckoutArguments;
              return const Scaffold(body: Text('결제 테스트'));
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('2개 주문하기'), findsOneWidget);

    await tester.tap(find.text('2개 주문하기'));
    await tester.pumpAndSettle();

    expect(checkout, isNotNull);
    expect(checkout!.items.single.shoe.id, _shoe.id);
    expect(checkout!.items.single.quantity, 2);
    expect(checkout!.store?.id, _store.id);
    expect(checkout!.clearCart, isTrue);
    expect(tester.takeException(), isNull);
  });
}
