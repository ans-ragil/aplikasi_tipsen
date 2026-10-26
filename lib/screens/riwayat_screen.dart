import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// Halaman Riwayat: filter Semua | Hadir | Izin + ringkasan + daftar.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, this.filterAwal = RiwayatFilter.semua});

  final RiwayatFilter filterAwal;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late RiwayatFilter _filter = widget.filterAwal;

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

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subjudul,
                style: const TextStyle(fontSize: 12, color: T.textSecondary)),
            const SizedBox(height: 14),

            // ── Periode ───────────────────────────────────────
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      size: 18, color: T.accent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Periode: Bulan ini',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  Text('${entri.length} catatan',
                      style: const TextStyle(
                          fontSize: 12, color: T.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter tab ────────────────────────────────────
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

            // ── Daftar / keadaan kosong ───────────────────────
            if (entri.isEmpty)
              const _KeadaanKosong()
            else
              ...entri.map((e) => Padding(
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
                  )),
            const SizedBox(height: 8),
            AppButton(
              label: 'Unduh Laporan Bulan Ini',
              icon: Icons.download_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => showToast(
                  context, 'Laporan sedang disiapkan (simulasi).', ToastKind.info),
            ),
          ],
        ),
      ),
    );
  }

  List<_Entri> _susunEntri(AppState app) {
    final list = <_Entri>[];
    switch (_filter) {
      case RiwayatFilter.semua:
        list.addAll(app.riwayat.map(_Entri.presensi));
        list.addAll(app.pengajuan.map(_Entri.izin));
      case RiwayatFilter.hadir:
        list.addAll(app.riwayat.map(_Entri.presensi));
      case RiwayatFilter.izin:
        list.addAll(app.pengajuan.map(_Entri.izin));
    }
    list.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return list;
  }
}

// ═══════════════════════════════════════════════════════════════
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
                Text(p.tanggalPendek.split(' ').last,
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
                  p.clockIn == null
                      ? 'Belum ada catatan jam'
                      : 'Masuk ${p.clockIn} · Pulang ${p.clockOut ?? '—'}',
                  style:
                      const TextStyle(fontSize: 11, color: T.textSecondary),
                ),
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
                Text(p.periodeLabel,
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
  const _KeadaanKosong();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 38, color: T.textMuted),
          SizedBox(height: 10),
          Text('Belum ada catatan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Catatan presensi dan pengajuan Anda akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: T.textSecondary),
          ),
        ],
      ),
    );
  }
}
