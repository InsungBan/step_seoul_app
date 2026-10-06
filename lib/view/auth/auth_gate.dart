import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/services/session_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _redirectToSession();
    });
  }

  Future<void> _redirectToSession() async {
    AppSession? session;
    try {
      session = await SessionService.instance.readSession();
    } catch (_) {
      session = null;
    }
    if (!mounted) return;
    Get.offAllNamed(switch (session?.role) {
      UserRole.customer => AppRoutes.customerHome,
      UserRole.employee => AppRoutes.employeeWorkHome,
      UserRole.executive => AppRoutes.executiveDashboard,
      null => AppRoutes.login,
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
