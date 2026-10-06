import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:step_seoul_app/main.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/hq/hq_console.dart';
import 'package:step_seoul_app/view/auth/login.dart';
import 'package:step_seoul_app/view/auth/register.dart';
import 'package:step_seoul_app/view/customer/branch_list.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';
import 'package:step_seoul_app/view/customer/product_detail.dart';
import 'package:step_seoul_app/view/customer/product_list.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const databaseChannel = MethodChannel('com.tekartik.sqflite');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  DatabaseFactory? originalFactory;
  String? role;

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
          if (sql == 'PRAGMA user_version') {
            return [
              {'user_version': 1},
            ];
          }
          return [
            if (sql.contains('app_session') && role != null)
              {'user_id': 'test-user', 'role': role},
          ];
        case 'execute':
        case 'options':
        case 'closeDatabase':
          return null;
        case 'insert':
          return 1;
        default:
          throw UnsupportedError('Unexpected database method: ${call.method}');
      }
    });
  });
  tearDownAll(() {
    messenger.setMockMethodCallHandler(databaseChannel, null);
    databaseFactoryOrNull = originalFactory;
  });
  setUp(() {
    Get.testMode = true;
    role = null;
  });
  tearDown(Get.reset);

  testWidgets('저장된 세션이 없으면 로그인 경로로 이동한다', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(find.byType(Login), findsOneWidget);
    expect(Get.key.currentState!.canPop(), isFalse);
  });

  testWidgets('회원가입 버튼과 뒤로 가기가 등록 경로를 사용한다', (tester) async {
    await _pumpLogin(tester);
    await tester.ensureVisible(find.text('회원가입'));
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.register);
    expect(find.byType(Register), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.login);
    expect(find.byType(Login), findsOneWidget);
  });

  testWidgets('상품과 결제 항목을 이름 기반 경로에 전달한다', (tester) async {
    await _pumpLogin(tester);
    const shoe = CustomerShoe(
      id: 'shoe-1',
      name: '테스트 운동화',
      category: '운동화',
      imageUrl: null,
      price: '10000',
      stock: 3,
    );
    Get.toNamed(AppRoutes.productList, arguments: [shoe]);
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.productList);
    expect(
      tester.widget<ProductList>(find.byType(ProductList)).shoes.single,
      shoe,
    );
    await tester.tap(find.text(shoe.name));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.productDetail);
    expect(tester.widget<ProductDetail>(find.byType(ProductDetail)).shoe, shoe);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final checkout = tester.widget<CheckoutPaymentPage>(
      find.byType(CheckoutPaymentPage),
    );
    expect(Get.currentRoute, AppRoutes.checkoutPayment);
    expect(checkout.items.single.shoe, shoe);
    expect(checkout.items.single.quantity, 1);
    expect(checkout.clearCart, isFalse);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.productDetail);
  });

  testWidgets('지점 목록으로 전달한 데이터를 선택 결과로 돌려준다', (tester) async {
    await _pumpLogin(tester);
    role = 'customer';
    const store = CustomerStore(
      id: 'store-1',
      name: '강남점',
      district: '강남구',
      phone: '02-1234-5678',
      latitude: null,
      longitude: null,
    );
    final result = Get.toNamed(
      AppRoutes.branchList,
      arguments: const BranchListArguments(stores: [store]),
    );
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.branchList);
    expect(
      tester.widget<BranchListPage>(find.byType(BranchListPage)).stores.single,
      store,
    );

    await tester.tap(find.text('지점 선택'));
    await tester.pumpAndSettle();

    expect(await result, store);
    expect(Get.currentRoute, AppRoutes.login);
  });

  testWidgets('저장된 임원 세션은 임원 홈 경로로 이동한다', (tester) async {
    role = 'executive';
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.executiveDashboard);
    expect(find.byType(HqConsole), findsOneWidget);
    expect(Get.key.currentState!.canPop(), isFalse);
  });
}

Future<void> _pumpLogin(WidgetTester tester) async {
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final app = const MyApp().build(context) as GetMaterialApp;
        return GetMaterialApp(
          initialRoute: AppRoutes.login,
          getPages: app.getPages,
          theme: app.theme,
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}
