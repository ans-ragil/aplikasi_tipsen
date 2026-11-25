/// Uji logika bisnis CRUD Lengkap (Minggu 11) — mengikuti 7 kasus uji di README.
///
/// Logika diuji pada [LayananMemori], yang aturan bisnisnya ditulis lewat
/// fungsi bersama yang SAMA dengan versi Firestore (`pastikanBolehDiubah`
/// dan cek tumpang tindih) — sehingga hasil uji mewakili perilaku produksi.
///
/// Yang tidak dapat diuji di sini (dilakukan manual di Chrome + Console):
/// Security Rules server-side dan dialog konfirmasi UI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_tipsen/models/models.dart';
import 'package:aplikasi_tipsen/services/layanan_firestore.dart';

LayananMemori layananBaru() => LayananMemori();

PengajuanIzin draf({
  required String jenis,
  required DateTime mulai,
  required DateTime selesai,
  String alasan = 'alasan uji',
}) =>
    PengajuanIzin(
      id: 'draf',
      jenis: jenis,
      tanggalMulai: mulai,
      tanggalSelesai: selesai,
      alasan: alasan,
      status: StatusPengajuan.menunggu,
      diajukanPada: DateTime(2026, 11, 25, 9),
    );

Future<PengajuanIzin> izinTersimpan(
  LayananMemori layanan,
  String uid, {
  String jenis = 'Izin Keperluan Pribadi',
  DateTime? mulai,
  DateTime? selesai,
}) =>
    layanan.tambahPengajuan(
      draf(
        jenis: jenis,
        mulai: mulai ?? DateTime(2026, 11, 23),
        selesai: selesai ?? DateTime(2026, 11, 26),
      ),
      uid,
    );

void main() {
  const uid = 'uid-anisa';
  const uidLain = 'uid-orang-lain';

  test('Kasus 1 — Ubah data valid: data berubah, field audit tetap utuh',
      () async {
    final layanan = layananBaru();
    final p = await izinTersimpan(layanan, uid);
    final diajukanPadaLama = p.diajukanPada;

    await layanan.ubahPengajuan(
      idPengajuan: p.id,
      uid: uid,
      jenis: p.jenis,
      mulai: p.tanggalMulai,
      selesai: p.tanggalSelesai,
      alasan: 'izin keperluan keluarga di luar kota',
    );

    final tampil = await layanan.streamPengajuanTampil(uid, sebagaiHC: false).first;
    expect(tampil, hasLength(1));
    final hasil = tampil.single;
    expect(hasil.alasan, 'izin keperluan keluarga di luar kota');
    // Field audit tetap: id, pemilik (implisit), status, diajukanPada.
    expect(hasil.status, StatusPengajuan.menunggu);
    expect(hasil.diajukanPada, diajukanPadaLama);
    // Field audit baru: diubahPada terisi.
    expect(hasil.diubahPada, isNotNull);
  });

  test('Kasus 2 — Ubah jadi periode tumpang tindih: ditolak, data lama utuh',
      () async {
    final layanan = layananBaru();
    final a = await izinTersimpan(layanan, uid); // 23–26 Nov
    final b = await izinTersimpan(
      layanan,
      uid,
      jenis: 'Cuti Tahunan',
      mulai: DateTime(2026, 11, 28),
      selesai: DateTime(2026, 11, 30),
    );

    await expectLater(
      layanan.ubahPengajuan(
        idPengajuan: b.id,
        uid: uid,
        jenis: b.jenis,
        mulai: a.tanggalMulai, // menumpuk pengajuan A
        selesai: a.tanggalSelesai,
        alasan: b.alasan,
      ),
      throwsA(isA<OperasiDitolakException>()
          .having((e) => e.pesan, 'pesan', contains('bertumpuk'))),
    );

    // Data lama B tidak berubah.
    final tampil = await layanan.streamPengajuanTampil(uid, sebagaiHC: false).first;
    final bSetelah = tampil.firstWhere((p) => p.id == b.id);
    expect(bSetelah.tanggalMulai, DateTime(2026, 11, 28));
    expect(bSetelah.tanggalSelesai, DateTime(2026, 11, 30));
    expect(bSetelah.diubahPada, isNull);
  });

  test(
      'Kasus 3 — Pengajuan sudah diputuskan HC: bisaDiubah false dan aksi ditolak',
      () async {
    final layanan = layananBaru();
    final p = await izinTersimpan(layanan, uid);
    expect(p.bisaDiubah, isTrue);

    await layanan.putuskanPengajuan(
      idPengajuan: p.id,
      setujui: true,
      diprosesOleh: 'Bambang (HC)',
    );

    final tampil = await layanan.streamPengajuanTampil(uid, sebagaiHC: false).first;
    final hasil = tampil.single;
    expect(hasil.status, StatusPengajuan.disetujui);
    expect(hasil.bisaDiubah, isFalse);

    await expectLater(
      layanan.ubahPengajuan(
        idPengajuan: p.id,
        uid: uid,
        jenis: p.jenis,
        mulai: p.tanggalMulai,
        selesai: p.tanggalSelesai,
        alasan: 'coba ubah setelah disetujui',
      ),
      throwsA(isA<OperasiDitolakException>()
          .having((e) => e.pesan, 'pesan', contains('diputuskan HC'))),
    );
    await expectLater(
      layanan.batalkanPengajuan(p.id, uid),
      throwsA(isA<OperasiDitolakException>()),
    );
  });

  test('Kasus 4 — Batalkan (setelah konfirmasi): dokumen dihapus', () async {
    final layanan = layananBaru();
    final p = await izinTersimpan(layanan, uid);

    await layanan.batalkanPengajuan(p.id, uid);

    final tampil = await layanan.streamPengajuanTampil(uid, sebagaiHC: false).first;
    expect(tampil, isEmpty);
    // Panggilan ulang pada dokumen yang sudah hilang → ditolak dengan pesan jelas.
    await expectLater(
      layanan.batalkanPengajuan(p.id, uid),
      throwsA(isA<OperasiDitolakException>()
          .having((e) => e.pesan, 'pesan', contains('tidak ditemukan'))),
    );
  });

  test('Kasus 5 — Menekan Batal pada dialog: tidak ada operasi, data tetap',
      () async {
    final layanan = layananBaru();
    final p = await izinTersimpan(layanan, uid);

    // Simulasi: pengguna menekan "Batal" pada showDialog —
    // showDialog<bool> mengembalikan null, aplikasi TIDAK memanggil layanan.
    final bool? keputusanDialog = null; // null = Batal ditekan
    if (keputusanDialog == true) await layanan.batalkanPengajuan(p.id, uid);

    final tampil = await layanan.streamPengajuanTampil(uid, sebagaiHC: false).first;
    expect(tampil, hasLength(1));
    expect(tampil.single.id, p.id);
    expect(tampil.single.status, StatusPengajuan.menunggu);
  });

  test('Kasus 6 — Aksi pada pengajuan milik akun lain: ditolak', () async {
    final layanan = layananBaru();
    final p = await izinTersimpan(layanan, uid);

    await expectLater(
      layanan.ubahPengajuan(
        idPengajuan: p.id,
        uid: uidLain,
        jenis: p.jenis,
        mulai: p.tanggalMulai,
        selesai: p.tanggalSelesai,
        alasan: 'coba ubah data orang lain',
      ),
      throwsA(isA<OperasiDitolakException>()
          .having((e) => e.pesan, 'pesan', contains('bukan pemilik'))),
    );
    await expectLater(
      layanan.batalkanPengajuan(p.id, uidLain),
      throwsA(isA<OperasiDitolakException>()
          .having((e) => e.pesan, 'pesan', contains('bukan pemilik'))),
    );
    // Data tetap aman milik pemiliknya.
    final tampil = await layanan.streamPengajuanTampil(uid, sebagaiHC: false).first;
    expect(tampil, hasLength(1));
  });

  test('Kasus 7 — Keputusan HC tersinkron ke stream karyawan (real-time)',
      () async {
    final layanan = layananBaru();
    final p = await izinTersimpan(layanan, uid);

    // Karyawan berlangganan stream miliknya; HC memutus lewat jalurnya sendiri.
    final langganan = layanan.streamPengajuanTampil(uid, sebagaiHC: false);
    final emisi = langganan.take(2).toList();

    await layanan.putuskanPengajuan(
      idPengajuan: p.id,
      setujui: false,
      diprosesOleh: 'Bambang (HC)',
      alasanPenolakan: 'Kuota cuti habis untuk bulan ini.',
    );

    final daftar = await emisi;
    final hasil = daftar.last.single;
    expect(hasil.status, StatusPengajuan.ditolak);
    expect(hasil.diprosesOleh, 'Bambang (HC)');
    expect(hasil.alasanPenolakan, 'Kuota cuti habis untuk bulan ini.');
    // HC melihat daftar semua pengajuan.
    final tampilHC = await layanan.streamPengajuanTampil(uidLain, sebagaiHC: true).first;
    expect(tampilHC, hasLength(1));
  });
}
