import 'package:flutter/material.dart';
import 'package:step_seoul_app/view/common/session_logout_button.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Customer Home'),
      actions: const [SessionLogoutButton()],
    ),
    body: const Center(child: Text('Customer Home')),
  );
}
