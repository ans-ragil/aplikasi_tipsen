import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/csv.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'detail_pengajuan_screen.dart';
import 'detail_presensi_screen.dart';
import 'shell_screen.dart';

/// Satu baris gabungan pada daftar riwayat (presensi atau pengajuan izin).
class _Entri {
  _Entri.presensi(Presensi p)
      : presensi = p,
        pengajuan = null,
        tanggal = p.tanggal;
  _Entri.izin(PengajuanIzin p)
      : presensi = null,
        pengajuan = p,
        tanggal = p.tanggalMulai;

  final Presensi? presensi;
  final PengajuanIzin? pengajuan;
  final DateTime tanggal;
}

/// Halaman Riwayat: filter periode bulan + filter status + daftar + unduh CSV.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, this.filterAwal = RiwayatFilter.semua});

  final RiwayatFilter filterAwal;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late RiwayatFilter _filter = widget.filterAwal;

  /// null = semua periode.
  DateTime? _periode = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final entri = _susunEntri(app);

    final (judul, subjudul) = switch (_filter) {
      RiwayatFilter.semua => (
          'Riwayat Presensi',
          'Semua aktivitas kehadiran dan pengajuan Anda.'
        ),
      RiwayatFilter.hadir => (
          'Riwayat Kehadiran',
          'Catatan presensi yang sudah tercatat.'
        ),
      RiwayatFilter.izin => (
          'Riwayat Izin & Cuti',
          'Pengajuan izin beserta status persetujuannya.'
        ),
    };

    final totalMenit = entri.fold<int>(
        0, (t, e) => t + (e.presensi?.durasiMenit ?? 0));
    final grup = _kelompokkan(entri);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subjudul,
                style: const TextStyle(fontSize: 12, color: T.textSecondary)),
            const SizedBox(height: 14),

            // ── Pemilih periode ──────────────────────────────
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => _pilihPeriode(context),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: T.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Periode',
                            style: TextStyle(
                                fontSize: 10.5, color: T.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          _periode == null
                              ? 'Semua periode'
                              : bulanTahun(_periode!),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text('${entri.length} catatan',
                      style: const TextStyle(
                          fontSize: 11.5, color: T.textSecondary)),
                  const SizedBox(width: 6),
                  const Icon(Icons.expand_more_rounded,
                      size: 20, color: T.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Ringkasan periode ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _RingkasanKecil(
                    ikon: Icons.event_available_rounded,
                    label: 'Catatan presensi',
                    nilai:
                        '${entri.where((e) => e.presensi != null).length} hari',
                    warna: T.green,
                    bg: T.greenBg,
                  ),
                ),                const SizedBox(width: 8),
                Expanded(
                  child: _RingkasanKecil(
                    ikon: Icons.timer_outlined,
                    label: 'Total jam kerja',
                    nilai: totalMenit == 0 ? '—' : durasiLabel(totalMenit),
                    warna: T.accent,
                    bg: T.blueBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Filter tab ───────────────────────────────────
            Row(
              children: [
                _TabFilter(
                  label: 'Semua',
                  aktif: _filter == RiwayatFilter.semua,
                  onTap: () => setState(() => _filter = RiwayatFilter.semua),
                ),
                const SizedBox(width: 8),
                _TabFilter(
                  label: 'Hadir',
                  aktif: _filter == RiwayatFilter.hadir,
                  onTap: () => setState(() => _filter = RiwayatFilter.hadir),
                ),
                const SizedBox(width: 8),
                _TabFilter(
                  label: 'Izin',
                  aktif: _filter == RiwayatFilter.izin,
                  onTap: () => setState(() => _filter = RiwayatFilter.izin),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Daftar / keadaan kosong ──────────────────────
            if (entri.isEmpty)
              _KeadaanKosong(filter: _filter)
            else
              for (final g in grup) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Row(
                    children: [
                      Text(g.key.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: T.textMuted)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Container(height: 1, color: T.border)),
                      const SizedBox(width: 8),
                      Text('${g.value.length}',
                          style: const TextStyle(
                              fontSize: 10.5, color: T.textMuted)),
                    ],
                  ),
                ),
                for (final e in g.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: e.presensi != null
                        ? _ItemPresensi(
                            presensi: e.presensi!,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailPresensiScreen(presensi: e.presensi!),
                              ),
                            ),
                          )
                        : _ItemIzin(
                            pengajuan: e.pengajuan!,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetailPengajuanScreen(
                                    pengajuan: e.pengajuan!),
                              ),
                            ),
                          ),
                  ),
              ],
            const SizedBox(height: 10),
            AppButton(
              label: 'Unduh Riwayat (CSV)',
              icon: Icons.download_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: entri.isEmpty ? null : () => _unduh(app, entri),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Berkas CSV dapat dibuka di Excel atau Google Sheets.',
                style: TextStyle(fontSize: 10.5, color: T.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Susun data ─────────────────────────────────────────────
  List<_Entri> _susunEntri(AppState app) {
    final list = <_Entri>[];
    bool cocok(DateTime d) =>
        _periode == null ||
        (d.year == _periode!.year && d.month == _periode!.month);

    switch (_filter) {
      case RiwayatFilter.semua:
        list.addAll(app.riwayat.where((r) => cocok(r.tanggal)).map(_Entri.presensi));
        list.addAll(app
            .pengajuanSaya()
            .where((p) => cocok(p.tanggalMulai))
            .map(_Entri.izin));
      case RiwayatFilter.hadir:
        list.addAll(app.riwayat.where((r) => cocok(r.tanggal)).map(_Entri.presensi));
      case RiwayatFilter.izin:
        list.addAll(app
            .pengajuanSaya()
            .where((p) => cocok(p.tanggalMulai))
            .map(_Entri.izin));
    }
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list;
  }

  /// Kelompokkan per bulan, urut dari yang terbaru.
  List<MapEntry<String, List<_Entri>>> _kelompokkan(List<_Entri> entri) {
    final map = <String, List<_Entri>>{};
    for (final e in entri) {
      final k = bulanTahun(e.tanggal);
      map.putIfAbsent(k, () => []).add(e);
    }
    return map.entries.toList();
  }

  // ── Aksi ───────────────────────────────────────────────────
  Future<void> _pilihPeriode(BuildContext context) async {
    final app = context.read<AppState>();
    final now = DateTime.now();
    final opsi = <DateTime?>[null];
    for (var i = 0; i < 12; i++) {
      opsi.add(DateTime(now.year, now.month - i));
    }
    // Sertakan bulan dari data bila lebih lama dari 12 bulan.
    for (final r in app.riwayat) {
      final b = DateTime(r.tanggal.year, r.tanggal.month);
      if (!opsi.any((o) => o != null && o.year == b.year && o.month == b.month)) {
        opsi.add(b);
      }
    }
    opsi.sort((a, b) {
      if (a == null) return -1;
      if (b == null) return 1;
      return b.compareTo(a);
    });

    final hasil = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: T.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rXl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 18, color: T.accent),
                  SizedBox(width: 8),
                  Text('Pilih Periode',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  for (final o in opsi)
                    ListTile(
                      dense: true,
                      title: Text(
                        o == null ? 'Semua periode' : bulanTahun(o),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _sama(o, _periode)
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: _sama(o, _periode) ? T.accent : T.text,
                        ),
                      ),
                      trailing: _sama(o, _periode)
                          ? const Icon(Icons.check_rounded,
                              size: 18, color: T.accent)
                          : null,
                      onTap: () => Navigator.of(ctx).pop(o ?? 'semua'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (hasil == null) return;
    setState(() {
      _periode = hasil == 'semua' ? null : hasil as DateTime;
    });
  }

  bool _sama(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month;
  }

  Future<void> _unduh(AppState app, List<_Entri> entri) async {
    final baris = <List<String>>[
      ['Tanggal', 'Jenis', 'Keterangan', 'Jam Masuk', 'Jam Pulang',
        'Durasi', 'Status', 'Lokasi'],
      for (final e in entri)
        if (e.presensi != null)
          [
            tanggalSingkat(e.presensi!.tanggal),
            'Presensi',
            e.presensi!.keterangan ?? '-',
            e.presensi!.clockIn ?? '-',
            e.presensi!.clockOut ?? '-',
            e.presensi!.durasi,
            e.presensi!.status.label,
            e.presensi!.lokasiNama,
          ]
        else
          [
            tanggalSingkat(e.pengajuan!.tanggalMulai),
            e.pengajuan!.jenis,
            e.pengajuan!.alasan,
            '-',
            '-',
            '${e.pengajuan!.jumlahHari} hari',
            e.pengajuan!.status.label,
            e.pengajuan!.lampiran?.nama ?? '-',
          ],
    ];
    final label = _periode == null
        ? 'semua-periode'
        : '${_periode!.year}-${_periode!.month.toString().padLeft(2, '0')}';
    await unduhCsv('tipsen-riwayat-$label.csv', baris);
    if (!mounted) return;
    showToast(context, 'Riwayat diunduh sebagai CSV (${entri.length} catatan).',
        ToastKind.success);
  }
}

// ═══════════════════════════════════════════════════════════════
class _RingkasanKecil extends StatelessWidget {
  const _RingkasanKecil({
    required this.ikon,
    required this.label,
    required this.nilai,
    required this.warna,
    required this.bg,
  });

  final IconData ikon;
  final String label;
  final String nilai;
  final Color warna;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: warna.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 17, color: warna),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: T.textSecondary)),
                const SizedBox(height: 2),
                Text(nilai,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: warna)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabFilter extends StatelessWidget {
  const _TabFilter({
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: aktif ? T.navy : T.card,
        borderRadius: BorderRadius.circular(T.rMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(T.rMd),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rMd),
              border: Border.all(color: aktif ? T.navy : T.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: aktif ? Colors.white : T.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemPresensi extends StatelessWidget {
  const _ItemPresensi({required this.presensi, required this.onTap});

  final Presensi presensi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = presensi;
    final badgeTone = switch (p.status) {
      StatusPresensi.hadir => AppBadgeTone.green,
      StatusPresensi.izinDisetujui => AppBadgeTone.blue,
      StatusPresensi.terlambat || StatusPresensi.wfh => AppBadgeTone.amber,
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: T.blueBg,
              borderRadius: BorderRadius.circular(T.rMd),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${p.tanggal.day}',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: T.accent)),
                Text(namaBulanPendek[p.tanggal.month],
                    style: const TextStyle(fontSize: 9, color: T.accent)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.tanggalLabel,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  'Masuk ${p.clockIn ?? '—'} · Pulang ${p.clockOut ?? '—'}',
                  style: const TextStyle(fontSize: 11, color: T.textSecondary),
                ),
                if (p.clockOut != null) ...[
                  const SizedBox(height: 2),
                  Text('Durasi kerja ${p.durasi}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: T.green)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppBadge(p.status.label, tone: badgeTone),
              const SizedBox(height: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: T.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemIzin extends StatelessWidget {
  const _ItemIzin({required this.pengajuan, required this.onTap});

  final PengajuanIzin pengajuan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = pengajuan;
    final tone = switch (p.status) {
      StatusPengajuan.disetujui => AppBadgeTone.green,
      StatusPengajuan.menunggu => AppBadgeTone.amber,
      StatusPengajuan.ditolak => AppBadgeTone.red,
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: T.amberBg,
              borderRadius: BorderRadius.circular(T.rMd),
            ),
            child: const Icon(Icons.event_note_rounded,
                size: 20, color: T.amber),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.jenis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${p.periodeLabel} · ${p.jumlahHari} hari',
                    style:
                        const TextStyle(fontSize: 11, color: T.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppBadge(p.status.label, tone: tone),
              const SizedBox(height: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: T.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeadaanKosong extends StatelessWidget {
  const _KeadaanKosong({required this.filter});

  final RiwayatFilter filter;

  @override
  Widget build(BuildContext context) {
    final (judul, ket) = switch (filter) {
      RiwayatFilter.semua => (
          'Belum ada catatan pada periode ini',
          'Catatan presensi dan pengajuan Anda akan tampil di sini.'
        ),
      RiwayatFilter.hadir => (
          'Belum ada presensi pada periode ini',
          'Lakukan presensi pada menu Presensi untuk mulai mencatat.'
        ),
      RiwayatFilter.izin => (
          'Belum ada pengajuan pada periode ini',
          'Ajukan cuti atau izin melalui menu Pengajuan Izin.'
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, size: 38, color: T.textMuted),
          const SizedBox(height: 10),
          Text(judul,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(ket,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: T.textSecondary)),
        ],
      ),
    );
  }
}
