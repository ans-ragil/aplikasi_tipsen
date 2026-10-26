import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/berkas/unduh.dart';
import '../../core/csv.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Laporan & Ekspor Data: rekap kehadiran per periode, ekspor CSV/PDF.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  PeriodeLaporan _periode = PeriodeLaporan.bulanIni;
  String _departemen = 'Semua departemen';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final semuaRekap = app.rekap(_periode);
    final data = _departemen == 'Semua departemen'
        ? semuaRekap
        : semuaRekap.where((r) => r.departemen == _departemen).toList();

    final daftarDepartemen = [
      'Semua departemen',
      ...{for (final k in app.karyawanAdmin) k.departemen},
    ];

    final totalCatatan = data.fold<int>(0, (t, r) => t + r.totalMasuk);
    final totalMenit = data.fold<int>(0, (t, r) => t + r.totalMenitKerja);
    final rataPersen = data.isEmpty
        ? 0
        : (data.fold<int>(0, (t, r) => t + r.persen) / data.length).round();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Laporan & Ekspor Data',
          subtitle:
              'Rekap kehadiran periode ${_periode.label.toLowerCase()} · '
              '${data.length} karyawan.',
          actions: [
            AppButton(
              label: 'Ekspor CSV',
              icon: Icons.table_view_rounded,
              expand: false,
              height: 40,
              onPressed: () => _eksporCsv(data),
            ),
            AppButton(
              label: 'Cetak / PDF',
              icon: Icons.picture_as_pdf_rounded,
              variant: AppButtonVariant.secondary,
              expand: false,
              height: 40,
              onPressed: () {
                showToast(context,
                    'Dialog cetak dibuka — pilih "Save as PDF".', ToastKind.info);
                cetakHalaman();
              },
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── Filter ──────────────────────────────────────────
        AdminPanel(
          title: 'Filter Laporan',
          subtitle: 'Perubahan filter langsung memperbarui tabel & ringkasan.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminFilterDropdown(
                value: _periode.label,
                items: [for (final p in PeriodeLaporan.values) p.label],
                onChanged: (v) => setState(() {
                  _periode = PeriodeLaporan.values
                      .firstWhere((p) => p.label == v);
                }),
              ),
              AdminFilterDropdown(
                value: _departemen,
                items: daftarDepartemen,
                onChanged: (v) => setState(() => _departemen = v),
              ),
              AppBadge(
                '${app.hariKerjaPeriode(_periode)} hari kerja',
                tone: AppBadgeTone.slate,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Ringkasan ───────────────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final kolom = c.maxWidth > 900 ? 3 : 1;
            return GridView.count(
              crossAxisCount: kolom,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: kolom == 1 ? 3.6 : 2.4,
              children: [
                StatCard(
                  label: 'Total Kehadiran',
                  value: '$totalCatatan catatan',
                  note: 'Akumulasi ${_periode.label.toLowerCase()}',
                  tone: StatTone.blue,
                ),
                StatCard(
                  label: 'Total Jam Kerja',
                  value: durasiLabel(totalMenit),
                  note: 'Dari ${data.length} karyawan',
                  tone: StatTone.slate,
                ),
                StatCard(
                  label: 'Rata-rata Kehadiran',
                  value: '$rataPersen%',
                  note: 'Target minimal 95%',
                  tone: rataPersen >= 95 ? StatTone.green : StatTone.amber,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Tabel rekap ─────────────────────────────────────
        AdminPanel(
          title: 'Rekap Kehadiran Karyawan',
          subtitle:
              '${_periode.label} · ${data.length} karyawan · '
              'rata-rata masuk ${app.rataJamMasuk}',
          trailing: AdminTextAction(
            label: 'Ekspor CSV',
            onTap: () => _eksporCsv(data),
          ),
          child: data.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('Belum ada data pada periode ini.',
                        style: TextStyle(
                            fontSize: 11.5, color: T.textSecondary)),
                  ),
                )
              : AdminTable(
                  lebarMinimal: 880,
                  flex: const [3, 1, 1, 1, 2, 1, 1],
                  kolom: const [
                    'Karyawan',
                    'Hadir',
                    'Terlambat',
                    'Izin / WFH',
                    'Kehadiran',
                    'Rata Durasi',
                    'Aksi',
                  ],
                  baris: [
                    for (final r in data)
                      [
                        AdminEmployeeCell(
                          inisial: _inisial(r.nama),
                          nama: r.nama,
                          subjudul: '${r.jabatan} · ${r.departemen}',
                        ),
                        Text('${r.hadir}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('${r.terlambat}',
                            style: const TextStyle(
                                fontSize: 12, color: T.amber)),
                        Text('${r.izin} / ${r.wfh}',
                            style: const TextStyle(
                                fontSize: 11.5, color: T.textSecondary)),
                        _BarKehadiran(persen: r.persen),
                        Text(r.rataDurasi,
                            style: const TextStyle(
                                fontSize: 11, color: T.textSecondary)),
                        AdminTextAction(
                          label: 'Detail',
                          onTap: () => _bukaDetail(context, r),
                        ),
                      ],
                  ],
                ),
        ),
      ],
    );
  }

  String _inisial(String nama) {
    final p = nama.trim().split(RegExp(r'\s+'));
    if (p.length == 1) return p.first.substring(0, 2).toUpperCase();
    return (p.first[0] + p[1][0]).toUpperCase();
  }

  Future<void> _eksporCsv(List<RekapKaryawan> data) async {
    final baris = <List<String>>[
      [
        'Nama', 'Jabatan', 'Departemen', 'Hadir', 'Terlambat', 'WFH', 'Izin',
        'Total Masuk', 'Hari Kerja', 'Persen Kehadiran', 'Rata Durasi',
      ],
      for (final r in data)
        [
          r.nama,
          r.jabatan,
          r.departemen,
          '${r.hadir}',
          '${r.terlambat}',
          '${r.wfh}',
          '${r.izin}',
          '${r.totalMasuk}',
          '${r.totalHariKerja}',
          '${r.persen}%',
          r.rataDurasi,
        ],
    ];
    final label = _periode.label.toLowerCase().replaceAll(' ', '-');
    await unduhCsv('tipsen-laporan-$label.csv', baris);
    if (!mounted) return;
    showToast(context, 'Laporan CSV diunduh (${data.length} karyawan).',
        ToastKind.success);
  }

  void _bukaDetail(BuildContext context, RekapKaryawan r) {
    final app = context.read<AppState>();
    final catatan = app
        .presensiPeriode(_periode)
        .where((b) => b.nama == r.nama)
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    showAdminDialog<void>(
      context,
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AdminEmployeeCell(
                  inisial: _inisial(r.nama),
                  nama: r.nama,
                  subjudul: '${r.jabatan} · ${r.departemen}',
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Kotak(
                  label: 'Hadir',
                  nilai: '${r.hadir}',
                  warna: T.green,
                  bg: T.greenBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Kotak(
                  label: 'Terlambat',
                  nilai: '${r.terlambat}',
                  warna: T.amber,
                  bg: T.amberBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Kotak(
                  label: 'Kehadiran',
                  nilai: '${r.persen}%',
                  warna: T.accent,
                  bg: T.blueBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Rincian catatan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (catatan.isEmpty)
            const Text('Tidak ada catatan pada periode ini.',
                style: TextStyle(fontSize: 11.5, color: T.textSecondary))
          else
            for (final b in catatan.take(14))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(tanggalPendek(b.tanggal),
                          style: const TextStyle(
                              fontSize: 11, color: T.textSecondary)),
                    ),
                    SizedBox(
                      width: 74,
                      child: Text('${b.jamMasuk}–${b.jamPulang}',
                          style: const TextStyle(fontSize: 11)),
                    ),
                    Expanded(
                      child: Text(b.status.label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: b.status == StatusPresensi.hadir
                                  ? T.green
                                  : (b.status == StatusPresensi.terlambat
                                      ? T.amber
                                      : T.textSecondary))),
                    ),
                    Text(b.durasi,
                        style: const TextStyle(
                            fontSize: 10.5, color: T.textMuted)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _BarKehadiran extends StatelessWidget {
  const _BarKehadiran({required this.persen});

  final int persen;

  @override
  Widget build(BuildContext context) {
    final warna = persen >= 95 ? T.green : (persen >= 85 ? T.amber : T.red);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (persen / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFEDF0F5),
              valueColor: AlwaysStoppedAnimation(warna),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$persen%',
            style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800, color: warna)),
      ],
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
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: warna)),
        ],
      ),
    );
  }
}
