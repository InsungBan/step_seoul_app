import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/routes/route_arguments.dart';
import 'package:step_seoul_app/services/checkout_service.dart';
import 'package:step_seoul_app/services/customer_home_service.dart';
import 'package:step_seoul_app/view/auth/login.dart';
import 'package:step_seoul_app/view/auth/register.dart';
import 'package:step_seoul_app/view/auth/auth_gate.dart';
import 'package:step_seoul_app/view/customer/branch_detail.dart';
import 'package:step_seoul_app/view/customer/branch_directions.dart';
import 'package:step_seoul_app/view/customer/branch_list.dart';
import 'package:step_seoul_app/view/customer/cart.dart';
import 'package:step_seoul_app/view/customer/checkout_payment.dart';
import 'package:step_seoul_app/view/customer/home.dart';
import 'package:step_seoul_app/view/customer/order_complete.dart';
import 'package:step_seoul_app/view/customer/order_detail.dart';
import 'package:step_seoul_app/view/customer/product_detail.dart';
import 'package:step_seoul_app/view/customer/product_list.dart';
import 'package:step_seoul_app/view/customer/profile_edit.dart';
import 'package:step_seoul_app/view/customer/return_request.dart';
import 'package:step_seoul_app/view/employee/work_home.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'STEP SEOUL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFA7B8DA), // 배경 파스텔 톤
        fontFamily: 'Pretendard',
      ),
      initialRoute: AppRoutes.authGate,
      getPages: [
        GetPage(name: AppRoutes.authGate, page: () => const AuthGate()),
        GetPage(name: AppRoutes.login, page: () => const Login()),
        GetPage(name: AppRoutes.register, page: () => const Register()),
        GetPage(
          name: AppRoutes.customerHome,
          page: () => CustomerHome(initialTab: Get.arguments as int? ?? 0),
        ),
        GetPage(
          name: AppRoutes.productList,
          page: () => ProductList(shoes: Get.arguments as List<CustomerShoe>),
        ),
        GetPage(
          name: AppRoutes.productDetail,
          page: () => ProductDetail(shoe: Get.arguments as CustomerShoe),
        ),
        GetPage(name: AppRoutes.cart, page: () => const CartPage()),
        GetPage(
          name: AppRoutes.checkoutPayment,
          page: () {
            final arguments = Get.arguments as CheckoutArguments;
            return CheckoutPaymentPage(
              items: arguments.items,
              store: arguments.store,
              clearCart: arguments.clearCart,
            );
          },
        ),
        GetPage(
          name: AppRoutes.orderComplete,
          page: () =>
              OrderCompletePage(receipt: Get.arguments as CheckoutReceipt),
        ),
        GetPage(
          name: AppRoutes.orderDetail,
          page: () => OrderDetailPage(orderId: Get.arguments as String),
        ),
        GetPage(
          name: AppRoutes.returnRequest,
          page: () => ReturnRequestPage(order: Get.arguments as CustomerOrder),
        ),
        GetPage(
          name: AppRoutes.profileEdit,
          page: () => const ProfileEditPage(),
        ),
        GetPage(
          name: AppRoutes.branchList,
          page: () {
            final arguments = Get.arguments as BranchListArguments;
            return BranchListPage(
              stores: arguments.stores,
              selectedStoreId: arguments.selectedStoreId,
            );
          },
        ),
        GetPage(
          name: AppRoutes.branchDetail,
          page: () => BranchDetailPage(store: Get.arguments as CustomerStore),
        ),
        GetPage(
          name: AppRoutes.branchDirections,
          page: () =>
              BranchDirectionsPage(store: Get.arguments as CustomerStore),
        ),
        GetPage(name: AppRoutes.employeeWorkHome, page: () => const WorkHome()),
        GetPage(
          name: AppRoutes.executiveDashboard,
          page: () => const HqConsole(),
        ),
      ],
    );
  }
}
