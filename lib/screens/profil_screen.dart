import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'bantuan_screen.dart';
import 'ubah_sandi_screen.dart';

/// Halaman Profil karyawan: identitas, pengaturan akun, bantuan, logout.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  Future<void> _konfirmasiKeluar(BuildContext context) async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
        title: const Text('Keluar Akun?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'Anda perlu masuk kembali untuk melakukan presensi.',
          style: TextStyle(fontSize: 13, color: T.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal',
                style: TextStyle(fontSize: 13, color: T.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: T.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(T.rSm)),
            ),
            child: const Text('Keluar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (keluar == true && context.mounted) {
      context.read<AppState>().keluar();
    }
  }

  void _buka(BuildContext context, Widget halaman) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => halaman));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profil Saya',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            // ── Kartu identitas ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: T.heroGradient,
                borderRadius: BorderRadius.circular(T.rXl),
              ),
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5), width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(user.inisial,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.nama,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('${user.jabatan} · ${user.departemen}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11.5, color: Color(0xFFCBDCFF))),
                  const SizedBox(height: 10),
                  const AppBadge('Karyawan Aktif', tone: AppBadgeTone.onHero),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Informasi akun ─────────────────────────────
            const SectionLabel('Informasi Akun'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: T.card,
                borderRadius: BorderRadius.circular(T.rLg),
                border: Border.all(color: T.border),
              ),
              child: Column(
                children: [
                  InfoTile(label: 'Email', value: user.email),
                  const Divider(height: 1),
                  InfoTile(label: 'ID Karyawan', value: user.id),
                  const Divider(height: 1),
                  InfoTile(label: 'Departemen', value: user.departemen),
                  const Divider(height: 1),
                  InfoTile(label: 'Jadwal Kerja', value: user.jadwal),
                  const Divider(height: 1),
                  InfoTile(
                      label: 'Presensi bulan ini',
                      value: '${app.hadirBulan(DateTime.now())} hari'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Pengaturan ─────────────────────────────────
            const SectionLabel('Pengaturan Akun'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: T.card,
                borderRadius: BorderRadius.circular(T.rLg),
                border: Border.all(color: T.border),
              ),
              child: Column(
                children: [
                  _BarisMenu(
                    ikon: Icons.lock_reset_rounded,
                    judul: 'Ubah Kata Sandi',
                    ket: 'Perbarui kata sandi akun Anda',
                    onTap: () => _buka(context, const UbahSandiScreen()),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.notifications_none_rounded,
                    judul: 'Notifikasi',
                    ket: app.notifikasiAktif
                        ? 'Pengingat presensi aktif'
                        : 'Pengingat presensi nonaktif',
                    trailing: Switch(
                      value: app.notifikasiAktif,
                      activeThumbColor: T.accent,
                      onChanged: (v) => app.aturNotifikasi(v),
                    ),
                    onTap: () => app.aturNotifikasi(!app.notifikasiAktif),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.help_outline_rounded,
                    judul: 'Bantuan & Kebijakan Privasi',
                    ket: 'FAQ, kontak HC, dan kebijakan data',
                    onTap: () => _buka(context, const BantuanScreen()),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.info_outline_rounded,
                    judul: 'Tentang Aplikasi',
                    ket: 'Versi, teknologi, dan pengembang',
                    onTap: () => _buka(context, const TentangScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Keluar Akun',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              onPressed: () => _konfirmasiKeluar(context),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('TIPSEN v1.0.0 · Data tersimpan lokal di browser',
                  style: TextStyle(fontSize: 10.5, color: T.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisMenu extends StatelessWidget {
  const _BarisMenu({
    required this.ikon,
    required this.judul,
    required this.ket,
    required this.onTap,
    this.trailing,
  });

  final IconData ikon;
  final String judul;
  final String ket;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: T.blueBg,
                borderRadius: BorderRadius.circular(T.rSm),
              ),
              child: Icon(ikon, size: 17, color: T.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(ket,
                      style: const TextStyle(
                          fontSize: 10.5, color: T.textSecondary)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: T.textMuted),
          ],
        ),
      ),
    );
  }
}
