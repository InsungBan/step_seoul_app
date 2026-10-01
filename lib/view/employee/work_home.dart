import 'package:flutter/material.dart';
import 'package:step_seoul_app/view/common/session_logout_button.dart';

class WorkHome extends StatelessWidget {
  const WorkHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Employee Work Home'),
      actions: const [SessionLogoutButton()],
    ),
    body: const Center(child: Text('Employee Work Home')),
  );
}
