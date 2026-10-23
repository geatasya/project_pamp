import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import 'auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isRegister = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_isRegister) {
      await auth.register(_email.text.trim(), _pass.text);
    } else {
      await auth.login(_email.text.trim(), _pass.text);
    }
  }

  Widget _formCard(AuthProvider auth, bool wide) {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!wide) ...[
            const Center(child: AppLogo(size: 108, radius: 30)),
            const SizedBox(height: 24),
          ],
          Text(_isRegister ? 'Buat Akun Baru' : 'Selamat Datang',
              style: const TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 8),
          Text(
            _isRegister
                ? 'Daftar untuk mulai mencatat konser incaranmu.'
                : 'Masuk untuk melihat jadwal konser & tiketmu.',
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          const Text('Email',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
                hintText: 'nama@email.com',
                prefixIcon:
                    Icon(Icons.mail_outline_rounded, color: AppColors.muted)),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
          ),
          const SizedBox(height: 16),
          const Text('Password',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pass,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'Minimal 6 karakter',
              prefixIcon: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.muted),
              suffixIcon: IconButton(
                icon: Icon(_obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.redBg,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(auth.error!,
                  style: const TextStyle(
                      color: AppColors.red, fontWeight: FontWeight.w600)),
            ),
          ],
          if (auth.info != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.tealBg,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(auth.info!,
                  style: const TextStyle(
                      color: AppColors.teal, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: auth.isLoading ? null : _submit,
            child: auth.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(_isRegister ? 'Daftar' : 'Masuk'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() => _isRegister = !_isRegister),
            child: Text(
              _isRegister
                  ? 'Sudah punya akun? Masuk'
                  : 'Belum punya akun? Daftar',
              style: const TextStyle(
                  color: AppColors.purple, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wide = isWideLayout(context);

    final formArea = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: _formCard(auth, wide),
        ),
      ),
    );

    if (!wide) {
      return Scaffold(backgroundColor: Colors.white, body: SafeArea(child: formArea));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFFAF9F7),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(size: 300, radius: 44),
                      const SizedBox(height: 30),
                      const Text('Catat konser, simpan tiket,\nwujudkan nonton!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.25)),
                      const SizedBox(height: 10),
                      const Text(
                          'Pantau jadwal konser incaran, kelola tiket,\ndan capai target tabunganmu di satu tempat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: formArea),
        ],
      ),
    );
  }
}
