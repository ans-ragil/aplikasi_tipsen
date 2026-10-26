import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'pengajuan_screen.dart';
import 'shell_screen.dart';

/// Halaman Beranda: hero jam real-time + status presensi hari ini,
/// ringkasan bulan berjalan, dan menu cepat.
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;
    final hariIni = app.presensiHariIni;
    final bulan = DateTime(_now.year, _now.month);

    // Durasi berjalan sejak Clock In (bila belum Clock Out).
    final menitBerjalan = hariIni?.clockIn == null
        ? 0
        : (_now.hour * 60 + _now.minute) - (menitDariJam(hariIni!.clockIn) ?? 0);

    final (statusTeks, labelTombol, ikonTombol) = switch (app.langkah) {
      LangkahPresensi.belumClockIn => (
          'Anda belum melakukan presensi hari ini',
          'Clock In Sekarang',
          Icons.fingerprint_rounded
        ),
      LangkahPresensi.sudahClockIn => (
          'Masuk ${hariIni?.clockIn} · durasi berjalan '
              '${durasiLabel(menitBerjalan)}',
          'Clock Out Sekarang',
          Icons.logout_rounded
        ),
      LangkahPresensi.sudahClockOut => (
          'Masuk ${hariIni?.clockIn} · Pulang ${hariIni?.clockOut} · '
              '${hariIni?.durasi ?? '—'}',
          'Lihat Riwayat Presensi',
          Icons.history_rounded
        ),
    };

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sapaan + avatar ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Halo, ${user.nama.split(' ').first} 👋',
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

            // ── Hero: jam + status presensi ──────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: T.heroGradient,
                borderRadius: BorderRadius.circular(T.rXl),
                boxShadow: [
                  BoxShadow(
                    color: T.navy.withValues(alpha: 0.32),
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
                      Flexible(
                        child: AppBadge(user.jadwal,
                            tone: AppBadgeTone.onHero),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(tanggalPanjang(_now),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFCBDCFF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(jamLengkap(_now),
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
                  if (hariIni != null && hariIni.clockOut == null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (menitBerjalan / 540).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF7DD3A8)),
                      ),
                    ),
                  ],
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
            Row(
              children: [
                const Expanded(child: SectionLabel('Ringkasan Bulan Ini')),
                Text(bulanTahun(bulan),
                    style:
                        const TextStyle(fontSize: 11, color: T.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Hadir',
                    value: '${app.hadirBulan(bulan)} hari',
                    note: '${app.terlambatBulan(bulan)} kali terlambat',
                    tone: StatTone.green,
                    onTap: () => widget.onBukaRiwayat(RiwayatFilter.hadir),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Izin / Cuti',
                    value: '${app.izinDisetujuiBulanIni} disetujui',
                    note: '${app.pengajuanMenunggu} pengajuan menunggu',
                    tone: StatTone.blue,
                    onTap: () => widget.onBukaRiwayat(RiwayatFilter.izin),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: T.amberBg,
                      borderRadius: BorderRadius.circular(T.rMd),
                    ),
                    child: const Icon(Icons.timer_outlined,
                        size: 18, color: T.amber),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Total jam kerja bulan ini',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  Text(durasiLabel(app.menitKerjaBulan(bulan)),
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: T.navy)),
                ],
              ),
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
                    judul: 'Presensi',
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
                      MaterialPageRoute(builder: (_) => const PengajuanScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MenuCepat(
                    ikon: Icons.history_rounded,
                    judul: 'Riwayat',
                    ket: 'Lihat catatan presensi\ndan status izin',
                    onTap: () => widget.onBukaRiwayat(RiwayatFilter.semua),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MenuCepat(
                    ikon: Icons.person_rounded,
                    judul: 'Profil Saya',
                    ket: 'Data akun, kata sandi,\ndan kebijakan privasi',
                    onTap: widget.onBukaProfil,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Kartu menu cepat.
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
          constraints: const BoxConstraints(minHeight: 116),
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
              const SizedBox(height: 10),
              Text(judul,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(ket,
                  style: const TextStyle(
                      fontSize: 11, color: T.textMuted, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
