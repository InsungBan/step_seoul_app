import 'package:flutter/material.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/auth/login.dart';
import 'package:step_seoul_app/view/customer/home.dart';
import 'package:step_seoul_app/view/employee/work_home.dart';
import 'package:step_seoul_app/view/executive/executive_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<AppSession?>(
    future: SessionService.instance.readSession(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final session = snapshot.data;
      if (session == null) return const Login();
      return switch (session.role) {
        UserRole.customer => const CustomerHome(),
        UserRole.employee => const WorkHome(),
        UserRole.executive => const ExecutiveDashboard(),
      };
    },
  );
}
