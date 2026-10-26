import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/selfie_capture.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'detail_presensi_screen.dart';

/// Halaman Presensi: selfie + validasi lokasi (geofence).
/// Alur: belum Clock In → sudah Clock In → sudah Clock Out.
class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _memproses = false;

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

  String get _jam => jamMenit(_now);

  /// Sudah lewat batas masuk 08:15 dan belum presensi.
  bool get _lewatJamMasuk => _now.hour * 60 + _now.minute > 8 * 60 + 15;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hariIni = app.presensiHariIni;
    final menitBerjalan = hariIni?.clockIn == null
        ? 0
        : (_now.hour * 60 + _now.minute) - (menitDariJam(hariIni!.clockIn) ?? 0);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Presensi Kehadiran',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
                'Pastikan lokasi dan selfie Anda valid sebelum mengirim presensi.',
                style: TextStyle(fontSize: 12, color: T.textSecondary)),
            const SizedBox(height: 16),

            // ── Panel waktu ──────────────────────────────────
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
                  _BadgeWaktu(app: app, lewat: _lewatJamMasuk),
                ],
              ),
            ),

            // ── Ringkasan hari ini (setelah Clock In) ────────
            if (hariIni != null) ...[
              const SizedBox(height: 12),
              _RingkasanHariIni(
                presensi: hariIni,
                menitBerjalan: menitBerjalan,
              ),
            ],
            const SizedBox(height: 16),

            // ── Selfie (kamera asli + fallback) ──────────────
            if (app.langkah == LangkahPresensi.belumClockIn)
              SelfieCapture(
                foto: app.fotoSelfie,
                simulasiAktif: app.selfieSimulasi,
                onFoto: app.setFotoSelfie,
                onSimulasi: () {
                  app.ambilSelfie();
                  showToast(
                      context,
                      'Mode tanpa kamera aktif — presensi tetap dapat dikirim.',
                      ToastKind.info);
                },
              )
            else
              _KartuSelfieTercatat(presensi: hariIni!),
            const SizedBox(height: 16),

            // ── Lokasi ───────────────────────────────────────
            _KartuLokasi(app: app),
            const SizedBox(height: 20),

            // ── Aksi utama ───────────────────────────────────
            _TombolUtama(
              app: app,
              memproses: _memproses,
              onClockIn: _kirimClockIn,
              onClockOut: _kirimClockOut,
              onLihatDetail: () {
                final p = app.presensiHariIni;
                if (p == null) return;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DetailPresensiScreen(presensi: p)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _kirimClockIn() async {
    final app = context.read<AppState>();
    if (!app.lokasiDiizinkan) {
      showToast(context, 'Izinkan akses lokasi terlebih dahulu.', ToastKind.error);
      return;
    }
    if (!app.selfieSiap) {
      showToast(context, 'Ambil foto selfie terlebih dahulu.', ToastKind.error);
      return;
    }
    setState(() => _memproses = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final catatan = app.catatClockIn(_jam);
    setState(() => _memproses = false);
    showToast(
      context,
      switch (catatan.status) {
        StatusPresensi.wfh =>
          'Presensi dicatat sebagai WFH / luar radius pukul $_jam.',
        StatusPresensi.terlambat =>
          'Presensi tercatat pukul $_jam — status Terlambat.',
        _ => 'Presensi masuk berhasil dicatat pukul $_jam.',
      },
      catatan.status == StatusPresensi.terlambat
          ? ToastKind.info
          : ToastKind.success,
    );
  }

  Future<void> _kirimClockOut() async {
    final app = context.read<AppState>();
    setState(() => _memproses = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    final hasil = app.catatClockOut(_jam);
    setState(() => _memproses = false);
    if (hasil == null) {
      showToast(context, 'Belum ada presensi masuk hari ini.', ToastKind.error);
      return;
    }
    showToast(
      context,
      'Clock Out tercatat pukul $_jam · durasi kerja ${hasil.durasi}.',
      ToastKind.success,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _BadgeWaktu extends StatelessWidget {
  const _BadgeWaktu({required this.app, required this.lewat});

  final AppState app;
  final bool lewat;

  @override
  Widget build(BuildContext context) {
    if (app.langkah == LangkahPresensi.belumClockIn) {
      return lewat
          ? const AppBadge('Lewat jam masuk', tone: AppBadgeTone.amber)
          : const AppBadge('Tepat waktu', tone: AppBadgeTone.green);
    }
    final status = app.presensiHariIni?.status ?? StatusPresensi.hadir;
    return AppBadge(
      status.label,
      tone: switch (status) {
        StatusPresensi.hadir => AppBadgeTone.green,
        StatusPresensi.terlambat => AppBadgeTone.amber,
        StatusPresensi.wfh => AppBadgeTone.blue,
        StatusPresensi.izinDisetujui => AppBadgeTone.slate,
      },
    );
  }
}

/// Ringkasan jam masuk / pulang / durasi setelah presensi.
class _RingkasanHariIni extends StatelessWidget {
  const _RingkasanHariIni({
    required this.presensi,
    required this.menitBerjalan,
  });

  final Presensi presensi;
  final int menitBerjalan;

  @override
  Widget build(BuildContext context) {
    final lengkap = presensi.clockOut != null;
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
              const Icon(Icons.check_circle_rounded, size: 17, color: T.green),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  lengkap
                      ? 'Presensi hari ini lengkap'
                      : 'Anda sedang dalam jam kerja',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelWaktu(
                  label: 'Jam masuk',
                  nilai: presensi.clockIn ?? '—',
                  warna: T.green,
                  bg: T.greenBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelWaktu(
                  label: 'Jam pulang',
                  nilai: presensi.clockOut ?? '—',
                  warna: T.red,
                  bg: T.redBg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelWaktu(
                  label: lengkap ? 'Durasi kerja' : 'Durasi berjalan',
                  nilai: lengkap
                      ? presensi.durasi
                      : durasiLabel(menitBerjalan),
                  warna: T.accent,
                  bg: T.blueBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelWaktu extends StatelessWidget {
  const _SelWaktu({
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

/// Setelah Clock In, area selfie menampilkan bukti yang tersimpan.
class _KartuSelfieTercatat extends StatelessWidget {
  const _KartuSelfieTercatat({required this.presensi});

  final Presensi presensi;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          if (presensi.foto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(T.rMd),
              child: SizedBox(
                width: 62,
                height: 62,
                child: Image.memory(presensi.foto!, fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: T.greenBg,
                shape: BoxShape.circle,
                border: Border.all(color: T.greenBorder, width: 2),
              ),
              child: const Icon(Icons.check_rounded, color: T.green, size: 28),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selfie presensi tersimpan',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  presensi.foto != null
                      ? 'Foto dari kamera perangkat, tersimpan pada catatan presensi hari ini.'
                      : 'Presensi dicatat tanpa foto kamera (mode tanpa kamera).',
                  style: const TextStyle(
                      fontSize: 11.5, color: T.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({required this.app});

  final AppState app;

  String get _jarakLabel => app.jarakMeter >= 1000
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
              'Izinkan akses lokasi agar sistem dapat memverifikasi bahwa Anda '
              'berada di dalam radius kantor.',
              style: TextStyle(fontSize: 12, color: T.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: FilledButton.icon(
                onPressed: () {
                  app.mintaIzinLokasi();
                  showToast(context,
                      'Akses lokasi diberikan. Titik lokasi terdeteksi.',
                      ToastKind.success);
                },
                icon: const Icon(Icons.my_location_rounded, size: 17),
                label: const Text('Minta Izin Lokasi',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
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
          Text(app.dalamRadius ? app.geofence.namaKantor : 'Di luar area kantor',
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
              style: TextStyle(
                  fontSize: 12, color: T.amber, fontWeight: FontWeight.w600),
            ),
          ],
          if (app.langkah == LangkahPresensi.belumClockIn) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => app.aturSimulasiLokasi(!app.dalamRadius),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  textStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
                child: Text(
                  app.dalamRadius
                      ? 'Uji coba: pindah ke luar radius'
                      : 'Uji coba: kembali ke kantor',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _TombolUtama extends StatelessWidget {
  const _TombolUtama({
    required this.app,
    required this.memproses,
    required this.onClockIn,
    required this.onClockOut,
    required this.onLihatDetail,
  });

  final AppState app;
  final bool memproses;
  final VoidCallback onClockIn;
  final VoidCallback onClockOut;
  final VoidCallback onLihatDetail;

  @override
  Widget build(BuildContext context) {
    if (memproses) {
      return const SizedBox(
        height: T.buttonHeight,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: T.navy),
          ),
        ),
      );
    }

    switch (app.langkah) {
      case LangkahPresensi.belumClockIn:
        return AppButton(
          label: 'Kirim Presensi Masuk',
          icon: Icons.fingerprint_rounded,
          onPressed: onClockIn,
        );

      case LangkahPresensi.sudahClockIn:
        return Column(
          children: [
            AppButton(
              label: 'Clock Out Sekarang',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.success,
              onPressed: onClockOut,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan pekerjaan hari ini sudah selesai sebelum Clock Out.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: T.textMuted),
            ),
          ],
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
              label: 'Lihat Detail Presensi Hari Ini',
              icon: Icons.receipt_long_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: onLihatDetail,
            ),
          ],
        );
    }
  }
}
