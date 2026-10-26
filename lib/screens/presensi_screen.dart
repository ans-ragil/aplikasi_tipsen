import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'detail_presensi_screen.dart';

/// Halaman Presensi: selfie + validasi lokasi (geofence) — fase simulasi.
/// State machine: belum Clock In → sudah Clock In → sudah Clock Out.
class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
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

  String get _jam =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

  /// Lewat 08.15 dianggap berpotensi terlambat (jadwal shift pagi 08.00).
  bool get _lewatJamMasuk => _now.hour * 60 + _now.minute > 8 * 60 + 15;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Presensi Kehadiran',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Pastikan lokasi dan selfie Anda valid sebelum mengirim.',
                style: TextStyle(fontSize: 12, color: T.textSecondary)),
            const SizedBox(height: 16),

            // ── Panel waktu saat ini ─────────────────────────
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: T.blueBg,
                      borderRadius: BorderRadius.circular(T.rMd),
                    ),
                    child: const Icon(Icons.schedule_rounded,
                        size: 21, color: T.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Waktu saat ini',
                            style: TextStyle(
                                fontSize: 11, color: T.textSecondary)),
                        Text('$_jam WIB',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  AppBadge(
                    _lewatJamMasuk && app.langkah == LangkahPresensi.belumClockIn
                        ? 'Perhatian: lewat jam masuk'
                        : 'Tepat waktu',
                    tone: _lewatJamMasuk && app.langkah == LangkahPresensi.belumClockIn
                        ? AppBadgeTone.amber
                        : AppBadgeTone.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Area selfie (simulasi) ───────────────────────
            _AreaSelfie(siap: app.selfieSiap, onTap: app.ambilSelfie),
            const SizedBox(height: 16),

            // ── Kartu lokasi / geofence ──────────────────────
            _KartuLokasi(app: app),
            const SizedBox(height: 20),

            // ── Aksi utama sesuai state ──────────────────────
            _TombolUtama(app: app, jam: _jam),
            const SizedBox(height: 10),
            if (app.langkah != LangkahPresensi.belumClockIn)
              const Center(
                child: Text(
                  'Riwayat lengkap dapat dilihat pada menu Riwayat.',
                  style: TextStyle(fontSize: 11, color: T.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AREA SELFIE — simulasi kamera (nanti: image_picker)
// ═══════════════════════════════════════════════════════════════
class _AreaSelfie extends StatelessWidget {
  const _AreaSelfie({required this.siap, required this.onTap});

  final bool siap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 210),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(T.rXl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF131D30), Color(0xFF0C1220)],
          ),
          border: Border.all(
              color: T.accent.withValues(alpha: 0.55), width: 1.6),
        ),
        child: siap
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDCE8FF),
                      border: Border.all(color: const Color(0xFF34D399), width: 4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      app.pengguna.inisial,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: T.navy),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Foto selfie siap digunakan',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const Text('Ketuk untuk mengambil ulang',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9EABC0))),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF26344C),
                    ),
                    child: const Icon(Icons.photo_camera_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ambil Foto Selfie',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_rounded, size: 12, color: Color(0xFF9EABC0)),
                      SizedBox(width: 5),
                      Text('Kamera simulasi · mode demo',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9EABC0))),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KARTU LOKASI — simulasi GPS + geofence
// ═══════════════════════════════════════════════════════════════
class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({required this.app});

  final AppState app;

  String get _jarakLabel =>
      app.jarakMeter >= 1000
          ? '${(app.jarakMeter / 1000).toStringAsFixed(1)} km'
          : '${app.jarakMeter} m';

  @override
  Widget build(BuildContext context) {
    if (!app.lokasiDiizinkan) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: T.accent),
                SizedBox(width: 7),
                Text('Status Lokasi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Izinkan akses lokasi agar sistem dapat memverifikasi bahwa '
              'Anda berada di dalam radius kantor.',
              style: TextStyle(fontSize: 12, color: T.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: () {
                  app.mintaIzinLokasi();
                  showToast(context, 'Akses lokasi diberikan (simulasi).', ToastKind.success);
                },
                icon: const Icon(Icons.my_location_rounded, size: 17),
                label: const Text('Minta Izin Lokasi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: T.blueBg,
                  foregroundColor: T.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(T.rMd)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 18, color: T.accent),
                    SizedBox(width: 7),
                    Text('Lokasi Anda saat ini',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              AppBadge(
                app.dalamRadius ? 'Dalam Radius' : 'Luar Radius',
                tone: app.dalamRadius ? AppBadgeTone.green : AppBadgeTone.red,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(app.geofence.namaKantor,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '$_jarakLabel dari kantor · Radius ${app.geofence.radiusMeter} m',
            style: const TextStyle(fontSize: 12, color: T.textSecondary),
          ),
          if (!app.dalamRadius) ...[
            const SizedBox(height: 8),
            const Text(
              'Presensi di luar radius akan dicatat sebagai WFH.',
              style: TextStyle(fontSize: 12, color: T.amber, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => app.aturSimulasiLokasi(!app.dalamRadius),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              child: Text(
                app.dalamRadius
                    ? 'Simulasi: pindah ke luar radius'
                    : 'Simulasi: kembali ke kantor',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOMBOL UTAMA — state machine presensi
// ═══════════════════════════════════════════════════════════════
class _TombolUtama extends StatelessWidget {
  const _TombolUtama({required this.app, required this.jam});

  final AppState app;
  final String jam;

  @override
  Widget build(BuildContext context) {
    switch (app.langkah) {
      case LangkahPresensi.belumClockIn:
        return AppButton(
          label: 'Kirim Presensi Masuk',
          icon: Icons.fingerprint_rounded,
          onPressed: () => _kirimClockIn(context),
        );

      case LangkahPresensi.sudahClockIn:
        return AppButton(
          label: 'Clock Out Sekarang',
          icon: Icons.logout_rounded,
          variant: AppButtonVariant.success,
          onPressed: () => _kirimClockOut(context),
        );

      case LangkahPresensi.sudahClockOut:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: T.greenBg,
                borderRadius: BorderRadius.circular(T.rLg),
                border: Border.all(color: T.greenBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: T.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Presensi hari ini sudah lengkap (masuk & pulang tercatat).',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: T.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Clock Out Sudah Tercatat',
              icon: Icons.check_circle_rounded,
              onPressed: null,
            ),
          ],
        );
    }
  }

  void _kirimClockIn(BuildContext context) {
    if (!app.lokasiDiizinkan) {
      showToast(context, 'Izinkan akses lokasi terlebih dahulu.', ToastKind.error);
      return;
    }
    if (!app.selfieSiap) {
      showToast(context, 'Ambil foto selfie simulasi sebelum mengirim presensi.',
          ToastKind.error);
      return;
    }

    final catatan = app.catatClockIn(jam);
    showToast(
      context,
      app.dalamRadius
          ? 'Presensi masuk berhasil dicatat pada $jam di dalam radius kantor.'
          : 'Presensi dicatat sebagai WFH / luar radius (pukul $jam).',
      ToastKind.success,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailPresensiScreen(presensi: catatan),
      ),
    );
  }

  void _kirimClockOut(BuildContext context) {
    app.catatClockOut(jam);
    showToast(context, 'Clock Out berhasil dicatat pada $jam.', ToastKind.success);
  }
}
