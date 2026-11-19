import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _adult = false;
  bool _terms = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_register && (!_adult || !_terms)) {
      showAppMessage(
        context,
        'Konfirmasi usia 18+ dan persetujuan Syarat & Privasi dulu, ya.',
        error: true,
      );
      return;
    }
    final session = context.read<SessionController>();
    try {
      if (_register) {
        await session.register(
          name: _name.text,
          username: _username.text,
          email: _email.text,
          password: _password.text,
          adultConfirmed: _adult,
          termsAccepted: _terms,
          privacyAccepted: _terms,
        );
      } else {
        await session.login(_email.text, _password.text);
      }
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } catch (e) {
      if (mounted) {
        showAppMessage(context, 'Terjadi kesalahan: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = context.watch<SessionController>().isBusy;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandMark(),
                  const SizedBox(height: 34),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE8F0E6), Color(0xFFF8EDE4)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .72),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'SOCIAL ACTIVITY COMPANION',
                            style: TextStyle(
                              letterSpacing: 1,
                              color: AppColors.forest,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          'Find your people.\nMake it happen.',
                          style: TextStyle(
                            fontSize: 31,
                            height: 1.04,
                            letterSpacing: -1.3,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Nggak harus punya geng dulu untuk mulai hal seru. Temukan orang dengan minat yang sama dan lakukan bareng.',
                          style: TextStyle(
                            height: 1.45,
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            _MiniBubble(
                              icon: Icons.sports_tennis_rounded,
                              color: AppColors.sageLight,
                            ),
                            SizedBox(width: 8),
                            _MiniBubble(
                              icon: Icons.coffee_rounded,
                              color: AppColors.peach,
                            ),
                            SizedBox(width: 8),
                            _MiniBubble(
                              icon: Icons.menu_book_rounded,
                              color: AppColors.lemon,
                            ),
                            SizedBox(width: 8),
                            _MiniBubble(
                              icon: Icons.palette_rounded,
                              color: AppColors.lavender,
                            ),
                            Spacer(),
                            Text(
                              '18+ COMMUNITY',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .7,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 27),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _register ? 'Buat akun baru' : 'Welcome back!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: -.7,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: isBusy
                            ? null
                            : () => setState(() => _register = !_register),
                        child: Text(_register ? 'Masuk' : 'Daftar'),
                      ),
                    ],
                  ),
                  Text(
                    _register
                        ? 'Mulai bikin momen bareng orang baru.'
                        : 'Masuk dan cari kegiatan yang cocok sama kamu.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (_register) ...[
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama lengkap',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _username,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Username minimal 3 karakter.'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Masukkan email yang valid.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 8)
                              ? 'Password minimal 8 karakter.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  if (_register) ...[
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _adult,
                      onChanged: (v) => setState(() => _adult = v ?? false),
                      title: const Text(
                        'Saya berusia minimal 18 tahun.',
                        style: TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _terms,
                      onChanged: (v) => setState(() => _terms = v ?? false),
                      title: const Text(
                        'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi.',
                        style: TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : _submit,
                      child: isBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_register ? 'Buat akun' : 'Masuk ke Barengin'),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      _register
                          ? 'Dengan mendaftar, kamu bisa membuat dan mengikuti aktivitas.'
                          : 'Belum punya akun? Gunakan tombol Daftar di atas.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Center(
                    child: Text(
                      'Made for doing things together.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.sageDark,
                        fontSize: 11,
                      ),
                    ),
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

class _MiniBubble extends StatelessWidget {
  const _MiniBubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: AppColors.forest, size: 18),
  );
}
