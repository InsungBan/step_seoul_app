import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/view/auth/login.dart';

class SessionLogoutButton extends StatelessWidget {
  const SessionLogoutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Sign out',
    icon: const Icon(Icons.logout_rounded),
    onPressed: () async {
      await SessionService.instance.clearSession();
      Get.offAll(() => const Login());
    },
  );
}
