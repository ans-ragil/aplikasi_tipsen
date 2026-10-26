import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/foto_profil.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'bantuan_screen.dart';
import 'ubah_sandi_screen.dart';

/// Halaman Profil karyawan: identitas + foto profil, pengaturan akun,
/// bantuan, dan keluar.
///
/// Web (≥ 1000 px): dua kolom — kartu identitas di kiri, pengaturan di kanan.
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => halaman));
  }

  // ── Foto profil ────────────────────────────────────────────
  Future<void> _pilihDariPerangkat(BuildContext context) async {
    final app = context.read<AppState>();
    final hasil = await pilihFotoProfil();
    if (!context.mounted) return;
    if (hasil.pesan != null) {
      showToast(context, hasil.pesan!, ToastKind.error);
      return;
    }
    if (hasil.bytes == null) return; // dialog ditutup

    final galat = await app.aturFotoProfil(hasil.bytes!);
    if (!context.mounted) return;
    if (galat != null) {
      showToast(context, galat, ToastKind.error);
      return;
    }
    showToast(context, 'Foto profil berhasil diperbarui.', ToastKind.success);
  }

  Future<void> _hapusFoto(BuildContext context) async {
    final app = context.read<AppState>();
    await app.hapusFotoProfil();
    if (!context.mounted) return;
    showToast(context, 'Foto profil dihapus.', ToastKind.info);
  }

  void _menuFoto(BuildContext context) {
    final app = context.read<AppState>();
    if (app.fotoProfil == null) {
      _pilihDariPerangkat(context);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: T.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: T.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: T.accent, size: 20),
              title: const Text('Pilih foto baru',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.of(ctx).pop();
                _pilihDariPerangkat(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: T.red, size: 20),
              title: const Text('Hapus foto profil',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.of(ctx).pop();
                _hapusFoto(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;

    // ── Kartu identitas ───────────────────────────────────────
    // Satu-satunya jalan untuk mengubah foto adalah ikon kamera yang menempel
    // di lingkaran avatar (tidak ada tombol teks tambahan yang dobel).
    // Web: avatar di kiri, identitas di kanan.
    // Sempit: susunan bertumpuk seperti aplikasi ponsel.
    Widget kartuIdentitas(bool web) {
      if (web) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: T.heroGradient,
            borderRadius: BorderRadius.circular(T.rXl),
          ),
          child: Row(
            children: [
              AvatarFotoBisaDiubah(
                inisial: user.inisial,
                foto: app.fotoProfil,
                size: 76,
                bg: Colors.white.withValues(alpha: 0.16),
                fg: Colors.white,
                borderColor: Colors.white.withValues(alpha: 0.5),
                onTap: () => _menuFoto(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 3),
                    Text('${user.jabatan} · ${user.departemen}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFFCBDCFF))),
                    const SizedBox(height: 8),
                    const AppBadge('Karyawan Aktif',
                        tone: AppBadgeTone.onHero),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: T.heroGradient,
          borderRadius: BorderRadius.circular(T.rXl),
        ),
        child: Column(
          children: [
            AvatarFotoBisaDiubah(
              inisial: user.inisial,
              foto: app.fotoProfil,
              size: 92,
              bg: Colors.white.withValues(alpha: 0.16),
              fg: Colors.white,
              borderColor: Colors.white.withValues(alpha: 0.5),
              onTap: () => _menuFoto(context),
            ),
            const SizedBox(height: 14),
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
      );
    }

    final informasiAkun = Container(
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
    );

    final pengaturan = Container(
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: Column(
        children: [
          _BarisMenu(
            ikon: Icons.account_circle_outlined,
            judul: 'Foto Profil',
            ket: app.fotoProfil == null
                ? 'Belum ada foto — memakai inisial nama'
                : 'Foto tersimpan di browser ini',
            onTap: () => _menuFoto(context),
          ),
          const Divider(height: 1),
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
    );

    final tombolKeluar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Keluar Akun',
          icon: Icons.logout_rounded,
          variant: AppButtonVariant.danger,
          onPressed: () => _konfirmasiKeluar(context),
        ),
        const SizedBox(height: 10),
        const Text('TIPSEN v1.0.0 · Data tersimpan lokal di browser',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: T.textMuted)),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        final web = c.maxWidth >= lebarWeb;

        if (web) {
          return SingleChildScrollView(
            padding: paddingHalaman(c.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profil Saya',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                    'Kelola foto profil, keamanan akun, dan preferensi Anda.',
                    style:
                        TextStyle(fontSize: 12, color: T.textSecondary)),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          kartuIdentitas(true),
                          const SizedBox(height: 18),
                          const SectionLabel('Informasi Akun'),
                          const SizedBox(height: 8),
                          informasiAkun,
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Pengaturan Akun'),
                          const SizedBox(height: 8),
                          pengaturan,
                          const SizedBox(height: 18),
                          tombolKeluar,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: paddingHalaman(c.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profil Saya',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              kartuIdentitas(false),
              const SizedBox(height: 18),
              const SectionLabel('Informasi Akun'),
              const SizedBox(height: 8),
              informasiAkun,
              const SizedBox(height: 18),
              const SectionLabel('Pengaturan Akun'),
              const SizedBox(height: 8),
              pengaturan,
              const SizedBox(height: 18),
              tombolKeluar,
            ],
          ),
        );
      },
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
