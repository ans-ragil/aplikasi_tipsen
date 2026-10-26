import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// Halaman Login TIPSEN.
/// Validasi inline (email format + wajib isi), toggle lihat sandi,
/// lupa sandi (simulasi), dan tombol Masuk.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _sandiC = TextEditingController();
  bool _lihatSandi = false;
  bool _memproses = false;

  static final _emailRegex =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _emailC.dispose();
    _sandiC.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _memproses = true);
    // Simulasi proses autentikasi (nanti: Firebase Authentication).
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.read<AppState>().masuk(_emailC.text);
    showToast(context, 'Login berhasil. Selamat datang, Anisa!', ToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Brand ──────────────────────────────────
                  const _BrandMark(),
                  const SizedBox(height: 24),
                  Text(
                    'TIPSEN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Presensi Cepat, Akurat & Transparan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: T.textSecondary),
                  ),
                  const SizedBox(height: 28),

                  // ── Kartu form ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(T.rXl),
                      border: Border.all(color: T.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Masuk ke Akun Anda',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Gunakan email karyawan yang terdaftar.',
                            style:
                                TextStyle(fontSize: 12, color: T.textSecondary),
                          ),
                          const SizedBox(height: 18),

                          // Email
                          TextFormField(
                            controller: _emailC,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email Karyawan',
                              hintText: 'nama@tipsen.id',
                              prefixIcon:
                                  Icon(Icons.mail_outline_rounded, size: 20),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (v) {
                              final e = v?.trim() ?? '';
                              if (e.isEmpty) return 'Email karyawan wajib diisi.';
                              if (!_emailRegex.hasMatch(e)) {
                                return 'Masukkan format email yang valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Kata sandi
                          TextFormField(
                            controller: _sandiC,
                            obscureText: !_lihatSandi,
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _lihatSandi = !_lihatSandi),
                                icon: Icon(
                                  _lihatSandi
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: T.textSecondary,
                                ),
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Kata sandi wajib diisi.' : null,
                            onFieldSubmitted: (_) => _masuk(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => showToast(context,
                                  'Hubungi HC Admin untuk mereset kata sandi (simulasi).',
                                  ToastKind.info),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                textStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Lupa kata sandi?'),
                            ),
                          ),
                          const SizedBox(height: 6),

                          AppButton(
                            label: _memproses ? 'Memproses…' : 'Masuk Sekarang',
                            icon: Icons.login_rounded,
                            onPressed: _memproses ? null : _masuk,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Belum punya akses? ',
                                  style: TextStyle(
                                      fontSize: 12, color: T.textSecondary)),
                              GestureDetector(
                                onTap: () => showToast(context,
                                    'Silakan hubungi HC Admin (simulasi).',
                                    ToastKind.info),
                                child: const Text('Hubungi HC Admin',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: T.accent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 14, color: T.textMuted),
                      SizedBox(width: 6),
                      Text(
                        'Data Anda terenkripsi · Kebijakan Privasi TIPSEN',
                        style: TextStyle(fontSize: 11, color: T.textMuted),
                      ),
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

/// Logo aplikasi: lingkaran navy dengan huruf T (menggantikan aset SVG Figma).
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: T.heroGradient,
          boxShadow: [
            BoxShadow(
              color: T.navy.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'T',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
