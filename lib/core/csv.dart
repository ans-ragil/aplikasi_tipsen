import 'dart:convert';

import 'berkas/unduh.dart';

/// Utilitas CSV: menyusun isi dan mengunduhnya sebagai berkas .csv.
String keCsv(List<List<String>> baris) {
  String sel(String v) {
    final perluKutip = v.contains(',') || v.contains('"') || v.contains('\n');
    final aman = v.replaceAll('"', '""');
    return perluKutip ? '"$aman"' : aman;
  }

  return baris.map((r) => r.map(sel).join(',')).join('\r\n');
}

/// Unduh CSV (dengan BOM agar terbaca benar di Excel).
Future<void> unduhCsv(String nama, List<List<String>> baris) {
  final isi = '\uFEFF${keCsv(baris)}';
  return unduhBerkas(nama, utf8.encode(isi), 'text/csv;charset=utf-8');
}
