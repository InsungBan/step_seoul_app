import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:step_seoul_app/services/profile_service.dart';

const _blue = Color(0xFF2F67E8);
const _ink = Color(0xFF17233C);
const _muted = Color(0xFF7486A0);

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  late Future<CustomerProfile> _profile;
  bool _saving = false;
  bool _showCurrent = false;
  bool _showNew = false;

  @override
  void initState() {
    super.initState();
    _profile = _service.load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.save(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        currentPassword: _current.text.isEmpty ? null : _current.text,
        newPassword: _newPassword.text.isEmpty ? null : _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uD68C\uC6D0\uC815\uBCF4\uB97C \uC800\uC7A5\uD588\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
      Get.back<bool>(result: true);
    } on ProfileException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FD),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF7F9FD),
      elevation: 0,
      title: const Text(
        '\uD68C\uC6D0\uC815\uBCF4 \uC218\uC815',
        style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        onPressed: () => Get.back<bool>(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink),
      ),
    ),
    body: FutureBuilder<CustomerProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: _blue));
        if (snapshot.hasError)
          return const Center(
            child: Text(
              '\uD68C\uC6D0 \uC815\uBCF4\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
            ),
          );
        final profile = snapshot.requireData;
        if (_name.text.isEmpty) {
          _name.text = profile.name;
          _phone.text = profile.phone;
        }
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            children: [
              _Banner(profile: profile),
              const SizedBox(height: 24),
              const _Heading(
                '\uAE30\uBCF8 \uC815\uBCF4',
                '\uC8FC\uBB38\uACFC \uB300\uB9AC\uC810 \uC218\uB839 \uC548\uB0B4\uC5D0 \uC0AC\uC6A9\uB418\uB294 \uC815\uBCF4\uC608\uC694.',
              ),
              const SizedBox(height: 13),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Input(
                      label: '\uC774\uB984 *',
                      controller: _name,
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? '\uC774\uB984\uC744 \uC785\uB825\uD558\uC138\uC694.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '\uC544\uC774\uB514',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Readonly(text: profile.id),
                    const SizedBox(height: 5),
                    const Text(
                      '\uC544\uC774\uB514\uB294 \uAC00\uC785 \uD6C4 \uBCC0\uACBD\uD560 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.',
                      style: TextStyle(color: Color(0xFF9BAAC0), fontSize: 11),
                    ),
                    const SizedBox(height: 18),
                    _Input(
                      label: '\uD734\uB300\uC804\uD654 *',
                      controller: _phone,
                      icon: Icons.phone_iphone_rounded,
                      keyboard: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? '\uD734\uB300\uC804\uD654 \uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694.'
                          : null,
                    ),
                    const SizedBox(height: 13),
                    const _Notice(
                      '\uBCC0\uACBD\uB41C \uC5F0\uB77D\uCC98\uB85C \uC8FC\uBB38 \uC0C1\uD0DC\uC640 \uC218\uB839 \uC548\uB0B4\uB97C \uBCF4\uB0B4\uB4DC\uB824\uC694.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _Heading(
                '\uBE44\uBC00\uBC88\uD638 \uBCC0\uACBD',
                '\uBCC0\uACBD\uD558\uC9C0 \uC54A\uC73C\uBA74 \uD604\uC7AC \uBE44\uBC00\uBC88\uD638\uAC00 \uC720\uC9C0\uB429\uB2C8\uB2E4.',
              ),
              const SizedBox(height: 13),
              _Panel(
                child: Column(
                  children: [
                    _Input(
                      label: '\uD604\uC7AC \uBE44\uBC00\uBC88\uD638',
                      controller: _current,
                      icon: Icons.lock_outline_rounded,
                      obscure: !_showCurrent,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _showCurrent = !_showCurrent),
                        icon: Icon(
                          _showCurrent
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (v) =>
                          _newPassword.text.isNotEmpty &&
                              (v == null || v.isEmpty)
                          ? '\uD604\uC7AC \uBE44\uBC00\uBC88\uD638\uB97C \uC785\uB825\uD558\uC138\uC694.'
                          : null,
                    ),
                    const SizedBox(height: 17),
                    _Input(
                      label: '\uC0C8 \uBE44\uBC00\uBC88\uD638',
                      controller: _newPassword,
                      icon: Icons.lock_reset_rounded,
                      obscure: !_showNew,
                      suffix: IconButton(
                        onPressed: () => setState(() => _showNew = !_showNew),
                        icon: Icon(
                          _showNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      validator: (v) =>
                          v != null && v.isNotEmpty && v.length < 8
                          ? '8\uC790 \uC774\uC0C1 \uC785\uB825\uD558\uC138\uC694.'
                          : null,
                    ),
                    const SizedBox(height: 17),
                    _Input(
                      label: '\uC0C8 \uBE44\uBC00\uBC88\uD638 \uD655\uC778',
                      controller: _confirm,
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                      validator: (v) =>
                          _newPassword.text.isNotEmpty && v != _newPassword.text
                          ? '\uC0C8 \uBE44\uBC00\uBC88\uD638\uAC00 \uC77C\uCE58\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4.'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _Heading('\uACC4\uC815 \uC815\uBCF4', ''),
              const SizedBox(height: 13),
              _Panel(
                child: Column(
                  children: [
                    _InfoRow('\uAC00\uC785\uC77C', _date(profile.joinedAt)),
                    const Divider(),
                    const _InfoRow(
                      '\uB85C\uADF8\uC778 \uBC29\uC2DD',
                      '\uC544\uC774\uB514',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 17),
              const _Notice(
                '\uAC1C\uC778\uC815\uBCF4\uB294 \uC548\uC804\uD558\uAC8C \uBCF4\uD638\uB429\uB2C8\uB2E4.',
              ),
            ],
          ),
        );
      },
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFDCE5F1))),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: _saving ? null : () => Get.back<bool>(),
              style: OutlinedButton.styleFrom(minimumSize: const Size(130, 56)),
              child: const Text('\uCDE8\uC18C'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _blue,
                ),
                icon: const Icon(Icons.save_outlined),
                label: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('\uBCC0\uACBD \uB0B4\uC6A9 \uC800\uC7A5'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.profile});
  final CustomerProfile profile;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF142A65), Color(0xFF2869EA)],
      ),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 33,
          backgroundColor: Color(0x335E93E6),
          child: Icon(
            Icons.person_outline_rounded,
            color: Colors.white,
            size: 45,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STEP SEOUL \uD68C\uC6D0',
                style: TextStyle(color: Color(0xFFBDD2FF)),
              ),
              Text(
                profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                '\u2713 \uBCF8\uC778 \uC778\uC99D \uC644\uB8CC',
                style: TextStyle(color: Color(0xFF9EF4C6), fontSize: 12),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFC8DBFF)),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle);
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (subtitle.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(subtitle, style: const TextStyle(color: _muted)),
        ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
    ),
    child: child,
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.controller,
    required this.icon,
    required this.validator,
    this.obscure = false,
    this.suffix,
    this.keyboard,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        validator: validator,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: _inputDecoration(icon, suffix),
      ),
    ],
  );
}

class _Readonly extends StatelessWidget {
  const _Readonly({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: text,
    enabled: false,
    decoration: _inputDecoration(Icons.lock_outline_rounded, null),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: _blue, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: _muted)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

InputDecoration _inputDecoration(IconData icon, Widget? suffix) =>
    InputDecoration(
      prefixIcon: Icon(icon, color: _blue),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FBFE),
      contentPadding: const EdgeInsets.symmetric(vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD8E3F4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFD8E3F4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _blue),
      ),
    );
String _date(String value) =>
    value.length >= 10 ? value.substring(0, 10).replaceAll('-', '. ') : value;
