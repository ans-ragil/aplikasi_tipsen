import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

/// Hasil pemilihan foto profil.
class HasilPilihFoto {
  /// Pengguna menutup dialog pemilih berkas.
  const HasilPilihFoto.batal() : bytes = null, pesan = null;

  /// Berkas terpilih tetapi tidak bisa diolah.
  const HasilPilihFoto.gagal(String p) : bytes = null, pesan = p;

  /// Berhasil dikompres dan siap disimpan.
  const HasilPilihFoto.sukses(Uint8List b) : bytes = b, pesan = null;

  final Uint8List? bytes;
  final String? pesan;
}

/// Membuka pemilih berkas gambar, lalu memotongnya menjadi persegi dan
/// mengecilkannya menjadi 320 × 320 JPEG (±20–40 KB).
///
/// Pemotongan & kompresi dilakukan di sisi klien karena foto kamera ponsel
/// berukuran 3–8 MB — jauh melebihi kuota penyimpanan browser dan batas
/// dokumen Firestore (1 MiB) pada fase berikutnya.
Future<HasilPilihFoto> pilihFotoProfil() async {
  final PlatformFile? berkas;
  try {
    berkas = await FilePicker.pickFile(
      dialogTitle: 'Pilih foto profil',
      type: FileType.image,
    );
  } catch (_) {
    return const HasilPilihFoto.gagal('Tidak dapat membuka pemilih berkas.');
  }
  if (berkas == null) return const HasilPilihFoto.batal();

  final mentah = await berkas.readAsBytes();
  if (mentah.isEmpty) {
    return const HasilPilihFoto.gagal('Berkas foto kosong atau tidak terbaca.');
  }

  final kecil = _kompres(mentah);
  if (kecil == null) {
    return const HasilPilihFoto.gagal(
        'Format gambar tidak dikenali. Gunakan JPG, PNG, atau WEBP.');
  }
  return HasilPilihFoto.sukses(kecil);
}

Uint8List? _kompres(Uint8List mentah) {
  final asli = img.decodeImage(mentah);
  if (asli == null) return null;

  // Foto ponsel sering menyimpan rotasi di EXIF; tanpa ini avatar bisa
  // tampil miring 90°.
  final tegak = img.bakeOrientation(asli);

  final sisi = tegak.width < tegak.height ? tegak.width : tegak.height;
  final potong = img.copyCrop(
    tegak,
    x: (tegak.width - sisi) ~/ 2,
    y: (tegak.height - sisi) ~/ 2,
    width: sisi,
    height: sisi,
  );
  final kecil = img.copyResize(
    potong,
    width: 320,
    height: 320,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(kecil, quality: 84));
}
