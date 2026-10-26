/// Model data TIPSEN + serialisasi JSON untuk penyimpanan lokal.
library;

import 'dart:convert';
import 'dart:typed_data';

// ═══════════════════════════════════════════════════════════════
// UTILITAS FORMAT (dipakai model & layar)
// ═══════════════════════════════════════════════════════════════
const namaBulanPanjang = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const namaBulanPendek = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const namaHari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

/// "Senin, 26 Oktober 2026"
String tanggalPanjang(DateTime d) =>
    '${namaHari[d.weekday - 1]}, ${d.day} ${namaBulanPanjang[d.month]} ${d.year}';

/// "26 Okt 2026"
String tanggalSingkat(DateTime d) =>
    '${d.day} ${namaBulanPendek[d.month]} ${d.year}';

/// "26 Okt"
String tanggalPendek(DateTime d) => '${d.day} ${namaBulanPendek[d.month]}';

/// "Oktober 2026"
String bulanTahun(DateTime d) => '${namaBulanPanjang[d.month]} ${d.year}';

/// "08:04"
String jamMenit(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "08:04:37"
String jamLengkap(DateTime d) => '${jamMenit(d)}:${d.second.toString().padLeft(2, '0')}';

/// 492 → "8 jam 12 menit", 0 → "< 1 menit"
String durasiLabel(int menit) {
  if (menit < 0) return '—';
  if (menit == 0) return '< 1 menit';
  final j = menit ~/ 60;
  final m = menit % 60;
  if (j == 0) return '$m menit';
  if (m == 0) return '$j jam';
  return '$j jam $m menit';
}

/// 251658 → "246 KB"
String ukuranFile(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// "07:58" → 478 (menit sejak tengah malam); null bila bukan format jam.
int? menitDariJam(String? jam) {
  if (jam == null) return null;
  final bagian = jam.split(':');
  if (bagian.length < 2) return null;
  final h = int.tryParse(bagian[0]);
  final m = int.tryParse(bagian[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// Selisih dua jam ("08:00" → "17:05") dalam menit.
/// 0 tetap dihitung (Clock In & Clock Out pada menit yang sama);
/// hanya nilai negatif (data tidak masuk akal) yang dianggap tidak valid.
int? selisihMenit(String? masuk, String? pulang) {
  final a = menitDariJam(masuk);
  final b = menitDariJam(pulang);
  if (a == null || b == null) return null;
  final d = b - a;
  return d >= 0 ? d : null;
}

DateTime _parseTanggal(Object? v) =>
    DateTime.tryParse((v as String?) ?? '') ?? DateTime.now();

String _iso(DateTime d) => d.toIso8601String();

// ═══════════════════════════════════════════════════════════════
// AKUN
// ═══════════════════════════════════════════════════════════════
enum PeranAkun { karyawan, adminHC }

extension PeranAkunX on PeranAkun {
  String get label =>
      this == PeranAkun.karyawan ? 'Karyawan' : 'Administrator HC';
  String get kode => this == PeranAkun.karyawan ? 'karyawan' : 'admin';
}

class Karyawan {
  const Karyawan({
    required this.id,
    required this.nama,
    required this.jabatan,
    required this.departemen,
    required this.email,
    required this.jadwal,
    required this.peran,
    this.aktif = true,
  });

  final String id;
  final String nama;
  final String jabatan;
  final String departemen;
  final String email;
  final String jadwal;
  final PeranAkun peran;
  final bool aktif;

  String get inisial {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 2).toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'jabatan': jabatan,
        'departemen': departemen,
        'email': email,
        'jadwal': jadwal,
        'peran': peran.kode,
        'aktif': aktif,
      };

  static Karyawan fromJson(Map<String, dynamic> j) => Karyawan(
        id: j['id'] as String,
        nama: j['nama'] as String,
        jabatan: j['jabatan'] as String,
        departemen: j['departemen'] as String,
        email: j['email'] as String,
        jadwal: j['jadwal'] as String,
        peran: j['peran'] == 'admin' ? PeranAkun.adminHC : PeranAkun.karyawan,
        aktif: j['aktif'] as bool? ?? true,
      );
}

// ═══════════════════════════════════════════════════════════════
// LAMPIRAN (file asli yang diunggah karyawan)
// ═══════════════════════════════════════════════════════════════
class Lampiran {
  const Lampiran({
    required this.nama,
    required this.ukuran,
    required this.tipe,
    this.bytes,
  });

  final String nama;
  final int ukuran;
  final String tipe;

  /// Isi file. Null untuk lampiran contoh (data awal) yang tidak menyimpan file.
  final Uint8List? bytes;

  bool get gambar => tipe.startsWith('image/');
  String get ukuranLabel => ukuranFile(ukuran);
  String get ekstensi {
    final i = nama.lastIndexOf('.');
    return i < 0 ? 'FILE' : nama.substring(i + 1).toUpperCase();
  }

  Map<String, dynamic> toJson({bool denganIsi = true}) => {
        'nama': nama,
        'ukuran': ukuran,
        'tipe': tipe,
        if (denganIsi && bytes != null) 'bytes': base64Encode(bytes!),
      };

  static Lampiran fromJson(Map<String, dynamic> j) => Lampiran(
        nama: j['nama'] as String,
        ukuran: (j['ukuran'] as num).toInt(),
        tipe: j['tipe'] as String? ?? 'application/octet-stream',
        bytes: j['bytes'] == null ? null : base64Decode(j['bytes'] as String),
      );
}

// ═══════════════════════════════════════════════════════════════
// PRESENSI
// ═══════════════════════════════════════════════════════════════
enum StatusPresensi { hadir, terlambat, wfh, izinDisetujui }

extension StatusPresensiX on StatusPresensi {
  String get label => switch (this) {
        StatusPresensi.hadir => 'Hadir',
        StatusPresensi.terlambat => 'Terlambat',
        StatusPresensi.wfh => 'WFH',
        StatusPresensi.izinDisetujui => 'Izin Disetujui',
      };

  String get kode => switch (this) {
        StatusPresensi.hadir => 'hadir',
        StatusPresensi.terlambat => 'terlambat',
        StatusPresensi.wfh => 'wfh',
        StatusPresensi.izinDisetujui => 'izin',
      };

  bool get normal =>
      this == StatusPresensi.hadir || this == StatusPresensi.izinDisetujui;
}

StatusPresensi statusPresensiDari(Object? kode) => switch (kode) {
      'terlambat' => StatusPresensi.terlambat,
      'wfh' => StatusPresensi.wfh,
      'izin' => StatusPresensi.izinDisetujui,
      _ => StatusPresensi.hadir,
    };

class Presensi {
  const Presensi({
    required this.id,
    required this.tanggal,
    required this.status,
    required this.lokasiNama,
    required this.jarakMeter,
    required this.dalamRadius,
    this.clockIn,
    this.clockOut,
    this.selfie = false,
    this.keterangan,
    this.foto,
  });

  final String id;
  final DateTime tanggal;
  final StatusPresensi status;
  final String lokasiNama;
  final int jarakMeter;
  final bool dalamRadius;
  final String? clockIn;
  final String? clockOut;
  final bool selfie;
  final String? keterangan;
  final Uint8List? foto;

  /// Durasi kerja dalam menit (null bila belum Clock Out).
  int? get durasiMenit => selisihMenit(clockIn, clockOut);

  /// Label durasi; "—" bila presensi belum lengkap.
  String get durasi => lengkap ? durasiLabel(durasiMenit ?? 0) : '—';
  bool get lengkap => clockIn != null && clockOut != null;

  String get tanggalLabel => tanggalPanjang(tanggal);
  String get tanggalPendekLabel => tanggalPendek(tanggal);

  Presensi copyWith({
    String? clockIn,
    String? clockOut,
    StatusPresensi? status,
    String? keterangan,
  }) =>
      Presensi(
        id: id,
        tanggal: tanggal,
        status: status ?? this.status,
        lokasiNama: lokasiNama,
        jarakMeter: jarakMeter,
        dalamRadius: dalamRadius,
        clockIn: clockIn ?? this.clockIn,
        clockOut: clockOut ?? this.clockOut,
        selfie: selfie,
        keterangan: keterangan ?? this.keterangan,
        foto: foto,
      );

  Map<String, dynamic> toJson({bool denganFoto = true}) => {
        'id': id,
        'tanggal': _iso(tanggal),
        'status': status.kode,
        'lokasi': lokasiNama,
        'jarak': jarakMeter,
        'dalamRadius': dalamRadius,
        'clockIn': clockIn,
        'clockOut': clockOut,
        'selfie': selfie,
        'keterangan': keterangan,
        if (denganFoto && foto != null) 'foto': base64Encode(foto!),
      };

  static Presensi fromJson(Map<String, dynamic> j) => Presensi(
        id: j['id'] as String,
        tanggal: _parseTanggal(j['tanggal']),
        status: statusPresensiDari(j['status']),
        lokasiNama: j['lokasi'] as String? ?? '-',
        jarakMeter: (j['jarak'] as num?)?.toInt() ?? 0,
        dalamRadius: j['dalamRadius'] as bool? ?? true,
        clockIn: j['clockIn'] as String?,
        clockOut: j['clockOut'] as String?,
        selfie: j['selfie'] as bool? ?? false,
        keterangan: j['keterangan'] as String?,
        foto: j['foto'] == null ? null : base64Decode(j['foto'] as String),
      );
}

// ═══════════════════════════════════════════════════════════════
// PENGAJUAN IZIN / CUTI
// ═══════════════════════════════════════════════════════════════
const daftarJenisPengajuan = [
  'Cuti Tahunan',
  'Izin Sakit',
  'Izin Keperluan Pribadi',
];

enum StatusPengajuan { menunggu, disetujui, ditolak }

extension StatusPengajuanX on StatusPengajuan {
  String get label => switch (this) {
        StatusPengajuan.menunggu => 'Menunggu',
        StatusPengajuan.disetujui => 'Disetujui',
        StatusPengajuan.ditolak => 'Ditolak',
      };

  String get kode => switch (this) {
        StatusPengajuan.menunggu => 'menunggu',
        StatusPengajuan.disetujui => 'disetujui',
        StatusPengajuan.ditolak => 'ditolak',
      };
}

StatusPengajuan statusPengajuanDari(Object? kode) => switch (kode) {
      'disetujui' => StatusPengajuan.disetujui,
      'ditolak' => StatusPengajuan.ditolak,
      _ => StatusPengajuan.menunggu,
    };

class PengajuanIzin {
  const PengajuanIzin({
    required this.id,
    required this.jenis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.alasan,
    required this.status,
    this.lampiran,
    this.diprosesOleh,
    this.namaPemohon,
    this.jabatanPemohon,
    this.alasanPenolakan,
    this.diajukanPada,
  });

  final String id;
  final String jenis;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String alasan;
  final StatusPengajuan status;
  final Lampiran? lampiran;
  final String? diprosesOleh;

  /// Diisi untuk pengajuan dari karyawan (dipakai portal HC).
  final String? namaPemohon;
  final String? jabatanPemohon;

  /// Catatan HC saat menolak — terlihat oleh karyawan.
  final String? alasanPenolakan;
  final DateTime? diajukanPada;

  int get jumlahHari => tanggalSelesai.difference(tanggalMulai).inDays + 1;

  String get periodeLabel {
    final a = tanggalSingkat(tanggalMulai);
    final b = tanggalSingkat(tanggalSelesai);
    if (a == b) return a;
    return '$a – $b';
  }

  PengajuanIzin copyWith({
    StatusPengajuan? status,
    String? diprosesOleh,
    String? alasanPenolakan,
    Lampiran? lampiran,
  }) =>
      PengajuanIzin(
        id: id,
        jenis: jenis,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        alasan: alasan,
        status: status ?? this.status,
        lampiran: lampiran ?? this.lampiran,
        diprosesOleh: diprosesOleh ?? this.diprosesOleh,
        namaPemohon: namaPemohon,
        jabatanPemohon: jabatanPemohon,
        alasanPenolakan: alasanPenolakan ?? this.alasanPenolakan,
        diajukanPada: diajukanPada,
      );

  Map<String, dynamic> toJson({bool denganLampiran = true}) => {
        'id': id,
        'jenis': jenis,
        'mulai': _iso(tanggalMulai),
        'selesai': _iso(tanggalSelesai),
        'alasan': alasan,
        'status': status.kode,
        if (lampiran != null)
          'lampiran': lampiran!.toJson(denganIsi: denganLampiran),
        'diprosesOleh': diprosesOleh,
        'namaPemohon': namaPemohon,
        'jabatanPemohon': jabatanPemohon,
        'alasanPenolakan': alasanPenolakan,
        'diajukanPada': diajukanPada == null ? null : _iso(diajukanPada!),
      };

  static PengajuanIzin fromJson(Map<String, dynamic> j) => PengajuanIzin(
        id: j['id'] as String,
        jenis: j['jenis'] as String,
        tanggalMulai: _parseTanggal(j['mulai']),
        tanggalSelesai: _parseTanggal(j['selesai']),
        alasan: j['alasan'] as String? ?? '',
        status: statusPengajuanDari(j['status']),
        lampiran: j['lampiran'] == null
            ? null
            : Lampiran.fromJson(j['lampiran'] as Map<String, dynamic>),
        diprosesOleh: j['diprosesOleh'] as String?,
        namaPemohon: j['namaPemohon'] as String?,
        jabatanPemohon: j['jabatanPemohon'] as String?,
        alasanPenolakan: j['alasanPenolakan'] as String?,
        diajukanPada: j['diajukanPada'] == null
            ? null
            : _parseTanggal(j['diajukanPada']),
      );
}

// ═══════════════════════════════════════════════════════════════
// GEOFENCE
// ═══════════════════════════════════════════════════════════════
class KonfigurasiGeofence {
  const KonfigurasiGeofence({
    this.namaKantor = 'Kantor Utama TIPSEN',
    this.latitude = -6.982400,
    this.longitude = 110.409100,
    this.radiusMeter = 50,
  });

  final String namaKantor;
  final double latitude;
  final double longitude;
  final int radiusMeter;

  String get koordinatLabel =>
      '${latitude.toStringAsFixed(6)} , ${longitude.toStringAsFixed(6)}';

  KonfigurasiGeofence copyWith({
    String? namaKantor,
    double? latitude,
    double? longitude,
    int? radiusMeter,
  }) =>
      KonfigurasiGeofence(
        namaKantor: namaKantor ?? this.namaKantor,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeter: radiusMeter ?? this.radiusMeter,
      );

  Map<String, dynamic> toJson() => {
        'nama': namaKantor,
        'lat': latitude,
        'lng': longitude,
        'radius': radiusMeter,
      };

  static KonfigurasiGeofence fromJson(Map<String, dynamic> j) =>
      KonfigurasiGeofence(
        namaKantor: j['nama'] as String? ?? 'Kantor Utama TIPSEN',
        latitude: (j['lat'] as num?)?.toDouble() ?? -6.9824,
        longitude: (j['lng'] as num?)?.toDouble() ?? 110.4091,
        radiusMeter: (j['radius'] as num?)?.toInt() ?? 50,
      );
}

// ═══════════════════════════════════════════════════════════════
// MODEL PORTAL HC
// ═══════════════════════════════════════════════════════════════

/// Karyawan pada daftar Manajemen Karyawan.
class KaryawanAdmin {
  const KaryawanAdmin({
    required this.id,
    required this.nama,
    required this.jabatan,
    required this.departemen,
    required this.status,
    required this.email,
    this.aktif = true,
  });

  final String id;
  final String nama;
  final String jabatan;
  final String departemen;

  /// "Aktif" | "WFH" | "Nonaktif"
  final String status;
  final String email;
  final bool aktif;

  String get inisial {
    final p = nama.trim().split(RegExp(r'\s+'));
    if (p.length == 1) return p.first.substring(0, 2).toUpperCase();
    return (p.first[0] + p[1][0]).toUpperCase();
  }

  KaryawanAdmin copyWith({
    String? nama,
    String? jabatan,
    String? departemen,
    String? status,
    String? email,
    bool? aktif,
  }) =>
      KaryawanAdmin(
        id: id,
        nama: nama ?? this.nama,
        jabatan: jabatan ?? this.jabatan,
        departemen: departemen ?? this.departemen,
        status: status ?? this.status,
        email: email ?? this.email,
        aktif: aktif ?? this.aktif,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'jabatan': jabatan,
        'departemen': departemen,
        'status': status,
        'email': email,
        'aktif': aktif,
      };

  static KaryawanAdmin fromJson(Map<String, dynamic> j) => KaryawanAdmin(
        id: j['id'] as String,
        nama: j['nama'] as String,
        jabatan: j['jabatan'] as String,
        departemen: j['departemen'] as String,
        status: j['status'] as String? ?? 'Aktif',
        email: j['email'] as String,
        aktif: j['aktif'] as bool? ?? true,
      );
}

/// Satu catatan presensi karyawan pada portal HC (sumber data monitoring,
/// dashboard, dan laporan — sekaligus tempat presensi karyawan sendiri dicatat).
class BarisMonitoring {
  const BarisMonitoring({
    required this.id,
    required this.nama,
    required this.jabatan,
    required this.tanggal,
    required this.jamMasuk,
    required this.jamPulang,
    required this.lokasi,
    required this.status,
    required this.keterangan,
    required this.jarakMeter,
  });

  final String id;
  final String nama;
  final String jabatan;
  final DateTime tanggal;
  final String jamMasuk;
  final String jamPulang;
  final String lokasi;
  final StatusPresensi status;
  final String keterangan;
  final int jarakMeter;

  String get inisial {
    final p = nama.trim().split(RegExp(r'\s+'));
    if (p.length == 1) return p.first.substring(0, 2).toUpperCase();
    return (p.first[0] + p[1][0]).toUpperCase();
  }

  int? get durasiMenit => selisihMenit(
        jamMasuk == '—' ? null : jamMasuk,
        jamPulang == '—' ? null : jamPulang,
      );

  /// Label durasi; "—" bila jam masuk/pulang belum lengkap.
  String get durasi => (jamMasuk == '—' || jamPulang == '—')
      ? '—'
      : durasiLabel(durasiMenit ?? 0);

  BarisMonitoring copyWith({
    String? jamMasuk,
    String? jamPulang,
    String? lokasi,
    StatusPresensi? status,
    String? keterangan,
    int? jarakMeter,
  }) =>
      BarisMonitoring(
        id: id,
        nama: nama,
        jabatan: jabatan,
        tanggal: tanggal,
        jamMasuk: jamMasuk ?? this.jamMasuk,
        jamPulang: jamPulang ?? this.jamPulang,
        lokasi: lokasi ?? this.lokasi,
        status: status ?? this.status,
        keterangan: keterangan ?? this.keterangan,
        jarakMeter: jarakMeter ?? this.jarakMeter,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'jabatan': jabatan,
        'tanggal': _iso(tanggal),
        'jamMasuk': jamMasuk,
        'jamPulang': jamPulang,
        'lokasi': lokasi,
        'status': status.kode,
        'keterangan': keterangan,
        'jarak': jarakMeter,
      };

  static BarisMonitoring fromJson(Map<String, dynamic> j) => BarisMonitoring(
        id: j['id'] as String,
        nama: j['nama'] as String,
        jabatan: j['jabatan'] as String? ?? '-',
        tanggal: _parseTanggal(j['tanggal']),
        jamMasuk: j['jamMasuk'] as String? ?? '—',
        jamPulang: j['jamPulang'] as String? ?? '—',
        lokasi: j['lokasi'] as String? ?? '—',
        status: statusPresensiDari(j['status']),
        keterangan: j['keterangan'] as String? ?? '',
        jarakMeter: (j['jarak'] as num?)?.toInt() ?? 0,
      );
}
