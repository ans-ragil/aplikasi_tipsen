import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Keadaan sesi pengguna.
enum SesiStatus { belumLogin, sudahLogin }

/// Langkah presensi hari ini.
enum LangkahPresensi { belumClockIn, sudahClockIn, sudahClockOut }

/// Periode laporan pada portal HC.
enum PeriodeLaporan { bulanIni, bulanLalu, tigaBulan }

extension PeriodeLaporanX on PeriodeLaporan {
  String get label => switch (this) {
        PeriodeLaporan.bulanIni => 'Bulan ini',
        PeriodeLaporan.bulanLalu => 'Bulan lalu',
        PeriodeLaporan.tigaBulan => '3 bulan terakhir',
      };
}

/// Ringkasan kehadiran satu karyawan untuk laporan HC.
class RekapKaryawan {
  const RekapKaryawan({
    required this.nama,
    required this.jabatan,
    required this.departemen,
    required this.hadir,
    required this.terlambat,
    required this.wfh,
    required this.izin,
    required this.totalHariKerja,
    required this.totalMenitKerja,
  });

  final String nama;
  final String jabatan;
  final String departemen;
  final int hadir;
  final int terlambat;
  final int wfh;
  final int izin;
  final int totalHariKerja;
  final int totalMenitKerja;

  int get totalMasuk => hadir + terlambat + wfh;
  int get persen => totalHariKerja == 0
      ? 0
      : ((totalMasuk / totalHariKerja) * 100).round().clamp(0, 100);
  String get rataDurasi =>
      totalMasuk == 0 ? '—' : durasiLabel(totalMenitKerja ~/ totalMasuk);
}

/// State global TIPSEN.
///
/// Satu sumber data dipakai bersama oleh aplikasi karyawan dan portal HC,
/// sehingga pengajuan karyawan langsung terlihat HC dan keputusan HC langsung
/// terlihat karyawan. Seluruh data disimpan di penyimpanan lokal browser
/// (bertahan setelah refresh) dan siap dipindahkan ke Firestore nanti.
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  static const _kunciSimpan = 'tipsen.data.v2';
  static const _kunciSesi = 'tipsen.sesi.v2';

  SharedPreferences? _prefs;
  bool siap = false;

  // ── Akun demo ────────────────────────────────────────────────
  static const emailKaryawan = 'anisa@tipsen.id';
  static const sandiKaryawan = 'tipsen123';
  static const emailAdmin = 'bambang@tipsen.id';
  static const sandiAdmin = 'admin123';

  final Map<String, String> _sandi = {
    emailKaryawan: sandiKaryawan,
    emailAdmin: sandiAdmin,
  };

  // ── Sesi ─────────────────────────────────────────────────────
  SesiStatus sesi = SesiStatus.belumLogin;
  PeranAkun peran = PeranAkun.karyawan;

  Karyawan _pengguna = const Karyawan(
    id: 'TIP-2301',
    nama: 'Anisa Ragil Saputri',
    jabatan: 'Mobile Developer',
    departemen: 'Teknologi Informasi',
    email: emailKaryawan,
    jadwal: 'Shift Pagi · 08:00 – 17:00',
    peran: PeranAkun.karyawan,
  );

  Karyawan get pengguna => _pengguna;

  /// Identitas admin HC (untuk halaman profil HC).
  Karyawan get adminHC => const Karyawan(
        id: 'HC-0001',
        nama: 'Bambang Santoso',
        jabatan: 'HC Head',
        departemen: 'Human Capital',
        email: emailAdmin,
        jadwal: 'Senin – Jumat · 08:00 – 17:00',
        peran: PeranAkun.adminHC,
      );

  // ── Presensi hari ini (karyawan) ─────────────────────────────
  Uint8List? fotoSelfie;
  bool selfieSimulasi = false;
  bool get selfieSiap => fotoSelfie != null || selfieSimulasi;

  bool lokasiDiizinkan = false;
  bool dalamRadius = true;
  int jarakMeter = 12;

  KonfigurasiGeofence geofence = const KonfigurasiGeofence();

  // ── Data ─────────────────────────────────────────────────────
  final List<Presensi> _riwayat = [];
  final List<PengajuanIzin> _pengajuan = [];
  final List<KaryawanAdmin> _karyawan = [];
  final List<BarisMonitoring> _presensiOrg = [];

  bool notifikasiAktif = true;

  int _seq = 500;

  List<Presensi> get riwayat => List.unmodifiable(_riwayat);
  List<PengajuanIzin> get pengajuan => List.unmodifiable(_pengajuan);
  List<KaryawanAdmin> get karyawanAdmin => List.unmodifiable(_karyawan);

  // ════════════════════════════════════════════════════════════
  // INISIALISASI & PENYIMPANAN
  // ════════════════════════════════════════════════════════════
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final mentah = _prefs!.getString(_kunciSimpan);
      if (mentah != null) {
        _pulihkan(jsonDecode(mentah) as Map<String, dynamic>);
      }
      final sesiTersimpan = _prefs!.getString(_kunciSesi);
      if (sesiTersimpan != null) {
        final email = sesiTersimpan;
        if (email == emailAdmin) {
          peran = PeranAkun.adminHC;
          sesi = SesiStatus.sudahLogin;
        } else if (_sandi.containsKey(email)) {
          _pengguna = _pengguna.copyWithEmail(email);
          peran = PeranAkun.karyawan;
          sesi = SesiStatus.sudahLogin;
        }
      }
    } catch (_) {
      // Penyimpanan tidak tersedia — aplikasi tetap berjalan dengan data awal.
    }
    siap = true;
    notifyListeners();
  }

  void _simpan() {
    final prefs = _prefs;
    if (prefs == null) return;
    final now = DateTime.now();
    bool dekat(DateTime d) => now.difference(d).inDays.abs() <= 2;

    Map<String, dynamic> bangun({required bool denganFoto}) => {
          'riwayat': [
            for (final r in _riwayat)
              r.toJson(denganFoto: denganFoto && dekat(r.tanggal)),
          ],
          'pengajuan': [
            for (final p in _pengajuan)
              p.toJson(
                  denganLampiran: !(p.lampiran?.bytes != null) ||
                      p.lampiran!.bytes!.length < 700000),
          ],
          'karyawan': [for (final k in _karyawan) k.toJson()],
          'presensiOrg': [for (final b in _presensiOrg) b.toJson()],
          'geofence': geofence.toJson(),
          'sandi': _sandi,
          'notifikasi': notifikasiAktif,
          'seq': _seq,
        };

    Future<void> tulis(Map<String, dynamic> isi) async {
      try {
        await prefs.setString(_kunciSimpan, jsonEncode(isi));
      } catch (_) {
        // Kuota penuh — coba sekali lagi tanpa foto.
        try {
          await prefs.setString(
              _kunciSimpan, jsonEncode(bangun(denganFoto: false)));
        } catch (_) {}
      }
    }

    unawaited(tulis(bangun(denganFoto: true)));
  }

  void _simpanSesi() {
    final prefs = _prefs;
    if (prefs == null) return;
    if (sesi == SesiStatus.belumLogin) {
      unawaited(prefs.remove(_kunciSesi));
    } else {
      unawaited(prefs.setString(
          _kunciSesi, peran == PeranAkun.adminHC ? emailAdmin : _pengguna.email));
    }
  }

  void _pulihkan(Map<String, dynamic> j) {
    _riwayat
      ..clear()
      ..addAll((j['riwayat'] as List? ?? [])
          .map((e) => Presensi.fromJson(e as Map<String, dynamic>)));
    _pengajuan
      ..clear()
      ..addAll((j['pengajuan'] as List? ?? [])
          .map((e) => PengajuanIzin.fromJson(e as Map<String, dynamic>)));
    _karyawan
      ..clear()
      ..addAll((j['karyawan'] as List? ?? [])
          .map((e) => KaryawanAdmin.fromJson(e as Map<String, dynamic>)));
    _presensiOrg
      ..clear()
      ..addAll((j['presensiOrg'] as List? ?? [])
          .map((e) => BarisMonitoring.fromJson(e as Map<String, dynamic>)));
    if (j['geofence'] != null) {
      geofence = KonfigurasiGeofence.fromJson(
          j['geofence'] as Map<String, dynamic>);
    }
    if (j['sandi'] != null) {
      (j['sandi'] as Map<String, dynamic>)
          .forEach((k, v) => _sandi[k] = v as String);
    }
    notifikasiAktif = j['notifikasi'] as bool? ?? true;
    _seq = (j['seq'] as num?)?.toInt() ?? 500;
    if (_karyawan.isEmpty || _riwayat.isEmpty) _seed();
  }

  // ════════════════════════════════════════════════════════════
  // SESI
  // ════════════════════════════════════════════════════════════
  /// Login. Mengembalikan pesan kesalahan, atau null bila berhasil.
  String? masuk(String email, String sandi) {
    final e = email.trim().toLowerCase();
    if (!_sandi.containsKey(e)) {
      return 'Email belum terdaftar. Gunakan akun demo yang tertera di bawah.';
    }
    if (_sandi[e] != sandi) {
      return 'Kata sandi salah. Periksa kembali atau gunakan akun demo.';
    }
    if (e == emailAdmin) {
      peran = PeranAkun.adminHC;
      _pengguna = _pengguna.copyWithEmail(e);
    } else {
      peran = PeranAkun.karyawan;
      _pengguna = _pengguna.copyWithEmail(e);
    }
    sesi = SesiStatus.sudahLogin;
    fotoSelfie = null;
    selfieSimulasi = false;
    _simpanSesi();
    notifyListeners();
    return null;
  }

  void keluar() {
    sesi = SesiStatus.belumLogin;
    peran = PeranAkun.karyawan;
    fotoSelfie = null;
    selfieSimulasi = false;
    lokasiDiizinkan = false;
    dalamRadius = true;
    jarakMeter = 12;
    _simpanSesi();
    notifyListeners();
  }

  /// Ubah kata sandi. Mengembalikan pesan kesalahan, atau null bila berhasil.
  String? ubahSandi(String lama, String baru) {
    final email = peran == PeranAkun.adminHC ? emailAdmin : _pengguna.email;
    if (_sandi[email] != lama) return 'Kata sandi saat ini tidak sesuai.';
    if (baru.length < 6) return 'Kata sandi baru minimal 6 karakter.';
    if (baru == lama) return 'Kata sandi baru harus berbeda dari yang lama.';
    _sandi[email] = baru;
    _simpan();
    notifyListeners();
    return null;
  }

  /// Reset kata sandi (alur "lupa kata sandi") — hanya untuk akun terdaftar.
  String? resetSandi(String email) {
    final e = email.trim().toLowerCase();
    if (!_sandi.containsKey(e)) return 'Email tidak terdaftar pada sistem TIPSEN.';
    return null;
  }

  // ════════════════════════════════════════════════════════════
  // PRESENSI KARYAWAN
  // ════════════════════════════════════════════════════════════
  bool _hariSama(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Catatan presensi hari ini (null bila belum Clock In).
  Presensi? get presensiHariIni {
    final now = DateTime.now();
    for (final r in _riwayat) {
      if (_hariSama(r.tanggal, now)) return r;
    }
    return null;
  }

  /// Langkah presensi diturunkan dari data — tidak bisa "Clock In dua kali"
  /// meski pengguna logout lalu login kembali.
  LangkahPresensi get langkah {
    final p = presensiHariIni;
    if (p == null) return LangkahPresensi.belumClockIn;
    return p.clockOut == null
        ? LangkahPresensi.sudahClockIn
        : LangkahPresensi.sudahClockOut;
  }

  void ambilSelfie() {
    fotoSelfie = null;
    selfieSimulasi = !selfieSimulasi;
    notifyListeners();
  }

  void setFotoSelfie(Uint8List? bytes) {
    fotoSelfie = bytes;
    if (bytes != null) selfieSimulasi = false;
    notifyListeners();
  }

  void mintaIzinLokasi() {
    lokasiDiizinkan = true;
    notifyListeners();
  }

  void aturSimulasiLokasi(bool inside) {
    dalamRadius = inside;
    jarakMeter = inside ? 12 : 8500;
    notifyListeners();
  }

  /// Batas jam masuk shift pagi (08:15) untuk menentukan keterlambatan.
  static const _batasMasuk = 8 * 60 + 15;

  bool get lewatBatasMasuk => _menitSekarang > _batasMasuk;
  int get _menitSekarang => DateTime.now().hour * 60 + DateTime.now().minute;

  /// Catat Clock In dan kembalikan catatan yang dibuat.
  Presensi catatClockIn(String jam) {
    final sekarang = DateTime.now();
    final telat = _menitSekarang > _batasMasuk;
    final status = !dalamRadius
        ? StatusPresensi.wfh
        : (telat ? StatusPresensi.terlambat : StatusPresensi.hadir);

    final catatan = Presensi(
      id: 'P-${_seq++}',
      tanggal: sekarang,
      status: status,
      lokasiNama: dalamRadius ? geofence.namaKantor : 'WFH / luar radius',
      jarakMeter: jarakMeter,
      dalamRadius: dalamRadius,
      clockIn: jam,
      selfie: selfieSiap,
      keterangan: switch (status) {
        StatusPresensi.terlambat =>
          'Terlambat ${durasiLabel(_menitSekarang - _batasMasuk)} dari jadwal 08:00',
        StatusPresensi.wfh => 'WFH — ${(jarakMeter / 1000).toStringAsFixed(1)} km dari kantor',
        _ => 'Presensi di dalam radius kantor',
      },
      foto: fotoSelfie,
    );

    _riwayat.removeWhere((r) => _hariSama(r.tanggal, sekarang));
    _riwayat.insert(0, catatan);
    _catatKePortalHC(catatan);
    _simpan();
    notifyListeners();
    return catatan;
  }

  /// Catat Clock Out pada catatan hari ini (riwayat ikut diperbarui).
  Presensi? catatClockOut(String jam) {
    final now = DateTime.now();
    final i = _riwayat.indexWhere((r) => _hariSama(r.tanggal, now));
    if (i < 0) return null;
    final baru = _riwayat[i].copyWith(clockOut: jam);
    _riwayat[i] = baru;
    _catatKePortalHC(baru);
    _simpan();
    notifyListeners();
    return baru;
  }

  /// Sinkronkan presensi karyawan ke data portal HC.
  void _catatKePortalHC(Presensi p) {
    final i = _presensiOrg.indexWhere(
        (b) => b.nama == _pengguna.nama && _hariSama(b.tanggal, p.tanggal));
    final baris = BarisMonitoring(
      id: i >= 0 ? _presensiOrg[i].id : 'M-${_seq++}',
      nama: _pengguna.nama,
      jabatan: _pengguna.jabatan,
      tanggal: p.tanggal,
      jamMasuk: p.clockIn ?? '—',
      jamPulang: p.clockOut ?? '—',
      lokasi: p.lokasiNama,
      status: p.status,
      keterangan: p.keterangan ?? '',
      jarakMeter: p.jarakMeter,
    );
    if (i >= 0) {
      _presensiOrg[i] = baris;
    } else {
      _presensiOrg.add(baris);
    }
  }

  // ════════════════════════════════════════════════════════════
  // STATISTIK KARYAWAN
  // ════════════════════════════════════════════════════════════
  List<Presensi> presensiBulan(DateTime bulan) => _riwayat
      .where((r) => r.tanggal.year == bulan.year && r.tanggal.month == bulan.month)
      .toList()
    ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

  List<PengajuanIzin> pengajuanSaya({DateTime? bulan}) {
    final list = _pengajuan.where((p) => p.namaPemohon == _pengguna.nama);
    if (bulan == null) return list.toList();
    return list
        .where((p) =>
            p.tanggalMulai.year == bulan.year &&
            p.tanggalMulai.month == bulan.month)
        .toList();
  }

  List<Presensi> get riwayatSaya => _riwayat;

  int hadirBulan(DateTime bulan) {
    final list = presensiBulan(bulan);
    return list
        .where((r) =>
            r.status == StatusPresensi.hadir ||
            r.status == StatusPresensi.terlambat ||
            r.status == StatusPresensi.wfh)
        .length;
  }

  int terlambatBulan(DateTime bulan) => presensiBulan(bulan)
      .where((r) => r.status == StatusPresensi.terlambat)
      .length;

  int menitKerjaBulan(DateTime bulan) => presensiBulan(bulan)
      .fold(0, (t, r) => t + (r.durasiMenit ?? 0));

  int get izinDisetujuiBulanIni => pengajuanSaya(bulan: DateTime.now())
      .where((p) => p.status == StatusPengajuan.disetujui)
      .length;

  int get pengajuanMenunggu =>
      pengajuanSaya().where((p) => p.status == StatusPengajuan.menunggu).length;

  // ════════════════════════════════════════════════════════════
  // PENGAJUAN IZIN (satu daftar untuk karyawan & HC)
  // ════════════════════════════════════════════════════════════
  PengajuanIzin kirimPengajuan({
    required String jenis,
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    Lampiran? lampiran,
  }) {
    final p = PengajuanIzin(
      id: 'IZ-${_seq++}',
      jenis: jenis,
      tanggalMulai: mulai,
      tanggalSelesai: selesai,
      alasan: alasan,
      status: StatusPengajuan.menunggu,
      lampiran: lampiran,
      namaPemohon: _pengguna.nama,
      jabatanPemohon: _pengguna.jabatan,
      diajukanPada: DateTime.now(),
    );
    _pengajuan.insert(0, p);
    _simpan();
    notifyListeners();
    return p;
  }

  /// Keputusan HC — langsung terlihat oleh karyawan yang bersangkutan.
  void putuskanPengajuan(String id, bool setujui, {String? alasanPenolakan}) {
    final i = _pengajuan.indexWhere((p) => p.id == id);
    if (i < 0) return;
    _pengajuan[i] = _pengajuan[i].copyWith(
      status: setujui ? StatusPengajuan.disetujui : StatusPengajuan.ditolak,
      diprosesOleh: '${adminHC.nama} (HC)',
      alasanPenolakan: setujui ? null : alasanPenolakan,
    );
    _simpan();
    notifyListeners();
  }

  int get totalMenungguPersetujuan =>
      _pengajuan.where((p) => p.status == StatusPengajuan.menunggu).length;

  List<PengajuanIzin> get pengajuanMasuk {
    final list = [..._pengajuan];
    list.sort((a, b) {
      final x = a.diajukanPada ?? a.tanggalMulai;
      final y = b.diajukanPada ?? b.tanggalMulai;
      return y.compareTo(x);
    });
    return list;
  }

  // ════════════════════════════════════════════════════════════
  // PORTAL HC — KARYAWAN
  // ════════════════════════════════════════════════════════════
  int get totalKaryawan => _karyawan.where((k) => k.aktif).length;

  String? tambahKaryawan(KaryawanAdmin k) {
    if (_karyawan.any((e) => e.email.toLowerCase() == k.email.toLowerCase())) {
      return 'Email ${k.email} sudah dipakai karyawan lain.';
    }
    _karyawan.add(k);
    _simpan();
    notifyListeners();
    return null;
  }

  String? perbaruiKaryawan(int index, KaryawanAdmin k) {
    if (index < 0 || index >= _karyawan.length) return 'Data tidak ditemukan.';
    final bentrok = _karyawan.asMap().entries.any((e) =>
        e.key != index && e.value.email.toLowerCase() == k.email.toLowerCase());
    if (bentrok) return 'Email ${k.email} sudah dipakai karyawan lain.';
    _karyawan[index] = k;
    _simpan();
    notifyListeners();
    return null;
  }

  void hapusKaryawan(String id) {
    _karyawan.removeWhere((k) => k.id == id);
    _simpan();
    notifyListeners();
  }

  void aturAktifKaryawan(String id, bool aktif) {
    final i = _karyawan.indexWhere((k) => k.id == id);
    if (i < 0) return;
    _karyawan[i] = _karyawan[i].copyWith(
      aktif: aktif,
      status: aktif ? 'Aktif' : 'Nonaktif',
    );
    _simpan();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // PORTAL HC — PRESENSI, DASHBOARD, LAPORAN
  // ════════════════════════════════════════════════════════════
  List<BarisMonitoring> get monitoringHariIni {
    final now = DateTime.now();
    final list = _presensiOrg.where((b) => _hariSama(b.tanggal, now)).toList();
    list.sort((a, b) => a.nama.compareTo(b.nama));
    return list;
  }

  int get hadirHariIni => monitoringHariIni
      .where((b) =>
          b.status == StatusPresensi.hadir || b.status == StatusPresensi.wfh)
      .length;
  int get terlambatHariIni => monitoringHariIni
      .where((b) => b.status == StatusPresensi.terlambat)
      .length;
  int get izinHariIni => monitoringHariIni
      .where((b) => b.status == StatusPresensi.izinDisetujui)
      .length;
  /// Total karyawan yang sudah masuk (hadir + terlambat + WFH).
  int get masukHariIni => monitoringHariIni
      .where((b) => b.status != StatusPresensi.izinDisetujui)
      .length;

  int get belumPresensiHariIni =>
      (totalKaryawan - masukHariIni - izinHariIni).clamp(0, 999);

  (DateTime, DateTime) rentangPeriode(PeriodeLaporan p) {
    final now = DateTime.now();
    return switch (p) {
      PeriodeLaporan.bulanIni => (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59)
        ),
      PeriodeLaporan.bulanLalu => (
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0, 23, 59)
        ),
      PeriodeLaporan.tigaBulan => (
          DateTime(now.year, now.month - 2, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59)
        ),
    };
  }

  List<BarisMonitoring> presensiPeriode(PeriodeLaporan periode) {
    final (awal, akhir) = rentangPeriode(periode);
    return _presensiOrg
        .where((b) => !b.tanggal.isBefore(awal) && !b.tanggal.isAfter(akhir))
        .toList();
  }

  /// Jumlah hari kerja pada periode (Senin–Jumat, sampai hari ini).
  int hariKerjaPeriode(PeriodeLaporan periode) {
    final (awal, akhir) = rentangPeriode(periode);
    final now = DateTime.now();
    final batas = akhir.isAfter(now) ? now : akhir;
    var n = 0;
    for (var d = awal; !d.isAfter(batas); d = d.add(const Duration(days: 1))) {
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) n++;
    }
    return n == 0 ? 1 : n;
  }

  List<RekapKaryawan> rekap(PeriodeLaporan periode) {
    final data = presensiPeriode(periode);
    final hariKerja = hariKerjaPeriode(periode);
    return [
      for (final k in _karyawan.where((k) => k.aktif))
        () {
          final milik = data.where((b) => b.nama == k.nama).toList();
          return RekapKaryawan(
            nama: k.nama,
            jabatan: k.jabatan,
            departemen: k.departemen,
            hadir: milik.where((b) => b.status == StatusPresensi.hadir).length,
            terlambat:
                milik.where((b) => b.status == StatusPresensi.terlambat).length,
            wfh: milik.where((b) => b.status == StatusPresensi.wfh).length,
            izin: milik
                .where((b) => b.status == StatusPresensi.izinDisetujui)
                .length,
            totalHariKerja: hariKerja,
            totalMenitKerja:
                milik.fold(0, (t, b) => t + (b.durasiMenit ?? 0)),
          );
        }(),
    ]..sort((a, b) => b.persen.compareTo(a.persen));
  }

  int get persenKehadiran {
    final data = presensiPeriode(PeriodeLaporan.bulanIni);
    if (data.isEmpty) return 0;
    final masuk =
        data.where((b) => b.status != StatusPresensi.izinDisetujui).length;
    return ((masuk / data.length) * 100).round().clamp(0, 100);
  }

  /// Rata-rata jam masuk seluruh karyawan (menit sejak tengah malam).
  String get rataJamMasuk {
    final data = presensiPeriode(PeriodeLaporan.bulanIni)
        .map((b) => menitDariJam(b.jamMasuk == '—' ? null : b.jamMasuk))
        .whereType<int>()
        .toList();
    if (data.isEmpty) return '—';
    final rata = data.reduce((a, b) => a + b) ~/ data.length;
    return '${(rata ~/ 60).toString().padLeft(2, '0')}:${(rata % 60).toString().padLeft(2, '0')}';
  }

  int get totalCatatanBulanIni =>
      presensiPeriode(PeriodeLaporan.bulanIni).length;

  /// Grafik batang dashboard: kehadiran per hari kerja terakhir.
  List<(String, int, int)> grafikMingguan() {
    final now = DateTime.now();
    final hasil = <(String, int, int)>[];
    for (var i = 4; i >= 0; i--) {
      final hari = now.subtract(Duration(days: i));
      final rows = _presensiOrg
          .where((b) => _hariSama(b.tanggal, hari))
          .toList();
      final masuk = rows
          .where((b) => b.status != StatusPresensi.izinDisetujui)
          .length;
      hasil.add((namaHari[hari.weekday - 1].substring(0, 3), masuk, totalKaryawan));
    }
    return hasil;
  }

  // ════════════════════════════════════════════════════════════
  // GEOFENCE
  // ════════════════════════════════════════════════════════════
  void aturRadius(int meter) {
    geofence = geofence.copyWith(radiusMeter: meter);
    _simpan();
    notifyListeners();
  }

  void aturNamaKantor(String nama) {
    geofence = geofence.copyWith(namaKantor: nama);
    _simpan();
    notifyListeners();
  }

  void aturNotifikasi(bool aktif) {
    notifikasiAktif = aktif;
    _simpan();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  // DATA AWAL
  // ════════════════════════════════════════════════════════════
  void _seed() {
    if (_karyawan.isNotEmpty) return;
    _karyawan.addAll(const [
      KaryawanAdmin(
          id: 'EMP-01',
          nama: 'Anisa Ragil Saputri',
          jabatan: 'Mobile Developer',
          departemen: 'Teknologi Informasi',
          status: 'Aktif',
          email: emailKaryawan),
      KaryawanAdmin(
          id: 'EMP-02',
          nama: 'Fajar Hidayat',
          jabatan: 'UI/UX Designer',
          departemen: 'Produk',
          status: 'Aktif',
          email: 'fajar@tipsen.id'),
      KaryawanAdmin(
          id: 'EMP-03',
          nama: 'Rizky Pratama',
          jabatan: 'Backend Engineer',
          departemen: 'Teknologi Informasi',
          status: 'WFH',
          email: 'rizky@tipsen.id'),
      KaryawanAdmin(
          id: 'EMP-04',
          nama: 'Nadia Salsabila',
          jabatan: 'Quality Assurance',
          departemen: 'Teknologi Informasi',
          status: 'Aktif',
          email: 'nadia@tipsen.id'),
      KaryawanAdmin(
          id: 'EMP-05',
          nama: 'Bagas Nugroho',
          jabatan: 'Finance Staff',
          departemen: 'Keuangan',
          status: 'Aktif',
          email: 'bagas@tipsen.id'),
      KaryawanAdmin(
          id: 'EMP-06',
          nama: 'Sinta Maharani',
          jabatan: 'HR Generalist',
          departemen: 'Human Capital',
          status: 'Aktif',
          email: 'sinta@tipsen.id'),
    ]);

    _seedRiwayatKaryawan();
    _seedPresensiOrganisasi();
    _seedPengajuan();
  }

  void _seedRiwayatKaryawan() {
    final now = DateTime.now();
    Presensi p(int hari, StatusPresensi status, String masuk, String pulang,
            [String? ket]) =>
        Presensi(
          id: 'P-${_seq++}',
          tanggal: now.subtract(Duration(days: hari)),
          status: status,
          lokasiNama: status == StatusPresensi.wfh
              ? 'WFH — Jl. Pandanaran'
              : geofence.namaKantor,
          jarakMeter: status == StatusPresensi.wfh ? 8200 : 9 + hari,
          dalamRadius: status != StatusPresensi.wfh,
          clockIn: masuk,
          clockOut: pulang,
          selfie: true,
          keterangan: ket ?? 'Presensi di dalam radius kantor',
        );

    _riwayat.addAll([
      p(1, StatusPresensi.hadir, '07:58', '17:02'),
      p(2, StatusPresensi.hadir, '08:01', '17:00'),
      p(3, StatusPresensi.terlambat, '08:24', '17:15',
          'Terlambat 24 menit dari jadwal 08:00'),
      p(4, StatusPresensi.hadir, '07:55', '17:03'),
      p(5, StatusPresensi.wfh, '08:00', '16:58',
          'WFH — 8,2 km dari kantor'),
      p(6, StatusPresensi.hadir, '07:52', '17:05'),
    ]);
  }

  void _seedPresensiOrganisasi() {
    final now = DateTime.now();
    final awal = DateTime(now.year, now.month, 1);
    for (var i = 0; i < _karyawan.length; i++) {
      final k = _karyawan[i];
      for (var d = awal; !d.isAfter(now); d = d.add(const Duration(days: 1))) {
        if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) {
          continue;
        }
        final hariIni = _hariSama(d, now);
        // Karyawan yang sedang login mencatat presensi sendiri hari ini.
        if (hariIni && k.nama == _pengguna.nama) continue;

        final acak = (i * 7 + d.day * 5 + d.month) % 23;
        final StatusPresensi status;
        if (acak == 0) {
          status = StatusPresensi.izinDisetujui;
        } else if (acak < 3) {
          status = StatusPresensi.wfh;
        } else if (acak < 6) {
          status = StatusPresensi.terlambat;
        } else {
          status = StatusPresensi.hadir;
        }

        final menitMasuk = status == StatusPresensi.terlambat
            ? 8 * 60 + 18 + acak
            : 7 * 60 + 45 + (acak * 3) % 18;
        final jamMasuk = status == StatusPresensi.izinDisetujui
            ? '—'
            : '${(menitMasuk ~/ 60).toString().padLeft(2, '0')}:${(menitMasuk % 60).toString().padLeft(2, '0')}';

        final jamPulang = status == StatusPresensi.izinDisetujui
            ? '—'
            : hariIni
                ? '—'
                : '${16 + (acak % 2)}:${(50 + acak % 20).toString().padLeft(2, '0')}';

        _presensiOrg.add(BarisMonitoring(
          id: 'M-${_seq++}',
          nama: k.nama,
          jabatan: k.jabatan,
          tanggal: d,
          jamMasuk: jamMasuk,
          jamPulang: jamPulang,
          lokasi: switch (status) {
            StatusPresensi.wfh => 'WFH — Jl. Pandanaran',
            StatusPresensi.izinDisetujui => '—',
            _ => geofence.namaKantor,
          },
          status: status,
          keterangan: switch (status) {
            StatusPresensi.izinDisetujui => 'Izin sakit (disetujui HC)',
            StatusPresensi.wfh => 'Di luar radius (8,2 km)',
            StatusPresensi.terlambat =>
              'Terlambat ${menitMasuk - 8 * 60} menit',
            _ => 'Tepat waktu',
          },
          jarakMeter: status == StatusPresensi.wfh ? 8200 : 8 + acak * 2,
        ));
      }
    }
  }

  void _seedPengajuan() {
    final now = DateTime.now();
    _pengajuan.addAll([
      PengajuanIzin(
        id: 'IZ-${_seq++}',
        jenis: 'Cuti Tahunan',
        tanggalMulai: now.add(const Duration(days: 3)),
        tanggalSelesai: now.add(const Duration(days: 5)),
        alasan:
            'Menghadiri acara pernikahan keluarga di luar kota dan sudah '
            'direncanakan sejak awal tahun.',
        status: StatusPengajuan.menunggu,
        namaPemohon: _pengguna.nama,
        jabatanPemohon: _pengguna.jabatan,
        diajukanPada: now.subtract(const Duration(days: 1)),
      ),
      PengajuanIzin(
        id: 'IZ-${_seq++}',
        jenis: 'Izin Sakit',
        tanggalMulai: now.subtract(const Duration(days: 7)),
        tanggalSelesai: now.subtract(const Duration(days: 7)),
        alasan: 'Demam dan sakit tenggorokan, dokter menyarankan istirahat satu hari.',
        status: StatusPengajuan.disetujui,
        lampiran: const Lampiran(
            nama: 'surat-keterangan-dokter.pdf',
            ukuran: 184320,
            tipe: 'application/pdf'),
        diprosesOleh: 'Bambang Santoso (HC)',
        namaPemohon: _pengguna.nama,
        jabatanPemohon: _pengguna.jabatan,
        diajukanPada: now.subtract(const Duration(days: 8)),
      ),
      PengajuanIzin(
        id: 'IZ-${_seq++}',
        jenis: 'Izin Keperluan Pribadi',
        tanggalMulai: now.subtract(const Duration(days: 2)),
        tanggalSelesai: now.subtract(const Duration(days: 2)),
        alasan: 'Mengurus dokumen kependudukan di kantor kelurahan.',
        status: StatusPengajuan.ditolak,
        diprosesOleh: 'Bambang Santoso (HC)',
        alasanPenolakan:
            'Bertepatan dengan jadwal rilis aplikasi. Silakan ajukan ulang '
            'pada tanggal lain.',
        namaPemohon: 'Nadia Salsabila',
        jabatanPemohon: 'Quality Assurance',
        diajukanPada: now.subtract(const Duration(days: 3)),
      ),
      PengajuanIzin(
        id: 'IZ-${_seq++}',
        jenis: 'Izin Sakit',
        tanggalMulai: now,
        tanggalSelesai: now,
        alasan: 'Demam dan sakit tenggorokan, disarankan istirahat oleh dokter.',
        status: StatusPengajuan.menunggu,
        lampiran: const Lampiran(
            nama: 'surat-dokter.pdf',
            ukuran: 96256,
            tipe: 'application/pdf'),
        namaPemohon: 'Rizky Pratama',
        jabatanPemohon: 'Backend Engineer',
        diajukanPada: now.subtract(const Duration(hours: 5)),
      ),
    ]);
  }
}

extension on Karyawan {
  Karyawan copyWithEmail(String email) => Karyawan(
        id: id,
        nama: nama,
        jabatan: jabatan,
        departemen: departemen,
        email: email,
        jadwal: jadwal,
        peran: peran,
        aktif: aktif,
      );
}
