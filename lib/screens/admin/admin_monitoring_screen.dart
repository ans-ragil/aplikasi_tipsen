import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/csv.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Monitoring Presensi: log presensi karyawan hari ini.
class AdminMonitoringScreen extends StatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  State<AdminMonitoringScreen> createState() => _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState extends State<AdminMonitoringScreen> {
  String _cari = '';
  String _status = 'Semua status';

  static const _opsiStatus = [
    'Semua status',
    'Hadir',
    'Terlambat',
    'WFH',
    'Izin Disetujui',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final semua = app.monitoringHariIni;
    final data = semua.where((m) {
      final cocokNama = m.nama.toLowerCase().contains(_cari.toLowerCase()) ||
          m.jabatan.toLowerCase().contains(_cari.toLowerCase());
      final cocokStatus =
          _status == 'Semua status' || m.status.label == _status;
      return cocokNama && cocokStatus;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Monitoring Presensi',
          subtitle:
              '${semua.length} dari ${app.totalKaryawan} karyawan sudah presensi '
              'hari ini (${tanggalPanjang(DateTime.now())}).',
          actions: [
            AppBadge('${app.belumPresensiHariIni} belum presensi',
                tone: app.belumPresensiHariIni > 0
                    ? AppBadgeTone.amber
                    : AppBadgeTone.green),
          ],
        ),
        const SizedBox(height: 18),

        // ── Ringkasan status ────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              label: 'Hadir',
              nilai: app.hadirHariIni,
              warna: T.green,
              bg: T.greenBg,
            ),
            _Chip(
              label: 'Terlambat',
              nilai: app.terlambatHariIni,
              warna: T.amber,
              bg: T.amberBg,
            ),
            _Chip(
              label: 'Izin',
              nilai: app.izinHariIni,
              warna: T.textSecondary,
              bg: const Color(0xFFF2F5F8),
            ),
            _Chip(
              label: 'Belum presensi',
              nilai: app.belumPresensiHariIni,
              warna: T.red,
              bg: T.redBg,
            ),
          ],
        ),
        const SizedBox(height: 16),

        AdminPanel(
          title: 'Log Presensi Hari Ini',
          subtitle: 'Klik baris untuk melihat detail bukti presensi.',
          trailing: AdminTextAction(
            label: 'Ekspor CSV',
            onTap: () => _ekspor(data),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AdminSearchField(
                    hint: 'Cari nama atau jabatan…',
                    onChanged: (v) => setState(() => _cari = v),
                  ),
                  AdminFilterDropdown(
                    value: _status,
                    items: _opsiStatus,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 34, color: T.textMuted),
                      SizedBox(height: 8),
                      Text('Tidak ada data yang cocok dengan filter.',
                          style: TextStyle(
                              fontSize: 11.5, color: T.textSecondary)),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, c) {
                    // Di layar sempit tabel 7 kolom tidak terbaca — ganti
                    // menjadi daftar kartu agar tidak perlu geser horizontal.
                    if (c.maxWidth < 760) {
                      return _DaftarKartu(data: data, onDetail: _bukaDetail);
                    }
                    return AdminTable(
                  lebarMinimal: 900,
                  flex: const [3, 1, 1, 1, 2, 2, 1],
                  kolom: const [
                    'Karyawan',
                    'Masuk',
                    'Pulang',
                    'Durasi',
                    'Lokasi',
                    'Status',
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
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(m.jamPulang,
                            style: const TextStyle(
                                fontSize: 12, color: T.textSecondary)),
                        Text(m.durasi,
                            style: const TextStyle(
                                fontSize: 11.5, color: T.textSecondary)),
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
                        AdminTextAction(
                          label: 'Detail',
                          onTap: () => _bukaDetail(context, m),
                        ),
                      ],
                  ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _ekspor(List<BarisMonitoring> data) async {
    final baris = <List<String>>[
      ['Nama', 'Jabatan', 'Tanggal', 'Jam Masuk', 'Jam Pulang', 'Durasi',
        'Lokasi', 'Status', 'Keterangan'],
      for (final m in data)
        [
          m.nama,
          m.jabatan,
          tanggalSingkat(m.tanggal),
          m.jamMasuk,
          m.jamPulang,
          m.durasi,
          m.lokasi,
          m.status.label,
          m.keterangan,
        ],
    ];
    final nama =
        'tipsen-monitoring-${DateTime.now().toIso8601String().split('T').first}.csv';
    await unduhCsv(nama, baris);
    if (!mounted) return;
    showToast(context, 'Log presensi diunduh (${data.length} baris).',
        ToastKind.success);
  }

  void _bukaDetail(BuildContext context, BarisMonitoring m) {
    showAdminDialog<void>(
      context,
      maxWidth: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminEmployeeCell(
                  inisial: m.inisial,
                  nama: m.nama,
                  subjudul: '${m.jabatan} · ${tanggalPanjang(m.tanggal)}',
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Kotak(
                  label: 'Jam masuk',
                  nilai: m.jamMasuk,
                  warna: T.green,
                  bg: T.greenBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Kotak(
                  label: 'Jam pulang',
                  nilai: m.jamPulang,
                  warna: T.red,
                  bg: T.redBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Kotak(
                  label: 'Durasi',
                  nilai: m.durasi,
                  warna: T.accent,
                  bg: T.blueBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _BarisDetail(label: 'Status', nilai: m.status.label),
          _BarisDetail(label: 'Lokasi', nilai: m.lokasi),
          _BarisDetail(
            label: 'Jarak dari kantor',
            nilai: m.jarakMeter >= 1000
                ? '${(m.jarakMeter / 1000).toStringAsFixed(1)} km'
                : '${m.jarakMeter} m',
          ),
          _BarisDetail(label: 'Keterangan', nilai: m.keterangan),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.canvas,
              borderRadius: BorderRadius.circular(T.rSm),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 16, color: T.accent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Presensi diverifikasi melalui selfie dan titik lokasi '
                    'perangkat karyawan.',
                    style: TextStyle(
                        fontSize: 11, height: 1.5, color: T.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.nilai,
    required this.warna,
    required this.bg,
  });

  final String label;
  final int nilai;
  final Color warna;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: warna.withValues(alpha: 0.25)),
      ),
      child: Row(
        // min: chip mengikuti lebar isinya, bukan memenuhi lebar halaman.
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$nilai',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: warna)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: T.textSecondary)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(T.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, color: T.textSecondary)),
          const SizedBox(height: 3),
          Text(nilai,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w800, color: warna)),
        ],
      ),
    );
  }
}

class _BarisDetail extends StatelessWidget {
  const _BarisDetail({required this.label, required this.nilai});

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
            width: 120,
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

/// Tampilan alternatif tabel untuk layar sempit (< 760 px).
class _DaftarKartu extends StatelessWidget {
  const _DaftarKartu({required this.data, required this.onDetail});

  final List<BarisMonitoring> data;
  final void Function(BuildContext, BarisMonitoring) onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < data.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _KartuBaris(
            m: data[i],
            onDetail: () => onDetail(context, data[i]),
          ),
        ],
      ],
    );
  }
}

class _KartuBaris extends StatelessWidget {
  const _KartuBaris({required this.m, required this.onDetail});

  final BarisMonitoring m;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 8),
              AppBadge(
                m.status.label,
                tone: switch (m.status) {
                  StatusPresensi.hadir => AppBadgeTone.green,
                  StatusPresensi.terlambat => AppBadgeTone.amber,
                  StatusPresensi.wfh => AppBadgeTone.blue,
                  StatusPresensi.izinDisetujui => AppBadgeTone.slate,
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Sel(label: 'Masuk', nilai: m.jamMasuk),
              _Sel(label: 'Pulang', nilai: m.jamPulang),
              _Sel(label: 'Durasi', nilai: m.durasi),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 13, color: T.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${m.lokasi} · ${m.jarakMeter} m',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: T.textSecondary),
                ),
              ),
              AdminTextAction(label: 'Detail', onTap: onDetail),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sel extends StatelessWidget {
  const _Sel({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: T.textMuted)),
          const SizedBox(height: 2),
          Text(nilai,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: T.text)),
        ],
      ),
    );
  }
}
