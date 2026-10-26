import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Dashboard Admin: ringkasan statistik, grafik kehadiran, akses cepat,
/// aktivitas terbaru, dan informasi penting.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final total = app.monitoring.length;
    final hadir = app.totalHadir;
    final terlambat = app.totalTerlambat;
    final wfh = app.totalWfh;
    final izin = total - hadir - terlambat - wfh;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Dashboard Admin',
          subtitle:
              'Ringkasan kehadiran karyawan hari ini, 26 Oktober 2026.',
          actions: [
            AppButton(
              label: 'Segarkan Data',
              icon: Icons.refresh_rounded,
              expand: false,
              height: 40,
              variant: AppButtonVariant.secondary,
              onPressed: () => showToast(
                  context, 'Data dashboard diperbarui (simulasi).', ToastKind.info),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Statistik ──────────────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final kolom = c.maxWidth > 900 ? 4 : (c.maxWidth > 560 ? 2 : 1);
            return GridView.count(
              crossAxisCount: kolom,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: kolom == 1 ? 3.4 : 2.1,
              children: [
                StatCard(
                  label: 'Total Karyawan',
                  value: '${app.totalKaryawan}',
                  note: 'Terdaftar di sistem',
                  tone: StatTone.slate,
                ),
                StatCard(
                  label: 'Hadir Hari Ini',
                  value: '$hadir dari $total',
                  note: '${app.persenKehadiran}% kehadiran',
                  tone: StatTone.green,
                ),
                StatCard(
                  label: 'Terlambat',
                  value: '$terlambat karyawan',
                  note: 'Perlu perhatian HC',
                  tone: StatTone.amber,
                ),
                StatCard(
                  label: 'Menunggu Persetujuan',
                  value: '${app.totalMenungguPersetujuan}',
                  note: 'Pengajuan cuti/izin',
                  tone: StatTone.blue,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Grafik + akses cepat ───────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 980;
            final grafik = AdminPanel(
              title: 'Ringkasan Kehadiran',
              subtitle: 'Distribusi status presensi hari ini',
              child: Column(
                children: [
                  _BarKehadiran(
                    label: 'Tepat waktu',
                    ket: '$hadir karyawan',
                    persen: total == 0 ? 0 : hadir / total,
                    warna: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _BarKehadiran(
                    label: 'Terlambat',
                    ket: '$terlambat karyawan',
                    persen: total == 0 ? 0 : terlambat / total,
                    warna: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 16),
                  _BarKehadiran(
                    label: 'WFH / luar radius',
                    ket: '$wfh karyawan',
                    persen: total == 0 ? 0 : wfh / total,
                    warna: T.accent,
                  ),
                  const SizedBox(height: 16),
                  _BarKehadiran(
                    label: 'Izin / cuti',
                    ket: '$izin karyawan',
                    persen: total == 0 ? 0 : izin / total,
                    warna: T.textMuted,
                  ),
                ],
              ),
            );

            final aksesCepat = AdminPanel(
              title: 'Akses Cepat',
              subtitle: 'Navigasi ke fungsi yang sering dipakai',
              child: Column(
                children: [
                  _TombolAkses(
                    ikon: Icons.fact_check_rounded,
                    judul: 'Setujui Pengajuan',
                    ket: '${app.totalMenungguPersetujuan} menunggu',
                    onTap: () => showToast(context,
                        'Buka menu Persetujuan Cuti & Izin di sidebar.',
                        ToastKind.info),
                  ),
                  const SizedBox(height: 10),
                  _TombolAkses(
                    ikon: Icons.my_location_rounded,
                    judul: 'Live Tracking',
                    ket: 'Radius ${app.geofence.radiusMeter} m',
                    onTap: () => showToast(context,
                        'Buka menu Live Tracking & Geofence di sidebar.',
                        ToastKind.info),
                  ),
                  const SizedBox(height: 10),
                  _TombolAkses(
                    ikon: Icons.download_rounded,
                    judul: 'Ekspor Laporan',
                    ket: 'Excel / PDF',
                    onTap: () => showToast(context,
                        'Buka menu Laporan & Ekspor Data di sidebar.',
                        ToastKind.info),
                  ),
                ],
              ),
            );

            if (!lebar) {
              return Column(
                children: [grafik, const SizedBox(height: 16), aksesCepat],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: grafik),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: aksesCepat),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Aktivitas + informasi ──────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 980;
            final aktivitas = AdminPanel(
              title: 'Aktivitas Terbaru',
              subtitle: 'Log presensi masuk karyawan hari ini',
              child: Column(
                children: [
                  for (final m in app.monitoring.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: T.blueBg,
                              borderRadius: BorderRadius.circular(T.rSm),
                            ),
                            alignment: Alignment.center,
                            child: Text(m.inisial,
                                style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: T.accent)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.nama,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    '${m.jamMasuk} · ${m.keterangan}',
                                    style: const TextStyle(
                                        fontSize: 10.5, color: T.textMuted)),
                              ],
                            ),
                          ),
                          AppBadge(
                            m.status.label,
                            tone: m.status == StatusPresensi.hadir
                                ? AppBadgeTone.green
                                : m.status == StatusPresensi.terlambat
                                    ? AppBadgeTone.amber
                                    : AppBadgeTone.blue,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );

            final informasi = AdminPanel(
              title: 'Informasi Penting',
              subtitle: 'Perlu tindakan HC',
              child: Column(
                children: [
                  _ItemInformasi(
                    ikon: Icons.schedule_rounded,
                    warna: T.amber,
                    bg: T.amberBg,
                    judul: '$terlambat karyawan terlambat hari ini',
                    ket: 'Perlu konfirmasi alasan keterlambatan.',
                  ),
                  const SizedBox(height: 12),
                  _ItemInformasi(
                    ikon: Icons.fact_check_rounded,
                    warna: T.accent,
                    bg: T.blueBg,
                    judul:
                        '${app.totalMenungguPersetujuan} pengajuan menunggu',
                    ket: 'Setujui atau tolak dari menu Persetujuan.',
                  ),
                  const SizedBox(height: 12),
                  _ItemInformasi(
                    ikon: Icons.location_off_rounded,
                    warna: T.red,
                    bg: T.redBg,
                    judul: '$wfh karyawan di luar radius',
                    ket: 'Presensi tercatat sebagai WFH.',
                  ),
                ],
              ),
            );

            if (!lebar) {
              return Column(
                children: [aktivitas, const SizedBox(height: 16), informasi],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: aktivitas),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: informasi),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _BarKehadiran extends StatelessWidget {
  const _BarKehadiran({
    required this.label,
    required this.ket,
    required this.persen,
    required this.warna,
  });

  final String label;
  final String ket;
  final double persen;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(ket,
                  style: const TextStyle(fontSize: 10, color: T.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: persen.clamp(0, 1),
              minHeight: 8,
              backgroundColor: const Color(0xFFEDF0F4),
              valueColor: AlwaysStoppedAnimation(warna),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 42,
          child: Text('${(persen * 100).round()}%',
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      ],
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
      color: T.blueBg,
      borderRadius: BorderRadius.circular(T.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.blueBorder),
          ),
          child: Row(
            children: [
              Icon(ikon, size: 18, color: T.accent),
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
                            fontSize: 10, color: T.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: T.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemInformasi extends StatelessWidget {
  const _ItemInformasi({
    required this.ikon,
    required this.warna,
    required this.bg,
    required this.judul,
    required this.ket,
  });

  final IconData ikon;
  final Color warna;
  final Color bg;
  final String judul;
  final String ket;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(T.rSm),
          ),
          child: Icon(ikon, size: 17, color: warna),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(ket,
                  style:
                      const TextStyle(fontSize: 10.5, color: T.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
