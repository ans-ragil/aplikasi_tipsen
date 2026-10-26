import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Monitoring Presensi: tabel kehadiran karyawan + filter + detail.
class AdminMonitoringScreen extends StatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  String _filter = 'Semua status';
  String _cari = '';

  static const _opsiFilter = [
    'Semua status',
    'Hadir',
    'Terlambat',
    'WFH',
    'Izin Disetujui',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    final data = app.monitoring.where((m) {
      final cocokCari = m.nama.toLowerCase().contains(_cari.toLowerCase()) ||
          m.jabatan.toLowerCase().contains(_cari.toLowerCase());
      final cocokFilter =
          _filter == 'Semua status' || m.status.label == _filter;
      return cocokCari && cocokFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Monitoring Presensi',
          subtitle: 'Pantau kehadiran karyawan secara real-time (data simulasi).',
          actions: [
            AppButton(
              label: 'Ekspor Excel',
              icon: Icons.download_rounded,
              expand: false,
              height: 40,
              onPressed: () => showToast(
                  context, 'Ekspor Excel disiapkan (simulasi).', ToastKind.success),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Ringkasan cepat ────────────────────────────────
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
                  label: 'Hadir',
                  value: '${app.totalHadir}',
                  note: 'Tepat waktu',
                  tone: StatTone.green,
                ),
                StatCard(
                  label: 'Terlambat',
                  value: '${app.totalTerlambat}',
                  note: 'Lewat jam masuk',
                  tone: StatTone.amber,
                ),
                StatCard(
                  label: 'WFH',
                  value: '${app.totalWfh}',
                  note: 'Di luar radius',
                  tone: StatTone.blue,
                ),
                StatCard(
                  label: 'Izin',
                  value:
                      '${app.monitoring.length - app.totalHadir - app.totalTerlambat - app.totalWfh}',
                  note: 'Disetujui HC',
                  tone: StatTone.slate,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Toolbar filter ─────────────────────────────────
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdminSearchField(
              hint: 'Cari nama atau jabatan…',
              onChanged: (v) => setState(() => _cari = v),
            ),
            AdminFilterDropdown(
              value: _filter,
              items: _opsiFilter,
              onChanged: (v) => setState(() => _filter = v),
            ),
            Text('${data.length} baris',
                style: const TextStyle(fontSize: 11.5, color: T.textMuted)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tabel ──────────────────────────────────────────
        AdminPanel(
          title: 'Log Presensi Karyawan',
          subtitle: 'Klik "Detail" untuk melihat bukti presensi.',
          child: data.isEmpty
              ? const _KosongMonitoring()
              : AdminTable(
                  lebarMinimal: 900,
                  flex: const [3, 1, 1, 2, 1, 2, 1],
                  onTapBaris: (i) => _bukaDetail(context, data[i]),
                  kolom: const [
                    'Karyawan',
                    'Masuk',
                    'Pulang',
                    'Lokasi',
                    'Status',
                    'Keterangan',
                    'Aksi',
                  ],
                  baris: [
                    for (final m in data)
                      [
                        AdminEmployeeCell(
                          inisial: m.inisial,
                          nama: m.nama,
                          subjudul: m.jabatan,
                        ),
                        Text(m.jamMasuk,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(m.jamPulang,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: T.textSecondary)),
                        Text(m.lokasi,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: T.textSecondary)),
                        AppBadge(
                          m.status.label,
                          tone: switch (m.status) {
                            StatusPresensi.hadir => AppBadgeTone.green,
                            StatusPresensi.terlambat => AppBadgeTone.amber,
                            StatusPresensi.wfh => AppBadgeTone.blue,
                            StatusPresensi.izinDisetujui => AppBadgeTone.slate,
                          },
                        ),
                        Text(m.keterangan,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: T.textSecondary)),
                        AdminTextAction(
                          label: 'Detail',
                          onTap: () => _bukaDetail(context, m),
                        ),
                      ],
                  ],
                ),
        ),
      ],
    );
  }

  void _bukaDetail(BuildContext context, BarisMonitoring m) {
    showAdminDialog<void>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminEmployeeCell(
                  inisial: m.inisial,
                  nama: m.nama,
                  subjudul: m.jabatan,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: T.blueBg,
              borderRadius: BorderRadius.circular(T.rMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_camera_rounded,
                    size: 18, color: T.accent),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Bukti selfie presensi tersedia (simulasi).',
                      style: TextStyle(fontSize: 12, color: T.accent)),
                ),
                AppBadge(m.status.label,
                    tone: m.status == StatusPresensi.hadir
                        ? AppBadgeTone.green
                        : AppBadgeTone.amber),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rMd),
              border: Border.all(color: T.border),
            ),
            child: Column(
              children: [
                InfoTile(label: 'Jam masuk', value: m.jamMasuk),
                const Divider(height: 1),
                InfoTile(label: 'Jam pulang', value: m.jamPulang),
                const Divider(height: 1),
                InfoTile(label: 'Lokasi', value: m.lokasi),
                const Divider(height: 1),
                InfoTile(
                  label: 'Jarak dari kantor',
                  value: m.jarakMeter >= 1000
                      ? '${(m.jarakMeter / 1000).toStringAsFixed(1)} km'
                      : '${m.jarakMeter} m',
                ),
                const Divider(height: 1),
                InfoTile(label: 'Keterangan', value: m.keterangan),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Tutup',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _KosongMonitoring extends StatelessWidget {
  const _KosongMonitoring();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 34, color: T.textMuted),
          SizedBox(height: 8),
          Text('Tidak ada data yang cocok',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          SizedBox(height: 3),
          Text('Coba ubah kata kunci atau filter status.',
              style: TextStyle(fontSize: 11, color: T.textMuted)),
        ],
      ),
    );
  }
}
