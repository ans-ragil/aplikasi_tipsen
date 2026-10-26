/// Model data TIPSEN (fase simulasi — nanti dipetakan ke koleksi Firestore).
library;

/// Peran akun — dipakai nanti saat ada portal admin.
enum PeranAkun { karyawan, adminHC }

/// Karyawan / pengguna aplikasi.
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
}

/// Status satu catatan presensi.
enum StatusPresensi { hadir, terlambat, wfh, izinDisetujui }

extension StatusPresensiX on StatusPresensi {
  String get label => switch (this) {
        StatusPresensi.hadir => 'Hadir',
        StatusPresensi.terlambat => 'Terlambat',
        StatusPresensi.wfh => 'WFH',
        StatusPresensi.izinDisetujui => 'Izin Disetujui',
      };

  /// Warna konsisten: hijau = normal, oranye = perhatian.
  bool get normal => this == StatusPresensi.hadir ||
      this == StatusPresensi.izinDisetujui;
}

/// Satu catatan presensi harian.
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

  Presensi copyWith({
    String? clockIn,
    String? clockOut,
    StatusPresensi? status,
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
        keterangan: keterangan,
      );

  /// "Senin, 26 Okt 2026"
  String get tanggalLabel {
    const hari = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${hari[tanggal.weekday - 1]}, ${tanggal.day} ${bulan[tanggal.month]} ${tanggal.year}';
  }

  /// "26 Okt"
  String get tanggalPendek {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${tanggal.day} ${bulan[tanggal.month]}';
  }
}

/// Jenis pengajuan cuti/izin.
const daftarJenisPengajuan = [
  'Cuti Tahunan',
  'Izin Sakit',
  'Izin Keperluan Pribadi',
];

/// Status pengajuan izin/cuti.
enum StatusPengajuan { menunggu, disetujui, ditolak }

extension StatusPengajuanX on StatusPengajuan {
  String get label => switch (this) {
        StatusPengajuan.menunggu => 'Menunggu',
        StatusPengajuan.disetujui => 'Disetujui',
        StatusPengajuan.ditolak => 'Ditolak',
      };
}

/// Satu pengajuan izin/cuti.
class PengajuanIzin {
  const PengajuanIzin({
    required this.id,
    required this.jenis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.alasan,
    required this.status,
    this.lampiranNama,
    this.diprosesOleh,
    this.namaPemohon,
    this.jabatanPemohon,
  });

  final String id;
  final String jenis;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String alasan;
  final StatusPengajuan status;
  final String? lampiranNama;
  final String? diprosesOleh;

  /// Diisi pada daftar pengajuan yang dilihat admin/HC.
  final String? namaPemohon;
  final String? jabatanPemohon;

  PengajuanIzin copyWith({
    StatusPengajuan? status,
    String? diprosesOleh,
  }) =>
      PengajuanIzin(
        id: id,
        jenis: jenis,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        alasan: alasan,
        status: status ?? this.status,
        lampiranNama: lampiranNama,
        diprosesOleh: diprosesOleh ?? this.diprosesOleh,
        namaPemohon: namaPemohon,
        jabatanPemohon: jabatanPemohon,
      );

  String get periodeLabel {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    String f(DateTime d) => '${d.day} ${bulan[d.month]} ${d.year}';
    if (tanggalMulai.year == tanggalSelesai.year &&
        tanggalMulai.month == tanggalSelesai.month &&
        tanggalMulai.day == tanggalSelesai.day) {
      return f(tanggalMulai);
    }
    return '${f(tanggalMulai)} – ${f(tanggalSelesai)}';
  }
}

/// Konfigurasi geofence kantor.
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

  KonfigurasiGeofence copyWith({String? namaKantor, int? radiusMeter}) =>
      KonfigurasiGeofence(
        namaKantor: namaKantor ?? this.namaKantor,
        latitude: latitude,
        longitude: longitude,
        radiusMeter: radiusMeter ?? this.radiusMeter,
      );
}

// ═══════════════════════════════════════════════════════════════
// MODEL KHUSUS WEB ADMIN (HC Portal)
// ═══════════════════════════════════════════════════════════════

/// Karyawan pada daftar Manajemen Karyawan (admin).
class KaryawanAdmin {
  const KaryawanAdmin({
    required this.nama,
    required this.jabatan,
    required this.departemen,
    required this.status,
    required this.email,
  });

  final String nama;
  final String jabatan;
  final String departemen;

  /// "Aktif" atau "WFH".
  final String status;
  final String email;

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
  }) =>
      KaryawanAdmin(
        nama: nama ?? this.nama,
        jabatan: jabatan ?? this.jabatan,
        departemen: departemen ?? this.departemen,
        status: status ?? this.status,
        email: email ?? this.email,
      );
}

/// Satu baris tabel Monitoring Presensi.
class BarisMonitoring {
  const BarisMonitoring({
    required this.nama,
    required this.jabatan,
    required this.jamMasuk,
    required this.jamPulang,
    required this.lokasi,
    required this.status,
    required this.keterangan,
    required this.jarakMeter,
  });

  final String nama;
  final String jabatan;
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
}
