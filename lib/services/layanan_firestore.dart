/// Layanan data TIPSEN — Cloud Firestore (Minggu 10–11).
///
/// Pemetaan ERD proyek menjadi EMPAT collection:
///
/// | Collection          | Isi                                   | Operasi |
/// |---------------------|----------------------------------------|---------|
/// | `users/{uid}`       | Profil pengguna                        | Create saat daftar/masuk, Read |
/// | `lokasi/{kode}`     | Master lokasi kantor (auto-seed)       | Read real-time |
/// | `presensi/{uid_tgl}`| Catatan kehadiran per hari             | Create (Clock In), Update (Clock Out), Read real-time |
/// | `pengajuan/{id}`    | Pengajuan izin/cuti karyawan           | Create, Update (ubah oleh pemilik / keputusan HC), Delete (batalkan), Read real-time |
///
/// Minggu 11 — Update & Delete milik pemilik data:
///  - `ubahPengajuan()` memakai `update()` (BUKAN `set()`) sehingga field
///    audit `dibuatPada`, `idPengguna`, dan `status` tetap utuh; field
///    `diubahPada` diisi serverTimestamp.
///  - Aturan bisnis "hanya pemilik + hanya status Menunggu" ditulis SEKALI
///    sebagai fungsi bersama `pastikanBolehDiubah()` dan dipakai ulang oleh
///    `ubahPengajuan()` maupun `batalkanPengajuan()`.
///  - Cek tumpang tindih periode menerima `abaikanIdPengajuan` agar dokumen
///    yang sedang diubah tidak dianggap bentrok dengan dirinya sendiri.
///
/// Pemisahan layanan dari UI:
///  - `LayananFirestore` — implementasi Cloud Firestore asli (produksi).
///  - `LayananMemori`    — implementasi memori untuk widget test & fallback
///    saat Firebase tidak terinisialisasi (tanpa jaringan, cepat).
///
/// Denormalisasi: dokumen `presensi` ikut menyimpan `lokasiNama` sehingga
/// daftar riwayat cukup satu kali baca (Firestore tidak mendukung JOIN).
/// Field `uid` juga tersimpan agar query real-time cukup satu `.where()`
/// (pengurutan dilakukan di sisi Dart untuk menghindari composite index).

library;

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

/// Kesalahan aturan bisnis — mis. presensi ganda pada hari yang sama.
class AturanBisnisException implements Exception {
  AturanBisnisException(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// Penolakan operasi ubah/hapus (Minggu 11) — dilempar [pastikanBolehDiubah]
/// saat pemanggil bukan pemilik dokumen atau status sudah diputuskan HC.
/// Semua kegagalan dilempar sebagai exception agar UI dapat menampilkan
/// pesan yang jelas (bukan hanya permission-denied dari server).
class OperasiDitolakException implements Exception {
  const OperasiDitolakException(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

// ═══════════════════════════════════════════════════════════════
// ATURAN BISNIS UBAH/HAPUS (Minggu 11 — ditulis sekali, dipakai ulang)
// ═══════════════════════════════════════════════════════════════

/// Syarat boleh mengubah/membatalkan pengajuan, sesuai modul Minggu 11:
///  1. Pengguna sudah login (dijamin pemanggil — uid tidak boleh kosong).
///  2. Dokumen masih ada (diperiksa pemanggil sebelum snapshot dibaca).
///  3. `idPengguna == uid` — hanya PEMILIK dokumen.
///  4. `status == menunggu` — hanya selama belum diputuskan HC.
///
/// Aturan yang sama juga tertulis di Security Rules agar data tetap aman
/// meski API dipanggil langsung di luar aplikasi (dua lapis pengaman).
void pastikanBolehDiubah({
  required Map<String, dynamic> data,
  required String uidAktif,
  required String aksi,
}) {
  if (data['idPengguna'] != uidAktif) {
    throw const OperasiDitolakException(
        'Anda bukan pemilik pengajuan ini. Hanya pemilik yang boleh '
        'mengubah atau membatalkan datanya.');
  }
  if ((data['status'] as String? ?? '') != 'menunggu') {
    throw OperasiDitolakException(
        'Pengajuan sudah diputuskan HC dan tidak dapat $aksi lagi.');
  }
}

// ═══════════════════════════════════════════════════════════════
// MODEL MASTER LOKASI (collection `lokasi`)
// ═══════════════════════════════════════════════════════════════

/// Satu lokasi kantor/cabang tempat karyawan boleh melakukan presensi.
class LokasiKantor {
  const LokasiKantor({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.radiusMeter,
    this.utama = false,
  });

  final String id;
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final int radiusMeter;

  /// Lokasi utama = sumber konfigurasi geofence aplikasi.
  final bool utama;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'alamat': alamat,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeter': radiusMeter,
        'utama': utama,
      };

  static LokasiKantor fromMap(Map<String, dynamic> j) => LokasiKantor(
        id: j['id'] as String,
        nama: j['nama'] as String? ?? '-',
        alamat: j['alamat'] as String? ?? '',
        latitude: (j['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (j['longitude'] as num?)?.toDouble() ?? 0,
        radiusMeter: (j['radiusMeter'] as num?)?.toInt() ?? 50,
        utama: j['utama'] as bool? ?? false,
      );
}

/// Empat lokasi awal — diisikan SEKALI saja ke collection `lokasi`
/// melalui WriteBatch saat collection masih kosong (auto-seed).
const daftarLokasiAwal = [
  LokasiKantor(
    id: 'lokasi-utama',
    nama: 'Kantor Utama TIPSEN',
    alamat: 'Jl. Pandanaran No. 12, Semarang Tengah',
    latitude: -6.982400,
    longitude: 110.409100,
    radiusMeter: 50,
    utama: true,
  ),
  LokasiKantor(
    id: 'lokasi-bsb',
    nama: 'Cabang BSB Village',
    alamat: 'Jl. Puri Anjasmoro, BSB Village, Semarang',
    latitude: -6.975800,
    longitude: 110.387100,
    radiusMeter: 40,
  ),
  LokasiKantor(
    id: 'lokasi-banyumanik',
    nama: 'Cabang Banyumanik',
    alamat: 'Jl. Srondol Wetan, Banyumanik, Semarang',
    latitude: -7.062700,
    longitude: 110.440100,
    radiusMeter: 40,
  ),
  LokasiKantor(
    id: 'lokasi-terboyo',
    nama: 'Gudang Terboyo',
    alamat: 'Kawasan Industri Terboyo, Semarang Utara',
    latitude: -6.946700,
    longitude: 110.460800,
    radiusMeter: 60,
  ),
];

// ═══════════════════════════════════════════════════════════════
// KUNCI DOKUMEN
// ═══════════════════════════════════════════════════════════════

/// "2026-11-17" — kunci hari untuk dokumen presensi.
String kunciHari(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Doc ID presensi = `uid_tanggal` → satu dokumen per pengguna per hari,
/// sekaligus bentuk pencegahan presensi ganda yang paling murah (tanpa query).
String idDokumenPresensi(String uid, DateTime hari) => '${uid}_${kunciHari(hari)}';

// ═══════════════════════════════════════════════════════════════
// KONTRAK LAYANAN
// ═══════════════════════════════════════════════════════════════

/// Kontrak layanan data TIPSEN. Kode UI (AppState) hanya berbicara dengan
/// kontrak ini sehingga widget test dapat memakai [LayananMemori].
abstract class LayananTipsen {
  /// Create profil pengguna ke `users/{uid}` (diabaikan bila sudah ada).
  Future<void> simpanPengguna({
    required String uid,
    required String email,
    String? namaLengkap,
    required String peran,
  });

  /// Read profil pengguna dari `users/{uid}`; null bila belum ada.
  Future<Map<String, dynamic>?> bacaPengguna(String uid);

  /// Auto-seed master lokasi bila collection `lokasi` masih kosong.
  Future<void> isiLokasiAwalJikaKosong();

  /// Read real-time master lokasi (StreamBuilder di Beranda).
  Stream<List<LokasiKantor>> streamLokasi();

  /// Create dokumen presensi hari ini. Melempar [AturanBisnisException]
  /// bila pengguna sudah presensi pada hari yang sama (aturan bisnis ERD).
  Future<void> tambahPresensi(Presensi catatan, String uid);

  /// Perbarui jam pulang pada dokumen presensi hari yang sama.
  Future<void> simpanClockOut(String idDokumen, String jamPulang);

  /// Read real-time presensi milik pengguna (filter `uid`, sort di Dart).
  Stream<List<Presensi>> streamPresensiSaya(String uid);

  // ── Pengajuan izin (Minggu 10 Create&Read, Minggu 11 Update&Delete) ──

  /// Read real-time pengajuan: milik pengguna (karyawan) atau seluruh
  /// collection (portal HC, [sebagaiHC] = true).
  Stream<List<PengajuanIzin>> streamPengajuanTampil(
      String uid, {
        required bool sebagaiHC,
      });

  /// Create pengajuan baru. Melempar [OperasiDitolakException] bila periode
  /// tumpang tindih dengan pengajuan lain yang belum ditolak.
  /// Mengembalikan salinan dengan ID final (Firestore auto-ID).
  Future<PengajuanIzin> tambahPengajuan(PengajuanIzin p, String uid);

  /// Update sebagian field pengajuan milik pemilik yang masih Menunggu.
  /// Melempar [OperasiDitolakException] bila bukan pemilik, status sudah
  /// diputuskan, atau periode baru tumpang tindih dengan pengajuan lain.
  Future<void> ubahPengajuan({
    required String idPengajuan,
    required String uid,
    required String jenis,
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    Lampiran? lampiran,
  });

  /// Delete pengajuan milik pemilik yang masih Menunggu (tombol Batalkan).
  Future<void> batalkanPengajuan(String idPengajuan, String uid);

  /// Update keputusan HC (Setujui/Tolak) — hanya untuk peran admin.
  Future<void> putuskanPengajuan({
    required String idPengajuan,
    required bool setujui,
    required String diprosesOleh,
    String? alasanPenolakan,
  });
}

/// Pilih layanan sesuai lingkungan: Firestore bila Firebase sudah
/// terinisialisasi, memori bila tidak (widget test).
LayananTipsen buatLayananTipsen() {
  try {
    FirebaseFirestore.instance; // lempar StateError bila belum init
    return LayananFirestore();
  } catch (_) {
    return LayananMemori();
  }
}

// ═══════════════════════════════════════════════════════════════
// IMPLEMENTASI CLOUD FIRESTORE
// ═══════════════════════════════════════════════════════════════

class LayananFirestore implements LayananTipsen {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── users ─────────────────────────────────────────────────────
  @override
  Future<void> simpanPengguna({
    required String uid,
    required String email,
    String? namaLengkap,
    required String peran,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return; // Profil sudah ada — jangan menimpa.
    await ref.set({
      'uid': uid,
      'nama': (namaLengkap ?? '').trim().isNotEmpty
          ? namaLengkap!.trim()
          : email.split('@').first,
      'email': email,
      'jabatan': 'Karyawan',
      'departemen': 'Belum diatur oleh HC',
      'jadwal': 'Shift Pagi · 08:00 – 17:00',
      'peran': peran,
      'aktif': true,
      'dibuatPada': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, dynamic>?> bacaPengguna(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  // ── lokasi (master data, auto-seed) ───────────────────────────
  @override
  Future<void> isiLokasiAwalJikaKosong() async {
    final cek = await _db.collection('lokasi').limit(1).get();
    if (cek.docs.isNotEmpty) return;
    final batch = _db.batch();
    for (final l in daftarLokasiAwal) {
      batch.set(_db.collection('lokasi').doc(l.id), l.toMap());
    }
    await batch.commit();
  }

  @override
  Stream<List<LokasiKantor>> streamLokasi() =>
      _db.collection('lokasi').snapshots().map((snap) {
        final daftar = snap.docs
            .map((d) => LokasiKantor.fromMap(d.data()))
            .toList();
        // Lokasi utama paling atas, lalu alfabetis.
        daftar.sort((a, b) {
          if (a.utama != b.utama) return a.utama ? -1 : 1;
          return a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
        });
        return daftar;
      });

  // ── presensi ──────────────────────────────────────────────────
  Map<String, dynamic> _petaPresensi(Presensi p, String uid) => {
        'uid': uid,
        'tanggal': kunciHari(p.tanggal),
        'status': p.status.kode,
        'clockIn': p.clockIn,
        'clockOut': p.clockOut,
        'lokasiNama': p.lokasiNama,
        'jarakMeter': p.jarakMeter,
        'dalamRadius': p.dalamRadius,
        'selfie': p.selfie,
        'keterangan': p.keterangan,
        // Selfie ikut disimpan selama masih kecil (< 200 KB) karena
        // dokumen Firestore dibatasi 1 MiB.
        'foto': (p.foto != null && p.foto!.length <= 200 * 1024)
            ? base64Encode(p.foto!)
            : null,
        'dibuatPada': FieldValue.serverTimestamp(),
      };

  Presensi _dariFirestore(String docId, Map<String, dynamic> j) {
    final hari = DateTime.tryParse(j['tanggal'] as String? ?? '') ??
        DateTime.now();
    return Presensi(
      id: docId,
      tanggal: hari,
      status: statusPresensiDari(j['status']),
      lokasiNama: j['lokasiNama'] as String? ?? '-',
      jarakMeter: (j['jarakMeter'] as num?)?.toInt() ?? 0,
      dalamRadius: j['dalamRadius'] as bool? ?? true,
      clockIn: j['clockIn'] as String?,
      clockOut: j['clockOut'] as String?,
      selfie: j['selfie'] as bool? ?? false,
      keterangan: j['keterangan'] as String?,
      foto: j['foto'] == null ? null : base64Decode(j['foto'] as String),
    );
  }

  @override
  Future<void> tambahPresensi(Presensi catatan, String uid) async {
    final docId = idDokumenPresensi(uid, catatan.tanggal);
    final ref = _db.collection('presensi').doc(docId);

    // Aturan bisnis ERD: satu presensi per pengguna per hari. Dicek
    // SEBELUM menulis (analogi "tolak jadwal bentrok" pada modul).
    final ada = await ref.get();
    if (ada.exists) {
      throw AturanBisnisException(
          'Anda sudah melakukan presensi hari ini. Clock Out untuk menutup sesi.');
    }

    await ref.set(_petaPresensi(catatan, uid));
  }

  @override
  Future<void> simpanClockOut(String idDokumen, String jamPulang) async {
    await _db
        .collection('presensi')
        .doc(idDokumen)
        .update({'clockOut': jamPulang});
  }

  @override
  Stream<List<Presensi>> streamPresensiSaya(String uid) =>
      // Satu .where() saja — pengurutan terbaru dilakukan di sisi Dart agar
      // tidak butuh composite index (lihat tips modul Minggu 10).
      _db
          .collection('presensi')
          .where('uid', isEqualTo: uid)
          .snapshots()
          .map((snap) {
        final daftar = snap.docs
            .map((d) => _dariFirestore(d.id, d.data()))
            .toList();
        daftar.sort((a, b) => b.tanggal.compareTo(a.tanggal));
        return daftar;
      });

  // ── pengajuan (Minggu 10–11) ─────────────────────────────────

  /// Lampiran ikut ke dokumen selama masih muat: Firestore 1 MiB/dokumen,
  /// base64 membengkak ±33% → simpan isi berkas hanya bila ≤ 500 KB.
  static const _maksIsiLampiranBytes = 500 * 1024;

  Map<String, dynamic>? _petaLampiran(Lampiran? l) => l == null
      ? null
      : {
          'nama': l.nama,
          'ukuran': l.ukuran,
          'tipe': l.tipe,
          'isi': (l.bytes != null && l.bytes!.length <= _maksIsiLampiranBytes)
              ? base64Encode(l.bytes!)
              : null,
        };

  Lampiran? _lampiranDari(Map<String, dynamic>? m) => m == null
      ? null
      : Lampiran(
          nama: m['nama'] as String? ?? 'lampiran',
          ukuran: (m['ukuran'] as num?)?.toInt() ?? 0,
          tipe: m['tipe'] as String? ?? 'application/octet-stream',
          bytes: m['isi'] == null
              ? null
              : base64Decode(m['isi'] as String),
        );

  Map<String, dynamic> _petaPengajuan(PengajuanIzin p, String uid) => {
        'idPengguna': uid, // field audit — pemilik, TIDAK boleh berubah
        'namaPemohon': p.namaPemohon,
        'jabatanPemohon': p.jabatanPemohon,
        'jenis': p.jenis,
        'mulai': kunciHari(p.tanggalMulai),
        'selesai': kunciHari(p.tanggalSelesai),
        'alasan': p.alasan,
        'status': p.status.kode,
        'lampiran': _petaLampiran(p.lampiran),
        'diprosesOleh': p.diprosesOleh,
        'alasanPenolakan': p.alasanPenolakan,
        'diajukanPada': p.diajukanPada == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(p.diajukanPada!),
        'diubahPada': null,
      };

  PengajuanIzin _pengajuanDariFirestore(String docId, Map<String, dynamic> j) =>
      PengajuanIzin(
        id: docId,
        jenis: j['jenis'] as String? ?? '-',
        tanggalMulai: DateTime.tryParse(j['mulai'] as String? ?? '') ??
            DateTime.now(),
        tanggalSelesai: DateTime.tryParse(j['selesai'] as String? ?? '') ??
            DateTime.now(),
        alasan: j['alasan'] as String? ?? '',
        status: statusPengajuanDari(j['status']),
        lampiran: _lampiranDari(j['lampiran'] as Map<String, dynamic>?),
        diprosesOleh: j['diprosesOleh'] as String?,
        namaPemohon: j['namaPemohon'] as String?,
        jabatanPemohon: j['jabatanPemohon'] as String?,
        alasanPenolakan: j['alasanPenolakan'] as String?,
        diajukanPada: (j['diajukanPada'] as Timestamp?)?.toDate(),
        diubahPada: (j['diubahPada'] as Timestamp?)?.toDate(),
      );

  /// Cek tumpang tindih periode (analogi "cek bentrok jadwal" modul).
  /// [abaikanIdPengajuan] mengecualikan dokumen yang sedang diubah — tanpa
  /// parameter ini, mengubah alasan tanpa mengganti tanggal akan ditolak
  /// karena dokumen itu sendiri dianggap bertumpuk (jebakan klasik modul).
  /// Query hanya pakai satu `where` (equality) — filter lain di Dart agar
  /// tidak butuh composite index.
  Future<void> _pastikanTidakTumpangTindih({
    required String uid,
    required DateTime mulai,
    required DateTime selesai,
    String? abaikanIdPengajuan,
  }) async {
    final snap = await _db
        .collection('pengajuan')
        .where('idPengguna', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) {
      if (doc.id == abaikanIdPengajuan) continue;
      final j = doc.data();
      final status = j['status'] as String? ?? '';
      if (status == 'ditolak') continue;
      final m = DateTime.tryParse(j['mulai'] as String? ?? '');
      final s = DateTime.tryParse(j['selesai'] as String? ?? '');
      if (m == null || s == null) continue;
      final tumpang = !selesai.isBefore(m) && !mulai.isAfter(s);
      if (tumpang) {
        throw OperasiDitolakException(
            'Sudah ada pengajuan ${j['jenis']} pada periode yang bertumpuk '
            '(${tanggalSingkat(m)} – ${tanggalSingkat(s)}). '
            'Ubah periode atau batalkan pengajuan lama terlebih dahulu.');
      }
    }
  }

  @override
  Stream<List<PengajuanIzin>> streamPengajuanTampil(
    String uid, {
    required bool sebagaiHC,
  }) {
    final Query<Map<String, dynamic>> query = sebagaiHC
        ? _db.collection('pengajuan')
        : _db.collection('pengajuan').where('idPengguna', isEqualTo: uid);
    return query.snapshots().map((snap) {
      final daftar = snap.docs
          .map((d) => _pengajuanDariFirestore(d.id, d.data()))
          .toList();
      daftar.sort((a, b) {
        final x = a.diajukanPada ?? a.tanggalMulai;
        final y = b.diajukanPada ?? b.tanggalMulai;
        return y.compareTo(x);
      });
      return daftar;
    });
  }

  @override
  Future<PengajuanIzin> tambahPengajuan(PengajuanIzin p, String uid) async {
    await _pastikanTidakTumpangTindih(
        uid: uid, mulai: p.tanggalMulai, selesai: p.tanggalSelesai);
    final ref = await _db
        .collection('pengajuan')
        .add(_petaPengajuan(p, uid));
    return PengajuanIzin(
      id: ref.id,
      jenis: p.jenis,
      tanggalMulai: p.tanggalMulai,
      tanggalSelesai: p.tanggalSelesai,
      alasan: p.alasan,
      status: p.status,
      lampiran: p.lampiran,
      namaPemohon: p.namaPemohon,
      jabatanPemohon: p.jabatanPemohon,
      diajukanPada: p.diajukanPada,
    );
  }

  @override
  Future<void> ubahPengajuan({
    required String idPengajuan,
    required String uid,
    required String jenis,
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    Lampiran? lampiran,
  }) async {
    // Urutan pemeriksaan menentukan kualitas pesan galat (modul Minggu 11):
    // login → dokumen ada → pemilik → status → tidak tumpang tindih.
    final docRef = _db.collection('pengajuan').doc(idPengajuan);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw const OperasiDitolakException(
          'Pengajuan tidak ditemukan atau sudah dibatalkan.');
    }
    pastikanBolehDiubah(data: snap.data()!, uidAktif: uid, aksi: 'diubah');
    await _pastikanTidakTumpangTindih(
      uid: uid,
      mulai: mulai,
      selesai: selesai,
      abaikanIdPengajuan: idPengajuan, // jangan tumpuk dengan diri sendiri
    );
    // update() — BUKAN set(): hanya field yang disebut yang berubah, sehingga
    // field audit dibuatPada, idPengguna, dan status tetap utuh.
    await docRef.update({
      'jenis': jenis,
      'mulai': kunciHari(mulai),
      'selesai': kunciHari(selesai),
      'alasan': alasan,
      'lampiran': _petaLampiran(lampiran),
      'diubahPada': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> batalkanPengajuan(String idPengajuan, String uid) async {
    final docRef = _db.collection('pengajuan').doc(idPengajuan);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw const OperasiDitolakException(
          'Pengajuan tidak ditemukan atau sudah dibatalkan.');
    }
    pastikanBolehDiubah(data: snap.data()!, uidAktif: uid, aksi: 'dibatalkan');
    await docRef.delete();
  }

  @override
  Future<void> putuskanPengajuan({
    required String idPengajuan,
    required bool setujui,
    required String diprosesOleh,
    String? alasanPenolakan,
  }) async {
    await _db.collection('pengajuan').doc(idPengajuan).update({
      'status': setujui ? 'disetujui' : 'ditolak',
      'diprosesOleh': diprosesOleh,
      'alasanPenolakan': setujui ? null : alasanPenolakan,
    });
  }
}

// ═══════════════════════════════════════════════════════════════
// IMPLEMENTASI MEMORI (widget test / fallback tanpa Firebase)
// ═══════════════════════════════════════════════════════════════

class LayananMemori implements LayananTipsen {
  final List<Presensi> _presensi = [];
  final Map<String, StreamController<List<Presensi>>> _saluranPresensi = {};

  void _umumkanPresensi(String uid) {
    final c = _saluranPresensi[uid];
    if (c == null || c.isClosed) return;
    final daftar = _presensi
        .where((p) => p.id.startsWith('${uid}_'))
        .toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    c.add(List.of(daftar));
  }

  @override
  Future<void> simpanPengguna({
    required String uid,
    required String email,
    String? namaLengkap,
    required String peran,
  }) async {
    // Mode memori tidak menyimpan profil — cukup tidak melakukannya.
  }

  @override
  Future<Map<String, dynamic>?> bacaPengguna(String uid) async => null;

  @override
  Future<void> isiLokasiAwalJikaKosong() async {}

  @override
  Stream<List<LokasiKantor>> streamLokasi() =>
      Stream.value(List.of(daftarLokasiAwal));

  @override
  Future<void> tambahPresensi(Presensi catatan, String uid) async {
    final docId = idDokumenPresensi(uid, catatan.tanggal);
    final sudahAda = _presensi.any((p) => p.id == docId);
    if (sudahAda) {
      throw AturanBisnisException(
          'Anda sudah melakukan presensi hari ini. Clock Out untuk menutup sesi.');
    }
    _presensi.add(catatan);
    _umumkanPresensi(uid);
  }

  @override
  Future<void> simpanClockOut(String idDokumen, String jamPulang) async {
    final i = _presensi.indexWhere((p) => p.id == idDokumen);
    if (i < 0) return;
    _presensi[i] = _presensi[i].copyWith(clockOut: jamPulang);
    final uid = _presensi[i].id.split('_').first;
    _umumkanPresensi(uid);
  }

  @override
  Stream<List<Presensi>> streamPresensiSaya(String uid) {
    final c = _saluranPresensi.putIfAbsent(
        uid, () => StreamController<List<Presensi>>.broadcast());
    scheduleMicrotask(() => _umumkanPresensi(uid));
    return c.stream;
  }

  // ── pengajuan (implementasi memori) ──────────────────────────
  final List<PengajuanIzin> _pengajuan = [];
  final Map<String, String> _pemilikPengajuan = {}; // docId → uid pemilik
  int _seqPengajuan = 1;
  final Map<String, StreamController<List<PengajuanIzin>>> _saluranPengajuan =
      {};

  void _umumkanPengajuan(String kunci) {
    final c = _saluranPengajuan[kunci];
    if (c == null || c.isClosed) return;
    final daftar = kunci == 'semua'
        ? [..._pengajuan]
        : [
            for (final p in _pengajuan)
              if (_pemilikPengajuan[p.id] == kunci) p,
          ];
    daftar.sort((a, b) {
      final x = a.diajukanPada ?? a.tanggalMulai;
      final y = b.diajukanPada ?? b.tanggalMulai;
      return y.compareTo(x);
    });
    c.add(List.of(daftar));
  }

  void _umumkanSemuaPengajuan() {
    _umumkanPengajuan('semua');
    for (final uid in _pemilikPengajuan.values.toSet()) {
      _umumkanPengajuan(uid);
    }
  }

  /// Analogi `_pastikanTidakTumpangTindih` versi memori — aturan bisnis
  /// yang sama, data dari daftar lokal (dipakai widget test).
  void _pastikanTidakTumpangTindihMemori({
    required String uid,
    required DateTime mulai,
    required DateTime selesai,
    String? abaikanIdPengajuan,
  }) {
    for (final p in _pengajuan) {
      if (p.id == abaikanIdPengajuan) continue;
      if (_pemilikPengajuan[p.id] != uid) continue;
      if (p.status == StatusPengajuan.ditolak) continue;
      final tumpang = !selesai.isBefore(p.tanggalMulai) &&
          !mulai.isAfter(p.tanggalSelesai);
      if (tumpang) {
        throw OperasiDitolakException(
            'Sudah ada pengajuan ${p.jenis} pada periode yang bertumpuk. '
            'Ubah periode atau batalkan pengajuan lama terlebih dahulu.');
      }
    }
  }

  @override
  Stream<List<PengajuanIzin>> streamPengajuanTampil(
    String uid, {
    required bool sebagaiHC,
  }) {
    final kunci = sebagaiHC ? 'semua' : uid;
    final c = _saluranPengajuan.putIfAbsent(
        kunci, () => StreamController<List<PengajuanIzin>>.broadcast());
    scheduleMicrotask(() => _umumkanPengajuan(kunci));
    return c.stream;
  }

  @override
  Future<PengajuanIzin> tambahPengajuan(PengajuanIzin p, String uid) async {
    _pastikanTidakTumpangTindihMemori(
        uid: uid, mulai: p.tanggalMulai, selesai: p.tanggalSelesai);
    final tersimpan = PengajuanIzin(
      id: 'PZ-${_seqPengajuan++}',
      jenis: p.jenis,
      tanggalMulai: p.tanggalMulai,
      tanggalSelesai: p.tanggalSelesai,
      alasan: p.alasan,
      status: p.status,
      lampiran: p.lampiran,
      namaPemohon: p.namaPemohon,
      jabatanPemohon: p.jabatanPemohon,
      diajukanPada: p.diajukanPada,
    );
    _pengajuan.add(tersimpan);
    _pemilikPengajuan[tersimpan.id] = uid;
    _umumkanSemuaPengajuan();
    return tersimpan;
  }

  @override
  Future<void> ubahPengajuan({
    required String idPengajuan,
    required String uid,
    required String jenis,
    required DateTime mulai,
    required DateTime selesai,
    required String alasan,
    Lampiran? lampiran,
  }) async {
    final i = _pengajuan.indexWhere((p) => p.id == idPengajuan);
    if (i < 0) {
      throw const OperasiDitolakException(
          'Pengajuan tidak ditemukan atau sudah dibatalkan.');
    }
    pastikanBolehDiubah(
      data: {
        'idPengguna': _pemilikPengajuan[idPengajuan],
        'status': _pengajuan[i].status.kode,
      },
      uidAktif: uid,
      aksi: 'diubah',
    );
    _pastikanTidakTumpangTindihMemori(
      uid: uid,
      mulai: mulai,
      selesai: selesai,
      abaikanIdPengajuan: idPengajuan, // jangan tumpuk dengan diri sendiri
    );
    _pengajuan[i] = _pengajuan[i].copyWith(
      jenis: jenis,
      tanggalMulai: mulai,
      tanggalSelesai: selesai,
      alasan: alasan,
      lampiran: lampiran,
      diubahPada: DateTime.now(),
    );
    _umumkanSemuaPengajuan();
  }

  @override
  Future<void> batalkanPengajuan(String idPengajuan, String uid) async {
    final i = _pengajuan.indexWhere((p) => p.id == idPengajuan);
    if (i < 0) {
      throw const OperasiDitolakException(
          'Pengajuan tidak ditemukan atau sudah dibatalkan.');
    }
    pastikanBolehDiubah(
      data: {
        'idPengguna': _pemilikPengajuan[idPengajuan],
        'status': _pengajuan[i].status.kode,
      },
      uidAktif: uid,
      aksi: 'dibatalkan',
    );
    _pengajuan.removeAt(i);
    _pemilikPengajuan.remove(idPengajuan);
    _umumkanSemuaPengajuan();
  }

  @override
  Future<void> putuskanPengajuan({
    required String idPengajuan,
    required bool setujui,
    required String diprosesOleh,
    String? alasanPenolakan,
  }) async {
    final i = _pengajuan.indexWhere((p) => p.id == idPengajuan);
    if (i < 0) return;
    _pengajuan[i] = _pengajuan[i].copyWith(
      status: setujui ? StatusPengajuan.disetujui : StatusPengajuan.ditolak,
      diprosesOleh: diprosesOleh,
      alasanPenolakan: setujui ? null : alasanPenolakan,
    );
    _umumkanSemuaPengajuan();
  }
}
