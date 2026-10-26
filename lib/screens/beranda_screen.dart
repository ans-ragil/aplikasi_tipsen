import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'pengajuan_screen.dart';
import 'shell_screen.dart';

/// Halaman Beranda: hero jam real-time, ringkasan bulan, dan menu cepat.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({
    super.key,
    required this.onBukaProfil,
    required this.onBukaRiwayat,
    required this.onBukaPresensi,
  });

  final VoidCallback onBukaProfil;
  final void Function(RiwayatFilter) onBukaRiwayat;
  final VoidCallback onBukaPresensi;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _jamLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}:'
      '${t.second.toString().padLeft(2, '0')}';

  String _tanggalLabel(DateTime t) {
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${hari[t.weekday - 1]}, ${t.day} ${bulan[t.month]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;
    final jam = _jamLabel(_now);

    // Teks status & aksi sesuai langkah presensi.
    final (statusTeks, labelTombol, ikonTombol) = switch (app.langkah) {
      LangkahPresensi.belumClockIn => (
          'Anda belum melakukan presensi hari ini',
          'Clock In Sekarang',
          Icons.fingerprint_rounded
        ),
      LangkahPresensi.sudahClockIn => (
          'Clock In tercatat pukul ${app.presensiHariIni?.clockIn ?? '-'} — jangan lupa Clock Out',
          'Clock Out Sekarang',
          Icons.logout_rounded
        ),
      LangkahPresensi.sudahClockOut => (
          'Presensi hari ini lengkap. Terima kasih!',
          'Lihat Riwayat Presensi',
          Icons.history_rounded
        ),
    };

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar: sapaan + avatar ─────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${_namaPertama(user.nama)} 👋',
                          style: const TextStyle(
                              fontSize: 12, color: T.textSecondary)),
                      const SizedBox(height: 2),
                      Text(user.nama,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.onBukaProfil,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: T.blueBg,
                      border: Border.all(color: T.accent, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(user.inisial,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: T.accent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Hero card: jam real-time ─────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: T.heroGradient,
                borderRadius: BorderRadius.circular(T.rXl),
                boxShadow: [
                  BoxShadow(
                    color: T.navy.withValues(alpha: 0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppBadge(user.jadwal, tone: AppBadgeTone.onHero),
                      Text(_tanggalLabel(_now),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFCBDCFF))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(jam,
                      style: const TextStyle(
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1)),
                  const SizedBox(height: 6),
                  Text(statusTeks,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDCE7FF))),
                  const SizedBox(height: 14),
                  _TombolHero(
                    label: labelTombol,
                    ikon: ikonTombol,
                    onTap: _aksiHero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Ringkasan bulan ini ──────────────────────────
            const SectionLabel('Ringkasan Bulan Ini'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Hadir',
                    value: '${app.jumlahHadirBulanIni} hari',
                    note: 'Presensi tercatat bulan ini',
                    tone: StatTone.green,
                    onTap: () => widget.onBukaRiwayat(RiwayatFilter.hadir),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Izin / Cuti',
                    value: '${app.jumlahIzinDisetujui} disetujui',
                    note: '${app.jumlahMenunggu} pengajuan menunggu',
                    tone: StatTone.blue,
                    onTap: () => widget.onBukaRiwayat(RiwayatFilter.izin),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Menu cepat ───────────────────────────────────
            const SectionLabel('Menu Cepat'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MenuCepat(
                    ikon: Icons.fingerprint_rounded,
                    judul: 'Presensi Kehadiran',
                    ket: 'Clock In / Out dengan\nselfie & lokasi',
                    onTap: widget.onBukaPresensi,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MenuCepat(
                    ikon: Icons.event_note_rounded,
                    judul: 'Pengajuan Izin',
                    ket: 'Ajukan cuti / izin\nsecara online',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PengajuanScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _aksiHero() {
    final app = context.read<AppState>();
    switch (app.langkah) {
      case LangkahPresensi.belumClockIn:
      case LangkahPresensi.sudahClockIn:
        widget.onBukaPresensi();
      case LangkahPresensi.sudahClockOut:
        widget.onBukaRiwayat(RiwayatFilter.hadir);
    }
  }

  String _namaPertama(String nama) => nama.split(' ').first;
}

/// Tombol putih di atas hero card (kontras dengan gradien navy).
class _TombolHero extends StatelessWidget {
  const _TombolHero({required this.label, required this.ikon, required this.onTap});

  final String label;
  final IconData ikon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: T.buttonHeight,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: T.navy,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(T.rMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Kartu menu cepat 2 kolom.
class _MenuCepat extends StatelessWidget {
  const _MenuCepat({
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
      borderRadius: BorderRadius.circular(T.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rLg),
            border: Border.all(color: T.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: T.blueBg,
                  borderRadius: BorderRadius.circular(T.rMd),
                ),
                child: Icon(ikon, size: 19, color: T.accent),
              ),
              const Spacer(),
              Text(judul,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(ket,
                  style: const TextStyle(fontSize: 11, color: T.textMuted, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
