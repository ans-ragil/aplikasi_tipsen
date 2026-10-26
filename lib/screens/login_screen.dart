import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// Halaman Login: validasi kredensial nyata terhadap akun demo,
/// plus alur "lupa kata sandi" dan pintu masuk portal HC.
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
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _sandiC.dispose();
    super.dispose();
  }

  void _masuk() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppState>();
    final pesan = app.masuk(_emailC.text, _sandiC.text);
    if (pesan != null) {
      setState(() => _error = pesan);
      return;
    }
    // Toast selamat datang ditampilkan oleh shell tujuan (ShellScreen /
    // AdminShell) setelah frame pertama, supaya muncul di dalam frame
    // aplikasi dan tidak menutupi navigasi bawah.
  }

  Future<void> _lupaSandi() async {
    final c = TextEditingController(text: _emailC.text);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
        title: const Text('Lupa Kata Sandi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email terdaftar. Sistem akan mengirim tautan atur ulang '
              'kata sandi melalui HC Admin.',
              style: TextStyle(fontSize: 12.5, color: T.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email Karyawan',
                hintText: 'nama@tipsen.id',
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal',
                style: TextStyle(fontSize: 13, color: T.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(c.text),
            style: FilledButton.styleFrom(
              backgroundColor: T.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(T.rSm)),
            ),
            child: const Text('Kirim Permintaan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    c.dispose();
    if (email == null || email.trim().isEmpty || !mounted) return;
    final err = context.read<AppState>().resetSandi(email);
    if (!mounted) return;
    showToast(
      context,
      err ??
          'Permintaan atur ulang dikirim ke HC Admin. Ikuti instruksi pada '
              'email ${email.trim()}.',
      err == null ? ToastKind.success : ToastKind.error,
    );
  }

  void _masukAdmin() {
    final app = context.read<AppState>();
    final pesan = app.masuk(AppState.emailAdmin, AppState.sandiAdmin);
    if (pesan != null) {
      showToast(context, pesan, ToastKind.error);
      return;
    }
    showToast(context, 'Masuk sebagai HC Admin (demo).', ToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Brand ────────────────────────────────
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: T.navy,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: T.navy.withValues(alpha: 0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('T',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text('TIPSEN',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            color: T.navy)),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text('Presensi Cepat, Akurat & Transparan',
                        style: TextStyle(fontSize: 12, color: T.textSecondary)),
                  ),
                  const SizedBox(height: 22),

                  // ── Kartu form ───────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: T.card,
                      borderRadius: BorderRadius.circular(T.rXl),
                      border: Border.all(color: T.border),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B2A46).withValues(alpha: 0.05),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Masuk ke Akun Anda',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          const Text('Gunakan email karyawan yang terdaftar.',
                              style: TextStyle(
                                  fontSize: 12, color: T.textSecondary)),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailC,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Karyawan',
                              hintText: 'nama@tipsen.id',
                              prefixIcon: Icon(Icons.mail_outline_rounded,
                                  size: 19, color: T.textMuted),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return 'Email wajib diisi.';
                              final pola =
                                  RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
                              if (!pola.hasMatch(t)) {
                                return 'Format email belum benar.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _sandiC,
                            obscureText: !_lihatSandi,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _masuk(),
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 19, color: T.textMuted),
                              suffixIcon: IconButton(
                                tooltip: _lihatSandi
                                    ? 'Sembunyikan sandi'
                                    : 'Lihat sandi',
                                onPressed: () =>
                                    setState(() => _lihatSandi = !_lihatSandi),
                                icon: Icon(
                                  _lihatSandi
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 19,
                                  color: T.textMuted,
                                ),
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            validator: (v) {
                              if ((v ?? '').isEmpty) return 'Kata sandi wajib diisi.';
                              if ((v ?? '').length < 6) {
                                return 'Kata sandi minimal 6 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _lupaSandi,
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                minimumSize: const Size(0, 34),
                                textStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Lupa kata sandi?'),
                            ),
                          ),
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: T.redBg,
                                borderRadius: BorderRadius.circular(T.rSm),
                                border: Border.all(color: T.redBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      size: 17, color: T.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_error!,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.4,
                                            color: T.red,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          AppButton(
                            label: 'Masuk Sekarang',
                            icon: Icons.login_rounded,
                            onPressed: _masuk,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: const Text('Belum punya akses? ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: T.textSecondary)),
                              ),
                              Flexible(
                                child: GestureDetector(
                                  onTap: () => showToast(
                                      context,
                                      'Ajukan pembuatan akun ke HC Admin melalui '
                                          'email hc@tipsen.id.',
                                      ToastKind.info),
                                  child: const Text('Hubungi HC Admin',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: T.accent)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Akun demo ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: T.blueBg,
                      borderRadius: BorderRadius.circular(T.rLg),
                      border: Border.all(color: T.blueBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.key_rounded, size: 16, color: T.accent),
                            SizedBox(width: 7),
                            Text('Akun demo',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: T.accent)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _BarisDemo(
                          peran: 'Karyawan',
                          email: AppState.emailKaryawan,
                          sandi: AppState.sandiKaryawan,
                          onPakai: () => setState(() {
                            _emailC.text = AppState.emailKaryawan;
                            _sandiC.text = AppState.sandiKaryawan;
                            _error = null;
                          }),
                        ),
                        const SizedBox(height: 6),
                        _BarisDemo(
                          peran: 'HC Admin',
                          email: AppState.emailAdmin,
                          sandi: AppState.sandiAdmin,
                          onPakai: () => setState(() {
                            _emailC.text = AppState.emailAdmin;
                            _sandiC.text = AppState.sandiAdmin;
                            _error = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Masuk sebagai HC Admin (Demo)',
                    icon: Icons.admin_panel_settings_rounded,
                    variant: AppButtonVariant.secondary,
                    height: 46,
                    onPressed: _masukAdmin,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                          size: 14, color: T.textMuted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Data tersimpan lokal di browser · Kebijakan Privasi TIPSEN',
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 11, color: T.textMuted),
                        ),
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

class _BarisDemo extends StatelessWidget {
  const _BarisDemo({
    required this.peran,
    required this.email,
    required this.sandi,
    required this.onPakai,
  });

  final String peran;
  final String email;
  final String sandi;
  final VoidCallback onPakai;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(peran,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: T.accent)),
              Text('$email · $sandi',
                  style: const TextStyle(fontSize: 11, color: T.textSecondary)),
            ],
          ),
        ),
        TextButton(
          onPressed: onPakai,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          child: const Text('Isi otomatis'),
        ),
      ],
    );
  }
}
