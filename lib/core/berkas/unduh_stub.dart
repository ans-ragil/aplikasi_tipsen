/// Implementasi unduhan untuk platform non-web (tidak dipakai pada build web).
Future<void> unduhBerkas(String nama, List<int> bytes, String mime) async {
  throw UnsupportedError('Unduh berkas hanya tersedia pada versi web TIPSEN.');
}

/// Cetak / simpan sebagai PDF (tidak tersedia di luar web).
void cetakHalaman() {
  throw UnsupportedError('Cetak hanya tersedia pada versi web TIPSEN.');
}
