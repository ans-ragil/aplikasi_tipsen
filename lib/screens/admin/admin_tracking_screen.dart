import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Live Tracking & Geofence: peta simulasi + pengaturan radius kantor.
class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  late double _radius = 50;

  @override
  void initState() {
    super.initState();
    _radius = context.read<AppState>().geofence.radiusMeter.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const AdminPageTitle(
          title: 'Live Tracking & Geofence',
          subtitle:
              'Pantau posisi karyawan terhadap radius kantor secara simulasi.',
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, c) {
            final lebar = c.maxWidth > 1000;
            final peta = _PetaKartu(radius: app.geofence.radiusMeter);
            final panel = Column(
              children: [
                _KartuPengaturan(
                  radius: _radius,
                  onUbah: (v) => setState(() => _radius = v),
                  onSimpan: () {
                    context.read<AppState>().aturRadius(_radius.round());
                    showToast(
                        context,
                        'Radius kantor diperbarui menjadi ${_radius.round()} m.',
                        ToastKind.success);
                  },
                ),
                const SizedBox(height: 16),
                _DaftarPosisi(radius: app.geofence.radiusMeter),
              ],
            );

            if (!lebar) {
              return Column(children: [peta, const SizedBox(height: 16), panel]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: peta),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: panel),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PETA SIMULASI
// ═══════════════════════════════════════════════════════════════
class _PetaKartu extends StatelessWidget {
  const _PetaKartu({required this.radius});

  final int radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.navyTopbar,
        borderRadius: BorderRadius.circular(T.rXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Peta Geofence — Kantor Utama',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              AppBadge('Radius $radius m', tone: AppBadgeTone.onHero),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 420,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(T.rMd),
              child: LayoutBuilder(
                builder: (context, c) {
                  // Diameter lingkaran mengikuti radius (skala tampilan).
                  final diameter = (radius * 2.2).clamp(60.0, c.maxWidth * 0.9);
                  return Stack(
                    children: [
                      // Latar peta
                      Positioned.fill(
                        child: CustomPaint(painter: _PetaPainter()),
                      ),
                      // Lingkaran geofence
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: diameter,
                          height: diameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: T.accent.withValues(alpha: 0.16),
                            border: Border.all(
                                color: const Color(0xFF4E83FF), width: 2),
                          ),
                        ),
                      ),
                      // Pin kantor (pusat)
                      const Center(child: _PinKantor()),
                      // Pin karyawan di dalam radius
                      const Positioned(
                          left: 60, top: 90, child: _PinKaryawan(nama: 'Anisa · 12 m')),
                      const Positioned(
                          right: 80,
                          bottom: 110,
                          child: _PinKaryawan(nama: 'Fajar · 25 m')),
                      // Pin karyawan di luar radius
                      const Positioned(
                          right: 26,
                          top: 26,
                          child: _PinKaryawan(nama: 'Rizky · 8,2 km', luar: true)),
                      // Legend
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(T.rSm),
                          ),
                          child: const Row(
                            children: [
                              _Legenda(warna: Color(0xFF10B981), teks: 'Dalam radius'),
                              SizedBox(width: 12),
                              _Legenda(warna: Color(0xFFE11D48), teks: 'Luar radius'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.warna, required this.teks});

  final Color warna;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(teks,
            style: const TextStyle(fontSize: 9, color: Color(0xFFC7D2E0))),
      ],
    );
  }
}

class _PinKantor extends StatelessWidget {
  const _PinKantor();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: T.accent,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.business_rounded,
              size: 18, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF111A2D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF3B4C66)),
          ),
          child: const Text('Kantor',
              style: TextStyle(fontSize: 8, color: Colors.white)),
        ),
      ],
    );
  }
}

class _PinKaryawan extends StatelessWidget {
  const _PinKaryawan({required this.nama, this.luar = false});

  final String nama;
  final bool luar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: luar ? const Color(0xFFE11D48) : const Color(0xFF10B981),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.person_rounded,
              size: 13, color: Colors.white),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF111A2D),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF3B4C66)),
          ),
          child: Text(nama,
              style: const TextStyle(fontSize: 7.5, color: Colors.white)),
        ),
      ],
    );
  }
}

/// Latar peta: titik grid + jalan horizontal/vertikal.
class _PetaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Latar
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0B1220),
    );

    // Titik-titik grid
    final dot = Paint()..color = const Color(0xFF314360);
    for (double x = 9; x < size.width; x += 18) {
      for (double y = 9; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }

    // Jalan
    final jalan = Paint()..color = const Color(0xFF1C2A40);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, size.width, 6),
      jalan,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.48, 0, 6, size.height),
      jalan,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// PENGATURAN RADIUS
// ═══════════════════════════════════════════════════════════════
class _KartuPengaturan extends StatelessWidget {
  const _KartuPengaturan({
    required this.radius,
    required this.onUbah,
    required this.onSimpan,
  });

  final double radius;
  final ValueChanged<double> onUbah;
  final VoidCallback onSimpan;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return AdminPanel(
      title: 'Pengaturan Titik & Radius',
      subtitle: 'Area presensi yang diizinkan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(app.geofence.namaKantor,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(app.geofence.koordinatLabel,
              style: const TextStyle(fontSize: 11, color: T.textMuted)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Radius kantor',
                  style: TextStyle(fontSize: 12, color: T.textSecondary)),
              Text('${radius.round()} meter',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: T.accent)),
            ],
          ),
          Slider(
            value: radius,
            min: 20,
            max: 200,
            divisions: 18,
            activeColor: T.accent,
            label: '${radius.round()} m',
            onChanged: onUbah,
          ),
          const Text('Geser untuk melihat area geofence berubah.',
              style: TextStyle(fontSize: 10.5, color: T.textMuted)),
          const SizedBox(height: 14),
          AppButton(
            label: 'Simpan Pengaturan',
            icon: Icons.save_rounded,
            onPressed: onSimpan,
          ),
        ],
      ),
    );
  }
}

class _DaftarPosisi extends StatelessWidget {
  const _DaftarPosisi({required this.radius});

  final int radius;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return AdminPanel(
      title: 'Status Posisi Karyawan',
      subtitle: 'Berdasarkan presensi terakhir hari ini',
      child: Column(
        children: [
          for (final m in app.monitoring)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  AdminEmployeeCell(
                    inisial: m.inisial,
                    nama: m.nama,
                    subjudul: m.jabatan,
                  ),
                  const SizedBox(width: 8),
                  AppBadge(
                    m.jarakMeter == 0
                        ? 'Tidak ada data'
                        : m.jarakMeter <= radius
                            ? 'Dalam radius'
                            : 'Luar radius',
                    tone: m.jarakMeter == 0
                        ? AppBadgeTone.slate
                        : m.jarakMeter <= radius
                            ? AppBadgeTone.green
                            : AppBadgeTone.red,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
