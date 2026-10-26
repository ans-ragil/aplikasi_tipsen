import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';

/// Detail satu catatan presensi (halaman turunan — punya tombol kembali).
class DetailPresensiScreen extends StatelessWidget {
  const DetailPresensiScreen({super.key, required this.presensi});

  final Presensi presensi;

  String get _durasi {
    final masuk = presensi.clockIn;
    final pulang = presensi.clockOut;
    if (masuk == null || pulang == null) return '—';
    final m1 = int.parse(masuk.split(':')[0]) * 60 + int.parse(masuk.split(':')[1]);
    final m2 = int.parse(pulang.split(':')[0]) * 60 + int.parse(pulang.split(':')[1]);
    final d = m2 - m1;
    if (d <= 0) return '—';
    return '${d ~/ 60} jam ${d % 60} menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Detail Presensi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.margin, 4, T.margin, 28),
            children: [
              // ── Ringkasan ───────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: T.heroGradient,
                  borderRadius: BorderRadius.circular(T.rXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(presensi.status.label, tone: AppBadgeTone.onHero),
                    const SizedBox(height: 12),
                    Text(presensi.tanggalLabel,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      presensi.keterangan ?? 'Presensi tercatat di sistem TIPSEN.',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFDCE7FF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Waktu ───────────────────────────────────
              const SectionLabel('Waktu Presensi'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _KartuWaktu(
                      label: 'Clock In',
                      nilai: presensi.clockIn ?? '—',
                      ikon: Icons.login_rounded,
                      tone: T.green,
                      bg: T.greenBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _KartuWaktu(
                      label: 'Clock Out',
                      nilai: presensi.clockOut ?? '—',
                      ikon: Icons.logout_rounded,
                      tone: T.red,
                      bg: T.redBg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Rincian ─────────────────────────────────
              const SectionLabel('Rincian'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: T.card,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: T.border),
                ),
                child: Column(
                  children: [
                    InfoTile(label: 'Durasi kerja', value: _durasi),
                    const Divider(height: 1),
                    InfoTile(label: 'Status', value: presensi.status.label),
                    const Divider(height: 1),
                    InfoTile(label: 'Lokasi', value: presensi.lokasiNama),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Jarak dari kantor',
                        value: presensi.jarakMeter >= 1000
                            ? '${(presensi.jarakMeter / 1000).toStringAsFixed(1)} km'
                            : '${presensi.jarakMeter} m'),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Validasi radius',
                        value: presensi.dalamRadius
                            ? 'Di dalam radius kantor'
                            : 'Di luar radius (WFH)'),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Verifikasi selfie',
                        value: presensi.selfie ? 'Tersedia' : 'Tidak tersedia'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Bukti selfie (simulasi) ──────────────────
              const SectionLabel('Bukti Verifikasi'),
              const SizedBox(height: 8),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFDCE8FF),
                        border: Border.all(
                            color: presensi.selfie
                                ? const Color(0xFF34D399)
                                : T.border,
                            width: 3),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.person_rounded,
                          size: 30, color: T.navy),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Foto selfie presensi',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text(
                            'Foto diambil saat presensi (data simulasi, '
                            'tidak menampilkan wajah asli).',
                            style: TextStyle(
                                fontSize: 11.5,
                                color: T.textSecondary,
                                height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Tutup',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuWaktu extends StatelessWidget {
  const _KartuWaktu({
    required this.label,
    required this.nilai,
    required this.ikon,
    required this.tone,
    required this.bg,
  });

  final String label;
  final String nilai;
  final IconData ikon;
  final Color tone;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(ikon, size: 15, color: tone),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5, color: T.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(nilai,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
