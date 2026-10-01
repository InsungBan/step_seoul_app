import 'package:flutter/material.dart';
import 'package:step_seoul_app/view/common/session_logout_button.dart';

class ExecutiveDashboard extends StatelessWidget {
  const ExecutiveDashboard({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Executive Dashboard'),
      actions: const [SessionLogoutButton()],
    ),
    body: const Center(child: Text('Executive Dashboard')),
  );
}
