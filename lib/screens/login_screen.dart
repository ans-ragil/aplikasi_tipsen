import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// Halaman Login: validasi kredensial nyata terhadap akun demo,
/// plus alur "lupa kata sandi" dan pintu masuk portal HC.
///
/// Versi web (≥ 900 px): dua panel — panel merek navy di kiri (keunggulan
/// aplikasi) dan kartu form di kanan, seperti halaman masuk produk web pada
/// umumnya. Versi sempit: pita merek ringkas di atas, form di bawahnya.
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
      body: LayoutBuilder(
        builder: (context, c) => c.maxWidth >= 900 ? _tampilanWeb() : _tampilanSempit(),
      ),
    );
  }

  // ── WEB: panel merek + panel form ────────────────────────────
  Widget _tampilanWeb() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(flex: 11, child: _PanelMerek()),
        Expanded(
          flex: 10,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: _kolomForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── SEMPIT: pita merek + form ────────────────────────────────
  Widget _tampilanSempit() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _PitaMerek(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: _kolomForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kolomForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _kartuForm(),
        const SizedBox(height: 12),
        _kotakDemo(),
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
                style: const TextStyle(fontSize: 11, color: T.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Kartu form ───────────────────────────────────────────────
  Widget _kartuForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rXl),
        border: Border.all(color: T.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2A46).withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Masuk ke Akun Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Gunakan email karyawan yang terdaftar.',
                style: TextStyle(fontSize: 12, color: T.textSecondary)),
            const SizedBox(height: 20),
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
                final pola = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
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
                  tooltip: _lihatSandi ? 'Sembunyikan sandi' : 'Lihat sandi',
                  onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Belum punya akses?',
                    style: TextStyle(fontSize: 11.5, color: T.textSecondary)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => showToast(
                      context,
                      'Ajukan pembuatan akun ke HC Admin melalui '
                          'email hc@tipsen.id.',
                      ToastKind.info),
                  child: const Text('Hubungi HC Admin',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: T.accent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Akun demo ────────────────────────────────────────────────
  Widget _kotakDemo() {
    return Container(
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PANEL MEREK (web)
// ═══════════════════════════════════════════════════════════════
class _PanelMerek extends StatelessWidget {
  const _PanelMerek();

  static const _fitur = <(IconData, String, String)>[
    (
      Icons.my_location_rounded,
      'Validasi lokasi (geofence)',
      'Presensi hanya terekam di dalam radius area kantor.'
    ),
    (
      Icons.photo_camera_rounded,
      'Selfie sebagai bukti',
      'Kamera aktif saat presensi — bukan unggahan dari galeri.'
    ),
    (
      Icons.sync_rounded,
      'Tersambung ke portal HC',
      'Pengajuan izin dan cuti langsung masuk ke meja HC Admin.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: T.heroGradient),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -80,
            child: _Lingkaran(ukuran: 320, alpha: 0.055),
          ),
          Positioned(
            bottom: -130,
            left: -90,
            child: _Lingkaran(ukuran: 360, alpha: 0.045),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(56, 52, 56, 44),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + wordmark
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(T.rMd),
                          ),
                          alignment: Alignment.center,
                          child: const Text('T',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: T.navy)),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('TIPSEN',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.4,
                                    color: Colors.white)),
                            SizedBox(height: 2),
                            Text('Sistem Presensi Karyawan',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9FB0C8))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 46),

                    const Text(
                      'Presensi online yang cepat,\nakurat, dan transparan.',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Satu akun untuk Clock In, Clock Out, riwayat kehadiran, '
                      'serta pengajuan izin dan cuti. Tanpa kertas, tanpa '
                      'rekap manual.',
                      style: TextStyle(
                          fontSize: 13,
                          height: 1.65,
                          color: Color(0xFFB6C3D6)),
                    ),
                    const SizedBox(height: 38),

                    for (final (ikon, judul, ket) in _fitur)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(T.rMd),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.16)),
                              ),
                              child: Icon(ikon, size: 18, color: Colors.white),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(judul,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  const SizedBox(height: 3),
                                  Text(ket,
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.55,
                                          color: Color(0xFFA9B7CC))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      width: 64,
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TIPSEN v1.0.0 · Proyek Mobile & Web Application Development',
                      style:
                          TextStyle(fontSize: 10.5, color: Color(0xFF8494AC)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PITA MEREK (layar sempit)
// ═══════════════════════════════════════════════════════════════
class _PitaMerek extends StatelessWidget {
  const _PitaMerek();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: const BoxDecoration(gradient: T.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(T.rMd),
                ),
                alignment: Alignment.center,
                child: const Text('T',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: T.navy)),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('TIPSEN',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white)),
                  SizedBox(height: 1),
                  Text('Sistem Presensi Karyawan',
                      style:
                          TextStyle(fontSize: 10, color: Color(0xFF9FB0C8))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Presensi cepat, akurat & transparan.',
            style: TextStyle(
                fontSize: 19,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Clock In & Clock Out dengan validasi lokasi dan selfie.',
            style: TextStyle(
                fontSize: 11.5, height: 1.5, color: Color(0xFFB6C3D6)),
          ),
        ],
      ),
    );
  }
}

class _Lingkaran extends StatelessWidget {
  const _Lingkaran({required this.ukuran, required this.alpha});

  final double ukuran;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
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
