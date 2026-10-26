import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Live Tracking & Geofence: peta simulasi + pengaturan radius kantor.
class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  double _radius = 50;

  @override
  void initState() {
    super.initState();
    _radius = context.read<AppState>().geofence.radiusMeter.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.monitoringHariIni;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Live Tracking & Geofence',
          subtitle:
              'Pantau posisi presensi karyawan terhadap area kantor yang ditetapkan.',
          actions: [
            AppBadge('Radius ${app.geofence.radiusMeter} m',
                tone: AppBadgeTone.blue),
            AppButton(
              label: 'Simpan Konfigurasi',
              icon: Icons.save_rounded,
              expand: false,
              height: 40,
              onPressed: () {
                app.aturRadius(_radius.round());
                showToast(
                    context,
                    'Radius geofence disimpan: ${_radius.round()} meter.',
                    ToastKind.success);
              },
            ),
          ],
        ),
        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 980;
            final peta = AdminPanel(
              title: 'Peta Area Kantor',
              subtitle: app.geofence.namaKantor,
              trailing: AppBadge(
                '${app.geofence.latitude.toStringAsFixed(4)}, '
                '${app.geofence.longitude.toStringAsFixed(4)}',
                tone: AppBadgeTone.slate,
              ),
              child: Column(
                children: [
                  _Peta(
                    radius: _radius,
                    jumlahDalam: data
                        .where((m) =>
                            m.status != StatusPresensi.wfh &&
                            m.status != StatusPresensi.izinDisetujui)
                        .length,
                    jumlahLuar: data
                        .where((m) => m.status == StatusPresensi.wfh)
                        .length,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, size: 16, color: T.accent),
                      const SizedBox(width: 8),
                      const Text('Radius geofence',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      Expanded(
                        child: Slider(
                          value: _radius.clamp(20, 200),
                          min: 20,
                          max: 200,
                          divisions: 18,
                          activeColor: T.accent,
                          label: '${_radius.round()} m',
                          onChanged: (v) {
                            setState(() => _radius = v);
                            context.read<AppState>().aturRadius(v.round());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 62,
                        child: Text('${_radius.round()} m',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Radius menentukan batas area presensi. Presensi di luar '
                          'radius otomatis dicatat sebagai WFH.',
                          style: const TextStyle(
                              fontSize: 11, color: T.textSecondary, height: 1.45),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          setState(() => _radius = 50);
                          context.read<AppState>().aturRadius(50);
                          showToast(context, 'Radius direset ke 50 meter.',
                              ToastKind.info);
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final daftar = AdminPanel(
              title: 'Status Posisi Karyawan',
              subtitle: '${data.length} karyawan terpantau hari ini.',
              child: data.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Belum ada data posisi hari ini.',
                            style: TextStyle(
                                fontSize: 11.5, color: T.textSecondary)),
                      ),
                    )
                  : Column(
                      children: [
                        for (final m in data)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: AdminEmployeeCell(
                                    inisial: m.inisial,
                                    nama: m.nama,
                                    subjudul: m.lokasi,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppBadge(
                                  m.status == StatusPresensi.wfh
                                      ? 'Luar radius'
                                      : 'Dalam radius',
                                  tone: m.status == StatusPresensi.wfh
                                      ? AppBadgeTone.red
                                      : AppBadgeTone.green,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            );

            if (!lebar) {
              return Column(
                children: [peta, const SizedBox(height: 16), daftar],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: peta),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: daftar),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Peta simulasi: grid jalan, lingkaran geofence, pin kantor & karyawan.
class _Peta extends StatelessWidget {
  const _Peta({
    required this.radius,
    required this.jumlahDalam,
    required this.jumlahLuar,
  });

  final double radius;
  final int jumlahDalam;
  final int jumlahLuar;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(T.rLg),
      child: Container(
        height: 320,
        decoration: const BoxDecoration(color: Color(0xFF101A2B)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PetaPainter(radiusMeter: radius),
              ),
            ),
            // Pin kantor
            const Align(
              alignment: Alignment.center,
              child: _PinKantor(),
            ),
            // Pin karyawan (posisi tetap untuk simulasi)
            const Positioned(
                left: 60, top: 70, child: _PinKaryawan(label: 'FH', dalam: true)),
            const Positioned(
                right: 70, top: 110, child: _PinKaryawan(label: 'NS', dalam: true)),
            const Positioned(
                left: 90, bottom: 56, child: _PinKaryawan(label: 'BN', dalam: true)),
            const Positioned(
                right: 54,
                bottom: 46,
                child: _PinKaryawan(label: 'RP', dalam: false)),
            // Legenda
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(T.rSm),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$jumlahDalam dalam radius · $jumlahLuar di luar',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Radius aktif ${radius.round()} m',
                        style: const TextStyle(
                            fontSize: 9.5, color: Color(0xFF8FA3C0))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetaPainter extends CustomPainter {
  _PetaPainter({required this.radiusMeter});

  final double radiusMeter;

  @override
  void paint(Canvas canvas, Size size) {
    final tengah = Offset(size.width / 2, size.height / 2);

    // Latar
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF101A2B));

    // Grid
    final grid = Paint()
      ..color = const Color(0xFF1C2A42)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Jalan
    final jalan = Paint()
      ..color = const Color(0xFF243552)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.34),
        Offset(size.width, size.height * 0.42), jalan);
    canvas.drawLine(Offset(size.width * 0.28, 0),
        Offset(size.width * 0.34, size.height), jalan);
    canvas.drawLine(Offset(0, size.height * 0.76),
        Offset(size.width, size.height * 0.68), jalan);

    // Lingkaran geofence
    final skala = size.width / 420;
    final r = (18 + radiusMeter * 0.62) * skala;
    canvas.drawCircle(
      tengah,
      r,
      Paint()..color = const Color(0xFF2E7DFF).withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      tengah,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF4F9BFF),
    );
    // Garis bantu
    final garis = Paint()
      ..color = const Color(0xFF4F9BFF).withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(tengah - Offset(r, 0), tengah + Offset(r, 0), garis);
    canvas.drawLine(tengah - Offset(0, r), tengah + Offset(0, r), garis);
    // Titik pusat
    canvas.drawCircle(tengah, 5, Paint()..color = const Color(0xFF4F9BFF));
    canvas.drawCircle(
      tengah,
      10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF4F9BFF).withValues(alpha: 0.6),
    );
    // Aksen sudut
    final sudut = Paint()..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2), 26, sudut);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.72),
        math.min(30, size.width * 0.08), sudut);
  }

  @override
  bool shouldRepaint(_PetaPainter oldDelegate) =>
      oldDelegate.radiusMeter != radiusMeter;
}

class _PinKantor extends StatelessWidget {
  const _PinKantor();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF4F9BFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F9BFF).withValues(alpha: 0.6),
                blurRadius: 14,
              ),
            ],
          ),
          child: const Icon(Icons.business_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text('Kantor',
              style: TextStyle(fontSize: 8.5, color: Colors.white)),
        ),
      ],
    );
  }
}

class _PinKaryawan extends StatelessWidget {
  const _PinKaryawan({required this.label, required this.dalam});

  final String label;
  final bool dalam;

  @override
  Widget build(BuildContext context) {
    final warna = dalam ? const Color(0xFF34D399) : const Color(0xFFF87171);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: warna,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.6),
            boxShadow: [
              BoxShadow(color: warna.withValues(alpha: 0.5), blurRadius: 10),
            ],
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1220))),
        ),
      ],
    );
  }
}
