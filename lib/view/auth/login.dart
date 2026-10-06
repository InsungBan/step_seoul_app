import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:step_seoul_app/routes/app_routes.dart';
import 'package:step_seoul_app/services/session_service.dart';
import 'package:step_seoul_app/services/api_config.dart';

const _apiBaseUrl = ApiConfig.baseUrl;
const _blue = Color(0xFF2F67E8);
const _navy = Color(0xFF102455);
const _muted = Color(0xFF71829C);

bool isExecutiveDepartment(Object? department) =>
    department?.toString().trim() == '\uBCF8\uC0AC';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _staySignedIn = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final destination = await _LoginRepository().signIn(
        id: _idController.text.trim(),
        password: _passwordController.text,
      );
      final role = switch (destination) {
        _LoginDestination.customer => UserRole.customer,
        _LoginDestination.employee => UserRole.employee,
        _LoginDestination.executive => UserRole.executive,
      };
      await SessionService.instance.saveSession(
        userId: _idController.text.trim(),
        role: role,
        persist: _staySignedIn,
      );
      if (!mounted) return;
      switch (destination) {
        case _LoginDestination.customer:
          Get.offAllNamed(AppRoutes.customerHome);
          return;
        case _LoginDestination.employee:
          Get.offAllNamed(AppRoutes.employeeWorkHome);
          return;
        case _LoginDestination.executive:
          Get.offAllNamed(
            AppRoutes.executiveDashboard,
            arguments: _idController.text.trim(),
          );
          return;
      }
    } on _LoginException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) => Get.snackbar(
    '\uB85C\uADF8\uC778 \uC2E4\uD328',
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFF25354E),
    colorText: Colors.white,
    margin: const EdgeInsets.all(20),
  );

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final heroHeight = isTablet ? 360.0 : 330.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 560 : double.infinity,
              ),
              child: Stack(
                children: [
                  _HeroArea(height: heroHeight, isTablet: isTablet),
                  Column(
                    children: [
                      SizedBox(height: heroHeight - 34),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 18,
                        ),
                        child: _LoginCard(
                          formKey: _formKey,
                          idController: _idController,
                          passwordController: _passwordController,
                          obscurePassword: _obscurePassword,
                          staySignedIn: _staySignedIn,
                          isLoading: _isLoading,
                          onPasswordVisibilityChanged: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onStaySignedInChanged: (value) =>
                              setState(() => _staySignedIn = value ?? false),
                          onLogin: _login,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 52 : 32,
                          26,
                          isTablet ? 52 : 32,
                          20,
                        ),
                        child: const _PickupNotice(),
                      ),
                      const Text(
                        '\uACE0\uAC1D\uC13C\uD130 1588-2026',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroArea extends StatelessWidget {
  const _HeroArea({required this.height, required this.isTablet});
  final double height;
  final bool isTablet;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_navy, Color(0xFF1D489C), Color(0xFF2058D6)],
      ),
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(isTablet ? 48 : 34),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(isTablet ? 48 : 34),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -65,
            top: -95,
            child: _GlowCircle(size: isTablet ? 310 : 250),
          ),
          Positioned(
            left: -92,
            bottom: -85,
            child: _GlowCircle(size: isTablet ? 300 : 245),
          ),
          Positioned(
            left: 34,
            top: 31,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP SEOUL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'ONLINE PICKUP',
                      style: TextStyle(
                        color: Color(0xFFAFC2EA),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: isTablet ? 86 : 78,
            child: Column(
              children: [
                SizedBox(
                  width: isTablet ? 270 : 235,
                  height: isTablet ? 150 : 135,
                  child: CustomPaint(painter: _ShoePainter()),
                ),
                const SizedBox(height: 2),
                const Text(
                  '\uC628\uB77C\uC778\uC73C\uB85C \uC8FC\uBB38\uD558\uACE0, \uAC00\uAE4C\uC6B4 \uB300\uB9AC\uC810\uC5D0\uC11C \uC218\uB839\uD558\uC138\uC694',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0x1FFFFFFF),
    ),
  );
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.idController,
    required this.passwordController,
    required this.obscurePassword,
    required this.staySignedIn,
    required this.isLoading,
    required this.onPasswordVisibilityChanged,
    required this.onStaySignedInChanged,
    required this.onLogin,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController idController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool staySignedIn;
  final bool isLoading;
  final VoidCallback onPasswordVisibilityChanged;
  final ValueChanged<bool?> onStaySignedInChanged;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A1A3C78),
          blurRadius: 22,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '\uB85C\uADF8\uC778',
            style: TextStyle(
              color: Color(0xFF16233D),
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\uC1FC\uD551\uACFC \uB300\uB9AC\uC810 \uC218\uB839\uC744 \uC2DC\uC791\uD558\uC138\uC694.',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 25),
          _InputField(
            controller: idController,
            label: '\uC544\uC774\uB514',
            hint: '\uC544\uC774\uB514 \uB610\uB294 \uC774\uBA54\uC77C',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter your ID.' : null,
          ),
          const SizedBox(height: 18),
          _InputField(
            controller: passwordController,
            label: '\uBE44\uBC00\uBC88\uD638',
            hint:
                '\uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter your password.' : null,
            suffixIcon: IconButton(
              onPressed: onPasswordVisibilityChanged,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: staySignedIn,
                  activeColor: _blue,
                  onChanged: onStaySignedInChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                '\uB85C\uADF8\uC778 \uC0C1\uD0DC \uC720\uC9C0',
                style: TextStyle(color: _muted, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  '\uBE44\uBC00\uBC88\uD638 \uCC3E\uAE30',
                  style: TextStyle(color: _blue, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '\uB85C\uADF8\uC778',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 23),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE5EBF5))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17),
                child: Text(
                  '\uCC98\uC74C \uBC29\uBB38\uD558\uC168\uB098\uC694?',
                  style: TextStyle(color: Color(0xFF9AAAC0), fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE5EBF5))),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.register),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('\uD68C\uC6D0\uAC00\uC785'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(57),
              foregroundColor: _blue,
              side: const BorderSide(color: Color(0xFFBDD4FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '\uB85C\uADF8\uC778\uD558\uBA74 \uC774\uC6A9\uC57D\uAD00 \uBC0F \uAC1C\uC778\uC815\uBCF4 \uCC98\uB9AC\uBC29\uCE68\uC5D0 \uB3D9\uC758\uD558\uAC8C \uB429\uB2C8\uB2E4.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AAAC0), fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFF596B85),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 9),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFA3B3C9)),
          prefixIcon: Icon(icon, color: const Color(0xFF71839E)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFF9FBFF),
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          border: _border(const Color(0xFFD8E3F4)),
          enabledBorder: _border(const Color(0xFFD8E3F4)),
          focusedBorder: _border(_blue),
        ),
      ),
    ],
  );
  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide(color: color, width: 1.2),
  );
}

class _PickupNotice extends StatelessWidget {
  const _PickupNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F1FF),
      borderRadius: BorderRadius.circular(17),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFD5E6FF),
          child: Icon(Icons.add_rounded, color: _blue, size: 25),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\uC11C\uC6B8 25\uAC1C \uC790\uCE58\uAD6C \uB300\uB9AC\uC810 \uC218\uB839',
                style: TextStyle(
                  color: Color(0xFF31599D),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '\uC628\uB77C\uC778 \uC8FC\uBB38 \uD6C4 \uC6D0\uD558\uB294 \uB300\uB9AC\uC810\uC744 \uC120\uD0DD\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
                style: TextStyle(color: Color(0xFF7187A9), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ShoePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shoe = Paint()..color = Colors.white;
    final shadow = Paint()..color = const Color(0x33000641);
    final line = Paint()
      ..color = const Color(0xFFAAD1FF)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * .026;
    final body = Path()
      ..moveTo(size.width * .10, size.height * .70)
      ..cubicTo(
        size.width * .13,
        size.height * .51,
        size.width * .32,
        size.height * .64,
        size.width * .48,
        size.height * .23,
      )
      ..cubicTo(
        size.width * .55,
        size.height * .53,
        size.width * .72,
        size.height * .53,
        size.width * .86,
        size.height * .65,
      )
      ..cubicTo(
        size.width * .96,
        size.height * .72,
        size.width * .93,
        size.height * .89,
        size.width * .89,
        size.height * .90,
      )
      ..lineTo(size.width * .16, size.height * .90)
      ..cubicTo(
        size.width * .07,
        size.height * .88,
        size.width * .06,
        size.height * .79,
        size.width * .10,
        size.height * .70,
      )
      ..close();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .58, size.height * .92),
        width: size.width * .78,
        height: size.height * .17,
      ),
      shadow,
    );
    canvas.drawPath(body, shoe);
    canvas.drawLine(
      Offset(size.width * .42, size.height * .43),
      Offset(size.width * .65, size.height * .60),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .34, size.height * .60),
      Offset(size.width * .57, size.height * .76),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .23, size.height * .78),
      Offset(size.width * .78, size.height * .78),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .14, size.height * .89),
      Offset(size.width * .82, size.height * .89),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum _LoginDestination { customer, employee, executive }

class _LoginException implements Exception {
  const _LoginException(this.message);
  final String message;
}

class _LoginRepository {
  Future<_LoginDestination> signIn({
    required String id,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_apiBaseUrl/authentication/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'account_id': id, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    // 1. 일반 고객(User) 체크
    if (response.statusCode == 401) {
      throw const _LoginException('Invalid ID or password.');
    }
    if (response.statusCode != 200) {
      throw const _LoginException('Could not sign in.');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final result = decoded is Map ? decoded['result'] : null;
    final role = result is Map ? result['role']?.toString() : null;
    return switch (role) {
      'customer' => _LoginDestination.customer,
      'employee' => _LoginDestination.employee,
      'executive' => _LoginDestination.executive,
      _ => throw const _LoginException('Invalid login response.'),
    };
  }
}
