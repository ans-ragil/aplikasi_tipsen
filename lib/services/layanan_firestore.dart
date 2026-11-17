/// Layanan data TIPSEN — Cloud Firestore (Minggu 10).
///
/// Pemetaan ERD proyek menjadi TIGA collection dengan operasi Create & Read:
///
/// | Collection          | Isi                                   | Operasi |
/// |---------------------|----------------------------------------|---------|
/// | `users/{uid}`       | Profil pengguna                        | Create saat daftar/masuk, Read |
/// | `lokasi/{kode}`     | Master lokasi kantor (auto-seed)       | Read real-time |
/// | `presensi/{uid_tgl}`| Catatan kehadiran per hari             | Create (Clock In), Read real-time |
///
/// Clock Out memperbarui `clockOut` pada dokumen hari yang sama — satu-
/// satunya penulisan di luar Create, karena alur presensi TIPSEN menuntut
/// jam pulang pada catatan yang sama (materi Update disentuh awal di sini,
/// diperdalam pada Minggu 11).
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
}
