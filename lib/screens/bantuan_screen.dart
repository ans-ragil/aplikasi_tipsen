import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';

/// Halaman Bantuan & Kebijakan Privasi.
class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  static const _faq = [
    (
      'Bagaimana cara melakukan presensi?',
      'Buka menu Presensi, izinkan akses lokasi, ambil selfie melalui kamera, '
          'lalu tekan Kirim Presensi Masuk. Tekan Clock Out Sekarang saat jam '
          'kerja berakhir.'
    ),
    (
      'Mengapa presensi saya tercatat WFH?',
      'Sistem membandingkan titik lokasi Anda dengan radius kantor. Bila jarak '
          'melebihi radius yang ditetapkan HC, presensi otomatis dicatat '
          'sebagai WFH.'
    ),
    (
      'Kamera tidak muncul, apa yang harus dilakukan?',
      'Pastikan halaman dibuka di tab browser langsung (bukan di dalam panel '
          'pratinjau), lalu izinkan akses kamera saat browser meminta. Jika '
          'tetap gagal, gunakan opsi "Lanjut tanpa kamera".'
    ),
    (
      'Berapa lama pengajuan izin diproses?',
      'Pengajuan diteruskan ke HC dan biasanya diproses dalam 1×24 jam kerja. '
          'Status terbaru selalu dapat dilihat pada menu Riwayat.'
    ),
    (
      'Apakah data saya aman?',
      'Data presensi disimpan pada penyimpanan lokal browser perangkat Anda '
          'dan hanya dipakai untuk keperluan kehadiran.'
    ),
  ];

  static const _privasi = [
    (
      'Data yang dikumpulkan',
      'Nama, email, jabatan, departemen, waktu presensi, lokasi (jarak dari '
          'kantor), foto selfie presensi, serta pengajuan izin beserta '
          'lampirannya.'
    ),
    (
      'Tujuan penggunaan',
      'Data dipakai untuk mencatat kehadiran, menghitung jam kerja, memproses '
          'pengajuan izin, dan menyusun laporan kehadiran bagi HC.'
    ),
    (
      'Penyimpanan',
      'Pada versi web ini, data disimpan di penyimpanan lokal browser. Data '
          'tidak dikirim ke pihak ketiga.'
    ),
    (
      'Foto selfie',
      'Foto hanya dipakai sebagai bukti verifikasi presensi dan dapat dilihat '
          'oleh Anda serta HC.'
    ),
    (
      'Hak pengguna',
      'Anda dapat meminta pembaruan atau penghapusan data kehadiran melalui '
          'HC Admin.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Bantuan & Kebijakan Privasi'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.margin, 4, T.margin, 28),
            children: [
              // ── Kontak HC ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: T.heroGradient,
                  borderRadius: BorderRadius.circular(T.rXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Butuh bantuan lain?',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text(
                      'Hubungi HC Admin pada jam kerja 08.00 – 17.00 WIB.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFDCE7FF)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Kontak(
                            ikon: Icons.mail_outline_rounded,
                            label: 'hc@tipsen.id',
                            onTap: () => showToast(
                                context,
                                'Email HC Admin: hc@tipsen.id',
                                ToastKind.info),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Kontak(
                            ikon: Icons.call_outlined,
                            label: '(024) 1234 5678',
                            onTap: () => showToast(
                                context,
                                'Telepon HC Admin: (024) 1234 5678',
                                ToastKind.info),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── FAQ ──────────────────────────────────────
              const SectionLabel('Pertanyaan Umum'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: T.card,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: T.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < _faq.length; i++) ...[
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          iconColor: T.accent,
                          collapsedIconColor: T.textMuted,
                          title: Text(_faq[i].$1,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(_faq[i].$2,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.6,
                                      color: T.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                      if (i < _faq.length - 1)
                        const Divider(height: 1, indent: 14, endIndent: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Kebijakan privasi ────────────────────────
              const SectionLabel('Kebijakan Privasi'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: T.card,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: T.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _privasi.length; i++) ...[
                      Text('${i + 1}. ${_privasi[i].$1}',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(_privasi[i].$2,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.6,
                              color: T.textSecondary)),
                      if (i < _privasi.length - 1) const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 14),
                    const Text('Terakhir diperbarui: Oktober 2026',
                        style: TextStyle(fontSize: 10.5, color: T.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Kontak extends StatelessWidget {
  const _Kontak({
    required this.ikon,
    required this.label,
    required this.onTap,
  });

  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(T.rSm),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(ikon, size: 15, color: Colors.white),
              const SizedBox(width: 7),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halaman Tentang Aplikasi.
class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Tentang TIPSEN'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.margin, 8, T.margin, 28),
            children: [
              Center(
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: T.navy,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: T.navy.withValues(alpha: 0.25),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('T',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text('TIPSEN',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: T.navy)),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text('Presensi Online Karyawan · Versi 1.0.0',
                    style: TextStyle(fontSize: 11.5, color: T.textSecondary)),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: T.card,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: T.border),
                ),
                child: const Column(
                  children: [
                    InfoTile(label: 'Nama Aplikasi', value: 'TIPSEN'),
                    Divider(height: 1),
                    InfoTile(label: 'Versi', value: '1.0.0 (build 1)'),
                    Divider(height: 1),
                    InfoTile(label: 'Platform', value: 'Web (Chrome) & Android'),
                    Divider(height: 1),
                    InfoTile(
                        label: 'Teknologi', value: 'Flutter · Dart (Material 3)'),
                    Divider(height: 1),
                    InfoTile(
                        label: 'Penyimpanan',
                        value: 'Lokal browser (SharedPreferences)'),
                    Divider(height: 1),
                    InfoTile(
                        label: 'Pengembang', value: 'Anisa Ragil Saputri'),
                    Divider(height: 1),
                    InfoTile(label: 'NIM', value: '23.01.55.0009'),
                    Divider(height: 1),
                    InfoTile(
                        label: 'Mata Kuliah',
                        value: 'Mobile & Web App Development'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fitur utama',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    for (final f in const [
                      'Presensi Clock In / Out dengan selfie & validasi lokasi',
                      'Riwayat presensi dengan filter periode dan unduh CSV',
                      'Pengajuan cuti / izin online beserta lampiran',
                      'Portal HC: monitoring, geofence, persetujuan, laporan',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 15, color: T.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(f,
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      height: 1.5,
                                      color: T.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('© 2026 TIPSEN · Data tersimpan lokal di perangkat',
                    style: TextStyle(fontSize: 10.5, color: T.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
