import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// Halaman Profil: informasi akun karyawan, ubah sandi (simulasi), logout.
class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  Future<void> _konfirmasiKeluar(BuildContext context) async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(T.rLg)),
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 24),
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
                  Text(user.jabatan,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFCBDCFF))),
                  const SizedBox(height: 10),
                  AppBadge('Karyawan Aktif', tone: AppBadgeTone.onHero),
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
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Pengaturan ─────────────────────────────────
            const SectionLabel('Pengaturan'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onTap: () => showToast(context,
                  'Fitur ubah kata sandi akan tersedia setelah integrasi Firebase.',
                  ToastKind.info),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 19, color: T.accent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Ubah Kata Sandi',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: T.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onTap: () => showToast(context,
                  'Pusat bantuan TIPSEN (simulasi). Hubungi HC Admin bila ada kendala.',
                  ToastKind.info),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, size: 19, color: T.accent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Bantuan & Kebijakan Privasi',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: T.textMuted),
                  ],
                ),
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
              child: Text('TIPSEN v1.0 · Data simulasi',
                  style: TextStyle(fontSize: 11, color: T.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
