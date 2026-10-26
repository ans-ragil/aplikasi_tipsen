import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../state/app_state.dart';
import '../bantuan_screen.dart';
import '../ubah_sandi_screen.dart';
import 'admin_widgets.dart';

/// Halaman Profil & Pengaturan khusus HC Admin.
class AdminProfilScreen extends StatelessWidget {
  const AdminProfilScreen({super.key});

  Future<void> _konfirmasiKeluar(BuildContext context) async {
    final keluar = await showAdminDialog<bool>(
      context,
      maxWidth: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Keluar dari Portal HC?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Anda akan kembali ke halaman login TIPSEN.',
              style: TextStyle(fontSize: 12, color: T.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Batal',
                  variant: AppButtonVariant.secondary,
                  height: 42,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Keluar',
                  variant: AppButtonVariant.danger,
                  height: 42,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
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
    final admin = app.adminHC;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const AdminPageTitle(
          title: 'Profil & Pengaturan',
          subtitle: 'Identitas akun HC beserta pengaturan portal.',
        ),
        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 900;

            final identitas = AdminPanel(
              title: 'Identitas Akun',
              subtitle: 'Akun administrator portal HC TIPSEN.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: T.heroGradient,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: Text(admin.inisial,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(admin.nama,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${admin.jabatan} · ${admin.departemen}',
                                style: const TextStyle(
                                    fontSize: 11.5, color: T.textSecondary)),
                            const SizedBox(height: 6),
                            AppBadge('Administrator HC',
                                tone: AppBadgeTone.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _BarisInfo(label: 'Email', nilai: admin.email),
                  _BarisInfo(label: 'ID Akun', nilai: admin.id),
                  _BarisInfo(label: 'Jadwal Kerja', nilai: admin.jadwal),
                  _BarisInfo(
                      label: 'Hak Akses',
                      nilai: 'Monitoring · Persetujuan · Laporan · Karyawan'),
                ],
              ),
            );

            final pengaturan = AdminPanel(
              title: 'Pengaturan Portal',
              subtitle: 'Kelola keamanan akun dan preferensi.',
              child: Column(
                children: [
                  _BarisMenu(
                    ikon: Icons.lock_reset_rounded,
                    judul: 'Ubah Kata Sandi',
                    ket: 'Perbarui kata sandi akun HC',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const UbahSandiScreen())),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.notifications_none_rounded,
                    judul: 'Notifikasi Pengajuan',
                    ket: app.notifikasiAktif
                        ? 'Notifikasi pengajuan baru aktif'
                        : 'Notifikasi pengajuan nonaktif',
                    trailing: Switch(
                      value: app.notifikasiAktif,
                      activeThumbColor: T.accent,
                      onChanged: app.aturNotifikasi,
                    ),
                    onTap: () => app.aturNotifikasi(!app.notifikasiAktif),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.my_location_rounded,
                    judul: 'Konfigurasi Geofence',
                    ket:
                        '${app.geofence.namaKantor} · radius ${app.geofence.radiusMeter} m',
                    onTap: () => showToast(context,
                        'Buka menu Live Tracking & Geofence untuk mengubah radius.',
                        ToastKind.info),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.help_outline_rounded,
                    judul: 'Bantuan & Kebijakan Privasi',
                    ket: 'FAQ, kontak, dan kebijakan data',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const BantuanScreen())),
                  ),
                  const Divider(height: 1),
                  _BarisMenu(
                    ikon: Icons.info_outline_rounded,
                    judul: 'Tentang Aplikasi',
                    ket: 'Versi, teknologi, dan pengembang',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const TentangScreen())),
                  ),
                ],
              ),
            );

            if (!lebar) {
              return Column(
                children: [identitas, const SizedBox(height: 16), pengaturan],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: identitas),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: pengaturan),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        AdminPanel(
          title: 'Ringkasan Aktivitas',
          subtitle: 'Statistik singkat sebagai administrator.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Kotak(
                label: 'Karyawan aktif',
                nilai: '${app.totalKaryawan}',
                warna: T.accent,
                bg: T.blueBg,
              ),
              _Kotak(
                label: 'Pengajuan menunggu',
                nilai: '${app.totalMenungguPersetujuan}',
                warna: T.amber,
                bg: T.amberBg,
              ),
              _Kotak(
                label: 'Kehadiran bulan ini',
                nilai: '${app.persenKehadiran}%',
                warna: T.green,
                bg: T.greenBg,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Keluar dari Portal HC',
          icon: Icons.logout_rounded,
          variant: AppButtonVariant.danger,
          expand: false,
          height: 44,
          onPressed: () => _konfirmasiKeluar(context),
        ),
        const SizedBox(height: 10),
        const Text('TIPSEN HC Portal v1.0.0 · Data tersimpan lokal di browser',
            style: TextStyle(fontSize: 10.5, color: T.textMuted)),
      ],
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 10.5, color: T.textMuted)),
          ),
          Expanded(
            child: Text(nilai,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: T.blueBg,
                borderRadius: BorderRadius.circular(T.rSm),
              ),
              child: Icon(ikon, size: 16, color: T.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(ket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5, color: T.textSecondary)),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded,
                    size: 17, color: T.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak({
    required this.label,
    required this.nilai,
    required this.warna,
    required this.bg,
  });

  final String label;
  final String nilai;
  final Color warna;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: warna.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: T.textSecondary)),
          const SizedBox(height: 4),
          Text(nilai,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: warna)),
        ],
      ),
    );
  }
}
