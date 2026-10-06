import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/services/product_variant_service.dart';
import 'package:step_seoul_app/view/customer/product_detail.dart';
import 'package:step_seoul_app/view/customer/shoe_image.dart';

const _blackId = 'airforce_black_m_280_00';
const _whiteId = 'airforce_white_m_280_00';

Map<String, dynamic> _shoeRow(
  String id, {
  String name = '에어포스 검정',
  String price = '10000',
  int stock = 3,
  String? imageUrl,
}) => {
  'shoe_id': id,
  'brand_name': name,
  'shoe_category': '스니커즈',
  'shoe_img_url': imageUrl,
  'shoe_price': price,
  'stock_quantity': stock,
};

Finder _color(String code) => find.byKey(ValueKey('product-color-$code'));

Finder _selectionSummary(String color, String size) =>
    find.textContaining('선택: $color · $size · 1개');

Future<void> _pumpProductDetail(
  WidgetTester tester,
  List<Map<String, dynamic>> rows, {
  required CustomerShoe selected,
  void Function(CheckoutArguments)? onCheckout,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final client = MockClient((request) async {
    expect(request.method, 'GET');
    expect(request.url.path, '/shoe/search');
    expect(request.url.queryParameters['query'], 'airforce');
    return http.Response.bytes(utf8.encode(jsonEncode({'result': rows})), 200);
  });
  addTearDown(client.close);
  await tester.pumpWidget(
    GetMaterialApp(
      home: ProductDetail(
        shoe: selected,
        variantService: ProductVariantService(client: client),
      ),
      getPages: [
        GetPage(
          name: AppRoutes.checkoutPayment,
          page: () {
            onCheckout?.call(Get.arguments as CheckoutArguments);
            return const Scaffold(body: Text('Checkout test page'));
          },
        ),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const databaseChannel = MethodChannel('com.tekartik.sqflite');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  DatabaseFactory? originalFactory;

  setUpAll(() {
    originalFactory = databaseFactoryOrNull;
    databaseFactory = databaseFactorySqflitePlugin;
    messenger.setMockMethodCallHandler(databaseChannel, (call) async {
      switch (call.method) {
        case 'getDatabasesPath':
          return '.';
        case 'openDatabase':
          return {'id': 1};
        case 'query':
          final sql = (call.arguments as Map)['sql'] as String;
          return [
            if (sql == 'PRAGMA user_version') {'user_version': 1},
          ];
        case 'execute':
        case 'options':
        case 'closeDatabase':
          return null;
        default:
          throw UnsupportedError('Unexpected database method: ${call.method}');
      }
    });
  });
  tearDownAll(() {
    messenger.setMockMethodCallHandler(databaseChannel, null);
    databaseFactoryOrNull = originalFactory;
  });
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('single black SKU shows only its actual black color', (
    tester,
  ) async {
    final blackRow = _shoeRow(_blackId);
    await _pumpProductDetail(tester, [
      blackRow,
    ], selected: CustomerShoe.fromJson(blackRow));

    expect(_color('black'), findsOneWidget);
    for (final code in ['white', 'offwhite', 'navy', 'gray']) {
      expect(_color(code), findsNothing);
    }
    expect(_selectionSummary('검정', '280'), findsOneWidget);
    for (final label in ['오프화이트', '네이비', '그레이']) {
      expect(find.text(label), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('colors are unique actual options from the current shoe family', (
    tester,
  ) async {
    final blackRow = _shoeRow(_blackId);
    await _pumpProductDetail(tester, [
      blackRow,
      _shoeRow('airforce_black_m_270_00'),
      _shoeRow('airforce_black_f_250_01'),
      _shoeRow(_whiteId, name: '에어포스 흰색'),
      _shoeRow('nike_red_m_280_00', name: '다른 상품 빨강'),
    ], selected: CustomerShoe.fromJson(blackRow));

    expect(_color('black'), findsOneWidget);
    expect(_color('white'), findsOneWidget);
    expect(_color('red'), findsNothing);
    expect(_color('navy'), findsNothing);
    expect(_color('gray'), findsNothing);
    expect(_selectionSummary('검정', '280'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('white selection changes the displayed SKU and checkout item', (
    tester,
  ) async {
    final blackRow = _shoeRow(_blackId);
    final whiteRow = _shoeRow(
      _whiteId,
      name: '에어포스 흰색 실제 상품',
      price: '22000',
      stock: 7,
      imageUrl: 'https://example.invalid/airforce-white.png',
    );
    CheckoutArguments? checkout;
    await _pumpProductDetail(
      tester,
      [
        blackRow,
        _shoeRow('airforce_white_f_250_00', name: '다른 성별과 사이즈 흰색'),
        _shoeRow('airforce_white_m_270_00', name: '다른 사이즈 흰색'),
        whiteRow,
        _shoeRow('nike_red_m_280_00'),
      ],
      selected: CustomerShoe.fromJson(blackRow),
      onCheckout: (arguments) => checkout = arguments,
    );

    await tester.tap(_color('white'));
    await tester.pumpAndSettle();

    expect(find.text('에어포스 흰색 실제 상품'), findsOneWidget);
    expect(find.text('에어포스 검정'), findsNothing);
    expect(find.textContaining(_whiteId), findsOneWidget);
    expect(find.text('22000원'), findsOneWidget);
    expect(find.textContaining('재고 7개'), findsOneWidget);
    expect(_selectionSummary('흰색', '280'), findsOneWidget);
    expect(
      tester.widget<ShoeImage>(find.byType(ShoeImage)).imageUrl,
      whiteRow['shoe_img_url'],
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.checkoutPayment);
    expect(checkout, isNotNull);
    expect(checkout!.items.single.shoe.id, _whiteId);
    expect(checkout!.items.single.shoe.name, whiteRow['brand_name']);
    expect(checkout!.items.single.shoe.price, '22000');
    expect(checkout!.items.single.shoe.stock, 7);
    expect(checkout!.items.single.shoe.imageUrl, whiteRow['shoe_img_url']);
    expect(checkout!.items.single.quantity, 1);
    expect(checkout!.clearCart, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selecting a sold out color disables purchase for its actual SKU',
    (tester) async {
      final blackRow = _shoeRow(_blackId);
      await _pumpProductDetail(tester, [
        blackRow,
        _shoeRow(_whiteId, name: '품절된 흰색 상품', stock: 0),
      ], selected: CustomerShoe.fromJson(blackRow));
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );

      await tester.tap(_color('white'));
      await tester.pumpAndSettle();

      expect(find.text('품절된 흰색 상품'), findsOneWidget);
      expect(find.text('품절'), findsOneWidget);
      expect(_selectionSummary('흰색', '280'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
