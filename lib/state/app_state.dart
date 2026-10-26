import 'package:flutter/material.dart';

import '../models/models.dart';

/// Keadaan sesi pengguna (login/logout — simulasi, nanti Firebase Auth).
enum SesiStatus { belumLogin, sudahLogin }

/// Keadaan langkah presensi hari ini.
enum LangkahPresensi { belumClockIn, sudahClockIn, sudahClockOut }

/// State global aplikasi TIPSEN (fase simulasi).
///
/// Seluruh data disimpan lokal dengan [ChangeNotifier]; struktur field sudah
/// mengikuti rancangan koleksi Firestore (users / presensi / pengajuan_izin /
/// config geofence) sehingga fase Firebase hanya menukar sumber datanya.
class AppState extends ChangeNotifier {
  // ── Sesi ─────────────────────────────────────────────────────
  SesiStatus sesi = SesiStatus.belumLogin;

  Karyawan? _pengguna;
  Karyawan get pengguna => _pengguna ?? _karyawanDefault;

  // ── Presensi hari ini ────────────────────────────────────────
  LangkahPresensi langkah = LangkahPresensi.belumClockIn;
  bool selfieSiap = false;
  bool lokasiDiizinkan = false;
  bool dalamRadius = true;
  int jarakMeter = 12;

  // ── Konfigurasi geofence (simulasi) ──────────────────────────
  KonfigurasiGeofence geofence = const KonfigurasiGeofence();

  // ── Data simulasi ────────────────────────────────────────────
  final List<Presensi> _riwayat = [];
  final List<PengajuanIzin> _pengajuan = [];

  List<Presensi> get riwayat => List.unmodifiable(_riwayat);
  List<PengajuanIzin> get pengajuan => List.unmodifiable(_pengajuan);

  Presensi? _presensiHariIni;
  Presensi? get presensiHariIni => _presensiHariIni;

  final Karyawan _karyawanDefault = const Karyawan(
    id: 'TIP-2301',
    nama: 'Anisa Ragil Saputri',
    jabatan: 'Mobile Developer',
    departemen: 'Teknologi Informasi',
    email: 'anisa@tipsen.id',
    jadwal: 'Shift Pagi · 08:00 – 17:00',
    peran: PeranAkun.karyawan,
  );

  /// ID berjalan untuk data simulasi baru.
  int _seq = 100;

  // ════════════════════════════════════════════════════════════
  // SESI
  // ════════════════════════════════════════════════════════════
  /// Login simulasi — dipanggil setelah validasi form lolos.
  void masuk(String email) {
    _pengguna = Karyawan(
      id: _karyawanDefault.id,
      nama: _karyawanDefault.nama,
      jabatan: _karyawanDefault.jabatan,
      departemen: _karyawanDefault.departemen,
      email: email.trim(),
      jadwal: _karyawanDefault.jadwal,
      peran: PeranAkun.karyawan,
    );
    sesi = SesiStatus.sudahLogin;
    _seedDataJikaKosong();
    notifyListeners();
  }

  /// Logout: kembali ke Login dan mereset state sesi.
  void keluar() {
    sesi = SesiStatus.belumLogin;
    langkah = LangkahPresensi.belumClockIn;
    selfieSiap = false;
    lokasiDiizinkan = false;
    dalamRadius = true;
    jarakMeter = 12;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // PRESENSI
  // ════════════════════════════════════════════════════════════
  void ambilSelfie() {
    selfieSiap = !selfieSiap;
    notifyListeners();
  }

  void mintaIzinLokasi() {
    lokasiDiizinkan = true;
    notifyListeners();
  }

  /// Toggle simulasi WFH (di luar radius kantor).
  void aturSimulasiLokasi(bool inside) {
    dalamRadius = inside;
    jarakMeter = inside ? 12 : 8500;
    notifyListeners();
  }

  /// Catat Clock In. Mengembalikan catatan presensi yang dibuat.
  Presensi catatClockIn(String jam) {
    final catatan = Presensi(
      id: 'P-${_seq++}',
      tanggal: DateTime.now(),
      status: dalamRadius ? StatusPresensi.hadir : StatusPresensi.wfh,
      lokasiNama: geofence.namaKantor,
      jarakMeter: jarakMeter,
      dalamRadius: dalamRadius,
      clockIn: jam,
      selfie: selfieSiap,
      keterangan:
          dalamRadius ? 'Presensi di dalam radius kantor' : 'Presensi WFH / luar radius',
    );
    _presensiHariIni = catatan;
    langkah = LangkahPresensi.sudahClockIn;
    _riwayat.insert(0, catatan);
    notifyListeners();
    return catatan;
  }

  /// Catat Clock Out pada presensi hari ini.
  void catatClockOut(String jam) {
    _presensiHariIni = _presensiHariIni?.copyWith(clockOut: jam);
    langkah = LangkahPresensi.sudahClockOut;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // PENGAJUAN IZIN
  // ════════════════════════════════════════════════════════════
  PengajuanIzin kirimPengajuan({
    required String jenis,
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    String? lampiranNama,
  }) {
    final p = PengajuanIzin(
      id: 'IZ-${_seq++}',
      jenis: jenis,
      tanggalMulai: mulai,
      tanggalSelesai: selesai,
      alasan: alasan,
      status: StatusPengajuan.menunggu,
      lampiranNama: lampiranNama,
    );
    _pengajuan.insert(0, p);
    notifyListeners();
    return p;
  }

  // ════════════════════════════════════════════════════════════
  // STATISTIK RINGKAS UNTUK BERANDA & RIWAYAT
  // ════════════════════════════════════════════════════════════
  int get jumlahHadirBulanIni =>
      riwayat.where((r) => r.status == StatusPresensi.hadir).length +
      riwayat.where((r) => r.status == StatusPresensi.terlambat).length;

  int get jumlahIzinDisetujui =>
      pengajuan.where((p) => p.status == StatusPengajuan.disetujui).length;

  int get jumlahMenunggu =>
      pengajuan.where((p) => p.status == StatusPengajuan.menunggu).length;

  // ════════════════════════════════════════════════════════════
  // DATA SIMULASI AWAL
  // ════════════════════════════════════════════════════════════
  void _seedDataJikaKosong() {
    if (_riwayat.isNotEmpty) return;
    final now = DateTime.now();
    Presensi p(int selisihHari, StatusPresensi status, String masuk,
            [String? pulang, String? ket]) =>
        Presensi(
          id: 'P-${_seq++}',
          tanggal: now.subtract(Duration(days: selisihHari)),
          status: status,
          lokasiNama: geofence.namaKantor,
          jarakMeter: 9 + selisihHari,
          dalamRadius: true,
          clockIn: masuk,
          clockOut: pulang,
          selfie: true,
          keterangan: ket,
        );

    _riwayat.addAll([
      p(1, StatusPresensi.hadir, '07:58', '17:02'),
      p(2, StatusPresensi.hadir, '08:01', '17:00'),
      p(3, StatusPresensi.terlambat, '08:24', '17:15',
          'Terlambat 24 menit — kendala lalu lintas'),
      p(4, StatusPresensi.hadir, '07:55', '17:03'),
      p(5, StatusPresensi.wfh, '08:00', '16:58',
          'WFH — jarak 8,2 km dari kantor'),
      p(6, StatusPresensi.hadir, '07:52', '17:05'),
    ]);

    _pengajuan.addAll([
      PengajuanIzin(
        id: 'IZ-${_seq++}',
        jenis: 'Izin Sakit',
        tanggalMulai: now.subtract(const Duration(days: 7)),
        tanggalSelesai: now.subtract(const Duration(days: 7)),
        alasan:
            'Sakit demam, disarankan istirahat total satu hari oleh dokter.',
        status: StatusPengajuan.disetujui,
        lampiranNama: 'surat-keteranggan.pdf',
        diprosesOleh: 'Bambang Santoso (HC)',
      ),
      PengajuanIzin(
        id: 'IZ-${_seq++}',
        jenis: 'Cuti Tahunan',
        tanggalMulai: now.add(const Duration(days: 9)),
        tanggalSelesai: now.add(const Duration(days: 10)),
        alasan: 'Menghadiri acara pernikahan keluarga di luar kota.',
        status: StatusPengajuan.menunggu,
      ),
    ]);
  }
}
