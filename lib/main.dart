import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:step_seoul_app/view/auth/login.dart';
import 'package:step_seoul_app/view/auth/register.dart';
import 'package:step_seoul_app/view/auth/auth_gate.dart';
import 'package:step_seoul_app/view/customer/home.dart';
import 'package:get/get.dart';

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
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const AuthGate()),
        GetPage(name: '/login', page: () => const Login()),
        GetPage(name: '/register', page: () => const Register()),
        GetPage(
          name: '/customer/home',
          page: () => CustomerHome(initialTab: Get.arguments as int? ?? 0),
        ),
        // GetPage(name: '/employee/work_home', page: () => const EmployeeWorkHome()),
        // GetPage(name: '/executive/dashboard', page: () => const ExecutiveDashboard()),
      ],
    );
  }
}
