import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Dashboard Admin: ringkasan hari ini, grafik kehadiran, akses cepat.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onPindahMenu});

  final ValueChanged<int> onPindahMenu;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DateTime _diperbarui = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sekarang = DateTime.now();
    final monitoring = app.monitoringHariIni;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Dashboard Admin',
          subtitle: 'Ringkasan kehadiran ${tanggalPanjang(sekarang)}',
          actions: [
            AppBadge('Diperbarui ${jamMenit(_diperbarui)}',
                tone: AppBadgeTone.slate),
            AppButton(
              label: 'Perbarui',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.secondary,
              expand: false,
              height: 40,
              onPressed: () {
                setState(() => _diperbarui = DateTime.now());
                showToast(context, 'Data dashboard diperbarui.', ToastKind.info);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Statistik hari ini ──────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final kolom = c.maxWidth > 1000 ? 4 : (c.maxWidth > 620 ? 2 : 1);
            return GridView.count(
              crossAxisCount: kolom,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: kolom == 1 ? 3.4 : 1.9,
              children: [
                StatCard(
                  label: 'Total Karyawan',
                  value: '${app.totalKaryawan}',
                  note: 'Karyawan aktif terdaftar',
                  tone: StatTone.slate,
                  onTap: () => widget.onPindahMenu(4),
                ),
                StatCard(
                  label: 'Hadir Hari Ini',
                  value: '${app.masukHariIni}',
                  note: '${app.belumPresensiHariIni} belum presensi',
                  tone: StatTone.green,
                  onTap: () => widget.onPindahMenu(1),
                ),
                StatCard(
                  label: 'Terlambat',
                  value: '${app.terlambatHariIni}',
                  note: 'Melewati batas 08:15',
                  tone: StatTone.amber,
                  onTap: () => widget.onPindahMenu(1),
                ),
                StatCard(
                  label: 'Menunggu Persetujuan',
                  value: '${app.totalMenungguPersetujuan}',
                  note: 'Pengajuan cuti & izin',
                  tone: StatTone.blue,
                  onTap: () => widget.onPindahMenu(3),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Grafik + akses cepat ────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 900;
            final grafik = AdminPanel(
              title: 'Tingkat Kehadiran 5 Hari Terakhir',
              subtitle:
                  'Perbandingan jumlah karyawan hadir terhadap total karyawan.',
              child: _GrafikBatang(data: app.grafikMingguan()),
            );
            final akses = AdminPanel(
              title: 'Akses Cepat',
              subtitle: 'Pintasan ke menu yang paling sering dipakai.',
              child: Column(
                children: [
                  _TombolAkses(
                    ikon: Icons.fact_check_rounded,
                    judul: 'Setujui Pengajuan',
                    ket: '${app.totalMenungguPersetujuan} menunggu',
                    onTap: () => widget.onPindahMenu(3),
                  ),
                  const SizedBox(height: 10),
                  _TombolAkses(
                    ikon: Icons.my_location_rounded,
                    judul: 'Live Tracking',
                    ket: 'Radius ${app.geofence.radiusMeter} m',
                    onTap: () => widget.onPindahMenu(2),
                  ),
                  const SizedBox(height: 10),
                  _TombolAkses(
                    ikon: Icons.download_rounded,
                    judul: 'Ekspor Laporan',
                    ket: 'CSV / PDF',
                    onTap: () => widget.onPindahMenu(5),
                  ),
                ],
              ),
            );

            if (!lebar) {
              return Column(
                children: [grafik, const SizedBox(height: 16), akses],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: grafik),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: akses),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Presensi terbaru + info ─────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 900;
            final terbaru = AdminPanel(
              title: 'Presensi Terbaru Hari Ini',
              subtitle: '${monitoring.length} karyawan sudah melakukan presensi.',
              trailing: AdminTextAction(
                label: 'Lihat semua',
                onTap: () => widget.onPindahMenu(1),
              ),
              child: monitoring.isEmpty
                  ? const _Kosong(
                      pesan: 'Belum ada karyawan yang melakukan presensi hari ini.')
                  : Column(
                      children: [
                        for (final m in monitoring.take(5))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: T.blueBg,
                                    borderRadius:
                                        BorderRadius.circular(T.rSm),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(m.inisial,
                                      style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: T.accent)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.nama,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700)),
                                      Text(
                                          'Masuk ${m.jamMasuk} · Pulang ${m.jamPulang}',
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              color: T.textMuted)),
                                    ],
                                  ),
                                ),
                                AppBadge(
                                  m.status.label,
                                  tone: switch (m.status) {
                                    StatusPresensi.hadir => AppBadgeTone.green,
                                    StatusPresensi.terlambat =>
                                      AppBadgeTone.amber,
                                    StatusPresensi.wfh => AppBadgeTone.blue,
                                    StatusPresensi.izinDisetujui =>
                                      AppBadgeTone.slate,
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            );

            final info = AdminPanel(
              title: 'Informasi Penting',
              subtitle: 'Ringkasan kebijakan kehadiran yang berlaku.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBaris(
                    ikon: Icons.schedule_rounded,
                    judul: 'Jam kerja',
                    isi: 'Shift pagi 08.00 – 17.00 WIB, toleransi 15 menit.',
                  ),
                  const SizedBox(height: 12),
                  _InfoBaris(
                    ikon: Icons.my_location_rounded,
                    judul: 'Geofence',
                    isi:
                        '${app.geofence.namaKantor} · radius ${app.geofence.radiusMeter} m.',
                  ),
                  const SizedBox(height: 12),
                  _InfoBaris(
                    ikon: Icons.percent_rounded,
                    judul: 'Kehadiran bulan ini',
                    isi:
                        '${app.persenKehadiran}% dari ${app.totalCatatanBulanIni} catatan presensi.',
                  ),
                ],
              ),
            );

            if (!lebar) {
              return Column(
                children: [terbaru, const SizedBox(height: 16), info],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: terbaru),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: info),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _GrafikBatang extends StatelessWidget {
  const _GrafikBatang({required this.data});

  /// (label hari, jumlah hadir, total karyawan)
  final List<(String, int, int)> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (label, masuk, total) in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('$masuk',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: T.navy)),
                    const SizedBox(height: 6),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: total == 0
                            ? 0.02
                            : (masuk / total).clamp(0.04, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 46),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                T.accent.withValues(alpha: 0.85),
                                T.navy,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 10.5, color: T.textSecondary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TombolAkses extends StatelessWidget {
  const _TombolAkses({
    required this.ikon,
    required this.judul,
    required this.ket,
    required this.onTap,
  });

  final IconData ikon;
  final String judul;
  final String ket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.card,
      borderRadius: BorderRadius.circular(T.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.border),
          ),
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
                    Text(ket,
                        style: const TextStyle(
                            fontSize: 10.5, color: T.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 17, color: T.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  const _InfoBaris({
    required this.ikon,
    required this.judul,
    required this.isi,
  });

  final IconData ikon;
  final String judul;
  final String isi;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, size: 15, color: T.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(isi,
                  style: const TextStyle(
                      fontSize: 11, height: 1.45, color: T.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.pesan});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 32, color: T.textMuted),
          const SizedBox(height: 8),
          Text(pesan,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: T.textSecondary)),
        ],
      ),
    );
  }
}
