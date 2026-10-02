import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:step_seoul_app/view/auth/login.dart';

const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.10.40:8000',
);
const _blue = Color(0xFF2F67E8);
const _navy = Color(0xFF102455);
const _fieldBorder = Color(0xFFD8E3F4);

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _agreedToTerms = false;
  bool _isCheckingId = false;
  bool _isSubmitting = false;
  String? _verifiedId;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _checkId() async {
    final id = _idController.text.trim();
    if (!RegExp(r'^[a-zA-Z0-9]{4,12}$').hasMatch(id)) {
      _message('ID must contain 4-12 English letters or numbers.');
      return;
    }
    setState(() {
      _isCheckingId = true;
      _verifiedId = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$_apiBaseUrl/user/select'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw const _RegisterException('Could not check ID availability.');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final records = decoded is Map<String, dynamic>
          ? decoded['result']
          : null;
      final exists =
          records is List &&
          records.any((row) => row is Map && row['user_id']?.toString() == id);
      if (!mounted) return;
      if (exists) {
        _message(
          '\uC774\uBBF8 \uC0AC\uC6A9 \uC911\uC778 \uC544\uC774\uB514\uC785\uB2C8\uB2E4.',
        );
      } else {
        setState(() => _verifiedId = id);
        _message(
          '\uC0AC\uC6A9 \uAC00\uB2A5\uD55C \uC544\uC774\uB514\uC785\uB2C8\uB2E4.',
          success: true,
        );
      }
    } on _RegisterException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _isCheckingId = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_verifiedId != _idController.text.trim()) {
      _message(
        '\uC544\uC774\uB514 \uC911\uBCF5 \uD655\uC778\uC744 \uD574 \uC8FC\uC138\uC694.',
      );
      return;
    }
    if (!_agreedToTerms) {
      _message(
        '\uD544\uC218 \uC57D\uAD00\uC5D0 \uB3D9\uC758\uD574 \uC8FC\uC138\uC694.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final request =
          http.MultipartRequest('POST', Uri.parse('$_apiBaseUrl/user/upload'))
            ..fields['user_id'] = _idController.text.trim()
            ..fields['user_name'] = _nameController.text.trim()
            ..fields['user_phone'] = _phoneController.text.trim()
            ..fields['user_pw'] = _passwordController.text;
      final response = await request.send().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        throw const _RegisterException(
          'Registration failed. Please try again.',
        );
      }
      if (!mounted) return;
      Get.offAll(() => const Login());
      Get.snackbar(
        '\uAC00\uC785 \uC644\uB8CC',
        '\uD68C\uC6D0\uAC00\uC785\uC774 \uC644\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4. \uB85C\uADF8\uC778\uD574 \uC8FC\uC138\uC694.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF25354E),
        colorText: Colors.white,
        margin: const EdgeInsets.all(20),
      );
    } on _RegisterException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Unable to connect to the server.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _message(String text, {bool success = false}) => Get.snackbar(
    success ? '\uC54C\uB9BC' : '\uD655\uC778 \uD544\uC694',
    text,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: success
        ? const Color(0xFF1E7547)
        : const Color(0xFF25354E),
    colorText: Colors.white,
    margin: const EdgeInsets.all(20),
  );

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final heroHeight = isTablet ? 286.0 : 252.0;
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
                  _RegisterHero(height: heroHeight, isTablet: isTablet),
                  Column(
                    children: [
                      SizedBox(height: heroHeight - 25),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 32 : 18,
                        ),
                        child: _RegisterCard(
                          formKey: _formKey,
                          nameController: _nameController,
                          idController: _idController,
                          phoneController: _phoneController,
                          passwordController: _passwordController,
                          passwordConfirmController: _passwordConfirmController,
                          obscurePassword: _obscurePassword,
                          obscureConfirmation: _obscureConfirmation,
                          agreedToTerms: _agreedToTerms,
                          isCheckingId: _isCheckingId,
                          isSubmitting: _isSubmitting,
                          isIdVerified:
                              _verifiedId == _idController.text.trim(),
                          onIdChanged: (_) {
                            if (_verifiedId != null) {
                              setState(() => _verifiedId = null);
                            }
                          },
                          onPasswordVisibilityChanged: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          onConfirmationVisibilityChanged: () => setState(
                            () => _obscureConfirmation = !_obscureConfirmation,
                          ),
                          onAgreementChanged: (value) =>
                              setState(() => _agreedToTerms = value ?? false),
                          onCheckId: _checkId,
                          onSmsRequest: () => _message(
                            '\uBB38\uC790 \uC778\uC99D \uC11C\uBC84\uAC00 \uC5F0\uACB0\uB418\uAE30 \uC804\uC785\uB2C8\uB2E4.',
                          ),
                          onRegister: _register,
                        ),
                      ),
                      const SizedBox(height: 28),
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

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.height, required this.isTablet});
  final double height;
  final bool isTablet;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_navy, Color(0xFF1E489D), Color(0xFF225CDD)],
      ),
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(isTablet ? 46 : 34),
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(isTablet ? 46 : 34),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -54,
            child: Container(
              height: isTablet ? 290 : 235,
              width: isTablet ? 290 : 235,
              decoration: const BoxDecoration(
                color: Color(0x1EFFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 23,
            left: 24,
            child: IconButton(
              onPressed: Get.back,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x2EFFFFFF),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
          Positioned(
            top: 29,
            left: 84,
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.show_chart_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP SEOUL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
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
            left: 30,
            bottom: 57,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '\uD68C\uC6D0\uAC00\uC785',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  '\uAE30\uBCF8 \uC815\uBCF4\uB97C \uC785\uB825\uD558\uACE0 \uC11C\uBE44\uC2A4\uB97C \uC2DC\uC791\uD558\uC138\uC694.',
                  style: TextStyle(color: Color(0xFFC5D4F1), fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.nameController,
    required this.idController,
    required this.phoneController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.obscurePassword,
    required this.obscureConfirmation,
    required this.agreedToTerms,
    required this.isCheckingId,
    required this.isSubmitting,
    required this.isIdVerified,
    required this.onIdChanged,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmationVisibilityChanged,
    required this.onAgreementChanged,
    required this.onCheckId,
    required this.onSmsRequest,
    required this.onRegister,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController idController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool obscurePassword;
  final bool obscureConfirmation;
  final bool agreedToTerms;
  final bool isCheckingId;
  final bool isSubmitting;
  final bool isIdVerified;
  final ValueChanged<String> onIdChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onConfirmationVisibilityChanged;
  final ValueChanged<bool?> onAgreementChanged;
  final VoidCallback onCheckId;
  final VoidCallback onSmsRequest;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x171A3C78),
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
          const _StepIndicator(),
          const SizedBox(height: 24),
          _RegisterField(
            controller: nameController,
            label: '\uC774\uB984',
            hint: '\uC774\uB984\uC744 \uC785\uB825\uD558\uC138\uC694',
            icon: Icons.person_outline_rounded,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter your name.'
                : null,
          ),
          const SizedBox(height: 18),
          _RegisterField(
            controller: idController,
            label: '\uC544\uC774\uB514',
            hint: '\uC601\uBB38\u00B7\uC22B\uC790 4\uC790 \uC774\uC0C1',
            icon: Icons.badge_outlined,
            onChanged: onIdChanged,
            validator: (value) =>
                value == null || !RegExp(r'^[a-zA-Z0-9]{4,12}$').hasMatch(value)
                ? 'Use 4-12 English letters or numbers.'
                : null,
            trailing: _SmallButton(
              label: isIdVerified
                  ? '\uD655\uC778 \uC644\uB8CC'
                  : '\uC911\uBCF5 \uD655\uC778',
              busy: isCheckingId,
              outlined: true,
              onPressed: onCheckId,
            ),
          ),
          const SizedBox(height: 18),
          _RegisterField(
            controller: phoneController,
            label: '\uD734\uB300\uC804\uD654',
            hint: '010-0000-0000',
            icon: Icons.phone_iphone_rounded,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                value == null || !RegExp(r'^01[0-9]{8,9}$').hasMatch(value)
                ? 'Enter a valid mobile number.'
                : null,
            trailing: _SmallButton(
              label: '\uC778\uC99D \uC694\uCCAD',
              onPressed: onSmsRequest,
            ),
          ),
          const SizedBox(height: 18),
          _RegisterField(
            controller: passwordController,
            label: '\uBE44\uBC00\uBC88\uD638',
            hint:
                '\uC601\uBB38\u00B7\uC22B\uC790\u00B7\uD2B9\uC218\uBB38\uC790 8\uC790 \uC774\uC0C1',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            trailing: _VisibilityButton(
              obscure: obscurePassword,
              onPressed: onPasswordVisibilityChanged,
            ),
            validator: (value) =>
                value == null ||
                    !RegExp(
                      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
                    ).hasMatch(value)
                ? 'Use 8+ letters, numbers, and special characters.'
                : null,
          ),
          const SizedBox(height: 18),
          _RegisterField(
            controller: passwordConfirmController,
            label: '\uBE44\uBC00\uBC88\uD638 \uD655\uC778',
            hint:
                '\uBE44\uBC00\uBC88\uD638\uB97C \uB2E4\uC2DC \uC785\uB825\uD558\uC138\uC694',
            icon: Icons.lock_outline_rounded,
            obscureText: obscureConfirmation,
            trailing: _VisibilityButton(
              obscure: obscureConfirmation,
              onPressed: onConfirmationVisibilityChanged,
            ),
            validator: (value) => value != passwordController.text
                ? 'Passwords do not match.'
                : null,
          ),
          const SizedBox(height: 22),
          InkWell(
            onTap: () => onAgreementChanged(!agreedToTerms),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFE),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: agreedToTerms,
                    activeColor: _blue,
                    onChanged: onAgreementChanged,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\uD544\uC218 \uC57D\uAD00 \uC804\uCCB4 \uB3D9\uC758',
                          style: TextStyle(
                            color: Color(0xFF31425B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\uC11C\uBE44\uC2A4 \uC774\uC6A9\uC57D\uAD00 \uBC0F \uAC1C\uC778\uC815\uBCF4 \uCC98\uB9AC\uBC29\uCE68\uC5D0 \uB3D9\uC758\uD569\uB2C8\uB2E4.',
                          style: TextStyle(
                            color: Color(0xFF8291A8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF8291A8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onRegister,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '\uAC00\uC785\uD558\uAE30',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '\uC774\uBBF8 \uACC4\uC815\uC774 \uC788\uC73C\uC2E0\uAC00\uC694?',
                style: TextStyle(color: Color(0xFF8291A8), fontSize: 13),
              ),
              TextButton(
                onPressed: Get.back,
                child: const Text(
                  '\uB85C\uADF8\uC778',
                  style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      _Step(number: '1', label: '\uAE30\uBCF8 \uC815\uBCF4', active: true),
      Expanded(child: Divider(color: Color(0xFFDDE5F2), thickness: 2)),
      _Step(number: '2', label: '\uAC00\uC785 \uC644\uB8CC'),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label, this.active = false});
  final String number;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: active ? _blue : const Color(0xFFE3E9F2),
        child: Text(
          number,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF8392A9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 9),
      Text(
        label,
        style: TextStyle(
          color: active ? _blue : const Color(0xFF9AA8BA),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.trailing,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;
  final Widget? trailing;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF596B85),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(text: label),
            const TextSpan(
              text: '  *',
              style: TextStyle(color: Color(0xFFFF5364)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              onChanged: onChanged,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFA3B3C9)),
                prefixIcon: Icon(icon, color: const Color(0xFF71839E)),
                suffixIcon: trailing is _VisibilityButton ? trailing : null,
                filled: true,
                fillColor: const Color(0xFFF9FBFF),
                contentPadding: const EdgeInsets.symmetric(vertical: 17),
                border: _outline(_fieldBorder),
                enabledBorder: _outline(_fieldBorder),
                focusedBorder: _outline(_blue),
              ),
            ),
          ),
          if (trailing != null && trailing is! _VisibilityButton) ...[
            const SizedBox(width: 9),
            trailing!,
          ],
        ],
      ),
    ],
  );
  OutlineInputBorder _outline(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide(color: color, width: 1.2),
  );
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.outlined = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final bool outlined;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 55,
    child: outlined
        ? OutlinedButton(
            onPressed: busy ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: _blue,
              side: const BorderSide(color: Color(0xFFBCD4FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: busy
                ? const SizedBox(
                    height: 17,
                    width: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(label),
          ),
  );
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.obscure, required this.onPressed});
  final bool obscure;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(
      obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      color: const Color(0xFF71839E),
    ),
  );
}

class _RegisterException implements Exception {
  const _RegisterException(this.message);
  final String message;
}
