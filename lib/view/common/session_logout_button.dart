import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/services/session_service.dart';

class SessionLogoutButton extends StatelessWidget {
  const SessionLogoutButton({super.key, this.labeled = false});
  final bool labeled;

  @override
  Widget build(BuildContext context) {
    Future<void> signOut() async {
      await SessionService.instance.clearSession();
      if (!context.mounted) return;
      Get.offAllNamed(AppRoutes.login);
    }

    if (labeled) {
      return OutlinedButton.icon(
        onPressed: signOut,
        icon: const Icon(Icons.logout_rounded),
        label: const Text('\uB85C\uADF8\uC544\uC6C3'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF4D60),
          side: const BorderSide(color: Color(0xFFFFE0E4)),
          backgroundColor: const Color(0xFFFFF4F5),
        ),
      );
    }
    return IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout_rounded),
      onPressed: signOut,
    );
  }
}
