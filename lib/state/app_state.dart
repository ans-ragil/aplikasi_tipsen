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
  AppState() {
    _seedAdmin();
  }

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
  // DATA & AKSI WEB ADMIN (HC PORTAL)
  // ════════════════════════════════════════════════════════════
  final List<KaryawanAdmin> _karyawanAdmin = [];
  final List<BarisMonitoring> _monitoring = [];
  final List<PengajuanIzin> _pengajuanMasuk = [];

  List<KaryawanAdmin> get karyawanAdmin => List.unmodifiable(_karyawanAdmin);
  List<BarisMonitoring> get monitoring => List.unmodifiable(_monitoring);
  List<PengajuanIzin> get pengajuanMasuk => List.unmodifiable(_pengajuanMasuk);

  int get totalKaryawan => _karyawanAdmin.length;
  int get totalHadir =>
      _monitoring.where((m) => m.status == StatusPresensi.hadir).length;
  int get totalTerlambat =>
      _monitoring.where((m) => m.status == StatusPresensi.terlambat).length;
  int get totalWfh =>
      _monitoring.where((m) => m.status == StatusPresensi.wfh).length;
  int get totalMenungguPersetujuan => _pengajuanMasuk
      .where((p) => p.status == StatusPengajuan.menunggu)
      .length;

  /// Persentase kehadiran (hadir + terlambat + wfh) terhadap total karyawan.
  int get persenKehadiran {
    if (_monitoring.isEmpty) return 0;
    final hadir = _monitoring
        .where((m) => m.status != StatusPresensi.izinDisetujui)
        .length;
    return ((hadir / _monitoring.length) * 100).round();
  }

  void aturRadius(int meter) {
    geofence = geofence.copyWith(radiusMeter: meter);
    notifyListeners();
  }

  void aturNamaKantor(String nama) {
    geofence = geofence.copyWith(namaKantor: nama);
    notifyListeners();
  }

  /// Setujui / tolak pengajuan pada daftar admin.
  void putuskanPengajuan(String id, bool setujui) {
    final i = _pengajuanMasuk.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _pengajuanMasuk[i] = _pengajuanMasuk[i].copyWith(
      status: setujui ? StatusPengajuan.disetujui : StatusPengajuan.ditolak,
      diprosesOleh: 'Bambang Santoso (HC)',
    );
    notifyListeners();
  }

  void tambahKaryawan(KaryawanAdmin k) {
    _karyawanAdmin.add(k);
    notifyListeners();
  }

  void perbaruiKaryawan(int index, KaryawanAdmin k) {
    if (index < 0 || index >= _karyawanAdmin.length) return;
    _karyawanAdmin[index] = k;
    notifyListeners();
  }

  void _seedAdmin() {
    _karyawanAdmin.addAll(const [
      KaryawanAdmin(
        nama: 'Anisa Ragil Saputri',
        jabatan: 'Mobile Developer',
        departemen: 'Teknologi Informasi',
        status: 'Aktif',
        email: 'anisa@tipsen.id',
      ),
      KaryawanAdmin(
        nama: 'Fajar Hidayat',
        jabatan: 'UI/UX Designer',
        departemen: 'Produk',
        status: 'Aktif',
        email: 'fajar@tipsen.id',
      ),
      KaryawanAdmin(
        nama: 'Rizky Pratama',
        jabatan: 'Backend Engineer',
        departemen: 'Teknologi Informasi',
        status: 'WFH',
        email: 'rizky@tipsen.id',
      ),
      KaryawanAdmin(
        nama: 'Nadia Salsabila',
        jabatan: 'Quality Assurance',
        departemen: 'Teknologi Informasi',
        status: 'Aktif',
        email: 'nadia@tipsen.id',
      ),
      KaryawanAdmin(
        nama: 'Bagas Nugroho',
        jabatan: 'Finance Staff',
        departemen: 'Keuangan',
        status: 'Aktif',
        email: 'bagas@tipsen.id',
      ),
      KaryawanAdmin(
        nama: 'Sinta Maharani',
        jabatan: 'HR Generalist',
        departemen: 'Human Capital',
        status: 'Aktif',
        email: 'sinta@tipsen.id',
      ),
    ]);

    _monitoring.addAll(const [
      BarisMonitoring(
        nama: 'Anisa Ragil Saputri',
        jabatan: 'Mobile Developer',
        jamMasuk: '07:58',
        jamPulang: '17:02',
        lokasi: 'Kantor Utama TIPSEN',
        status: StatusPresensi.hadir,
        keterangan: 'Tepat waktu',
        jarakMeter: 12,
      ),
      BarisMonitoring(
        nama: 'Fajar Hidayat',
        jabatan: 'UI/UX Designer',
        jamMasuk: '08:01',
        jamPulang: '17:00',
        lokasi: 'Kantor Utama TIPSEN',
        status: StatusPresensi.hadir,
        keterangan: 'Tepat waktu',
        jarakMeter: 25,
      ),
      BarisMonitoring(
        nama: 'Rizky Pratama',
        jabatan: 'Backend Engineer',
        jamMasuk: '08:00',
        jamPulang: '16:58',
        lokasi: 'WFH — Jl. Pandanaran',
        status: StatusPresensi.wfh,
        keterangan: 'Di luar radius (8,2 km)',
        jarakMeter: 8200,
      ),
      BarisMonitoring(
        nama: 'Nadia Salsabila',
        jabatan: 'Quality Assurance',
        jamMasuk: '08:24',
        jamPulang: '17:15',
        lokasi: 'Kantor Utama TIPSEN',
        status: StatusPresensi.terlambat,
        keterangan: 'Terlambat 24 menit',
        jarakMeter: 31,
      ),
      BarisMonitoring(
        nama: 'Bagas Nugroho',
        jabatan: 'Finance Staff',
        jamMasuk: '07:45',
        jamPulang: '17:05',
        lokasi: 'Kantor Utama TIPSEN',
        status: StatusPresensi.hadir,
        keterangan: 'Tepat waktu',
        jarakMeter: 8,
      ),
      BarisMonitoring(
        nama: 'Sinta Maharani',
        jabatan: 'HR Generalist',
        jamMasuk: '—',
        jamPulang: '—',
        lokasi: '—',
        status: StatusPresensi.izinDisetujui,
        keterangan: 'Izin sakit (disetujui)',
        jarakMeter: 0,
      ),
    ]);

    final now = DateTime.now();
    _pengajuanMasuk.addAll([
      PengajuanIzin(
        id: 'HC-1',
        jenis: 'Cuti Tahunan',
        tanggalMulai: now.add(const Duration(days: 3)),
        tanggalSelesai: now.add(const Duration(days: 5)),
        alasan: 'Liburan keluarga yang sudah direncanakan sejak awal tahun.',
        status: StatusPengajuan.menunggu,
        namaPemohon: 'Anisa Ragil Saputri',
        jabatanPemohon: 'Mobile Developer',
      ),
      PengajuanIzin(
        id: 'HC-2',
        jenis: 'Izin Sakit',
        tanggalMulai: now,
        tanggalSelesai: now,
        alasan: 'Demam dan sakit tenggorokan, disarankan istirahat oleh dokter.',
        status: StatusPengajuan.menunggu,
        lampiranNama: 'surat-dokter.pdf',
        namaPemohon: 'Rizky Pratama',
        jabatanPemohon: 'Backend Engineer',
      ),
      PengajuanIzin(
        id: 'HC-3',
        jenis: 'Izin Keperluan Pribadi',
        tanggalMulai: now.subtract(const Duration(days: 2)),
        tanggalSelesai: now.subtract(const Duration(days: 2)),
        alasan: 'Mengurus dokumen kependudukan di kantor kelurahan.',
        status: StatusPengajuan.disetujui,
        diprosesOleh: 'Bambang Santoso (HC)',
        namaPemohon: 'Nadia Salsabila',
        jabatanPemohon: 'Quality Assurance',
      ),
    ]);
  }

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
