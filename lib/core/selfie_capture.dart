import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

/// Area selfie presensi dengan **kamera asli** (mendukung Chrome/web).
///
/// Bila kamera tidak tersedia atau izin ditolak (mis. halaman dibuka di dalam
/// iframe tanpa izin kamera), widget menampilkan panel fallback yang
/// menawarkan mode simulasi agar alur presensi tetap bisa didemokan.
class SelfieCapture extends StatefulWidget {
  const SelfieCapture({
    super.key,
    required this.foto,
    required this.onFoto,
    this.onSimulasi,
    this.simulasiAktif = false,
  });

  final Uint8List? foto;
  final ValueChanged<Uint8List?> onFoto;
  final VoidCallback? onSimulasi;
  final bool simulasiAktif;

  @override
  State<SelfieCapture> createState() => _SelfieCaptureState();
}

class _SelfieCaptureState extends State<SelfieCapture> {
  CameraController? _kontrol;
  bool _memuat = true;
  bool _memotret = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _inisialisasi();
  }

  Future<void> _inisialisasi() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final kamera = await availableCameras();
      if (kamera.isEmpty) {
        throw 'Kamera tidak ditemukan pada perangkat ini.';
      }
      final depan = kamera.firstWhere(
        (k) => k.lensDirection == CameraLensDirection.front,
        orElse: () => kamera.first,
      );
      final kontrol = CameraController(
        depan,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await kontrol.initialize();
      if (!mounted) {
        await kontrol.dispose();
        return;
      }
      setState(() {
        _kontrol = kontrol;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = e is String
            ? e
            : 'Kamera tidak dapat diakses. Pastikan izin kamera diberikan.';
        _memuat = false;
      });
    }
  }

  Future<void> _potret() async {
    final kontrol = _kontrol;
    if (kontrol == null || !kontrol.value.isInitialized) return;
    setState(() => _memotret = true);
    try {
      final hasil = await kontrol.takePicture();
      final bytes = await hasil.readAsBytes();
      widget.onFoto(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _galat = 'Gagal mengambil foto. Coba lagi.');
    } finally {
      if (mounted) setState(() => _memotret = false);
    }
  }

  @override
  void dispose() {
    _kontrol?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 240),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(T.rXl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF131D30), Color(0xFF0C1220)],
        ),
        border: Border.all(
          color: widget.foto != null
              ? const Color(0xFF34D399)
              : T.accent.withValues(alpha: 0.55),
          width: widget.foto != null ? 2 : 1.6,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _isiKonten(),
    );
  }

  Widget _isiKonten() {
    // 1) Foto sudah diambil → tampilkan hasil
    if (widget.foto != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Image.memory(
              widget.foto!,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0C1220).withValues(alpha: 0.85),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF34D399), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Foto selfie siap digunakan',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => widget.onFoto(null),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Ambil ulang'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 2) Mode simulasi aktif
    if (widget.simulasiAktif) {
      return Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Color(0xFF34D399), size: 34),
            const SizedBox(height: 10),
            const Text('Mode simulasi aktif',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            const Text('Presensi akan dicatat tanpa foto kamera asli.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF9EABC0))),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => widget.onFoto(null),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Batalkan simulasi',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    // 3) Memuat kamera
    if (_memuat) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              ),
              SizedBox(height: 12),
              Text('Menghubungkan kamera…',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9EABC0))),
            ],
          ),
        ),
      );
    }

    // 4) Kamera gagal → fallback
    if (_galat != null) {
      return Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Color(0xFFF59E0B), size: 34),
            const SizedBox(height: 10),
            Text(_galat!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 6),
            const Text(
              'Izin kamera hanya aktif saat halaman dibuka langsung di tab '
              'browser (bukan panel pratinjau).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: Color(0xFF9EABC0)),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _inisialisasi,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF3B4C66)),
                    textStyle: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Coba lagi'),
                ),
                if (widget.onSimulasi != null)
                  FilledButton(
                    onPressed: widget.onSimulasi,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: T.navy,
                      textStyle: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Gunakan mode simulasi'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    // 5) Kamera siap → pratinjau + tombol jepret
    final kontrol = _kontrol!;
    final ukuran = kontrol.value.previewSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ukuran?.height ?? 480,
                height: ukuran?.width ?? 640,
                child: CameraPreview(kontrol),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: const Color(0xFF0C1220).withValues(alpha: 0.9),
          child: Row(
            children: [
              const Expanded(
                child: Text('Posisikan wajah di dalam bingkai',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9EABC0))),
              ),
              FilledButton.icon(
                onPressed: _memotret ? null : _potret,
                icon: _memotret
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: T.navy),
                      )
                    : const Icon(Icons.camera_alt_rounded, size: 16),
                label: Text(_memotret ? 'Menyimpan…' : 'Ambil Foto'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: T.navy,
                  minimumSize: const Size(0, 38),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
