// Uji asap (smoke test) aplikasi TIPSEN.
//
// Menjalankan: flutter test
// Fokus: gerbang sesi (loading → Login), validasi form, dan masuk ke aplikasi
// memakai tombol "Isi otomatis" + "Masuk Sekarang".

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aplikasi_tipsen/main.dart';

/// Membuka aplikasi sampai gerbang sesi selesai memuat data awal.
/// Permukaan uji dibuat tinggi supaya seluruh halaman Login tampil tanpa
/// perlu menggulir (tombol demo & tombol masuk terlihat semua).
Future<void> bukaAplikasi(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1100, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(const TipsenApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Halaman Login tampil setelah gerbang sesi selesai',
      (WidgetTester tester) async {
    await bukaAplikasi(tester);

    expect(find.text('TIPSEN'), findsOneWidget);
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
    expect(find.text('Email Karyawan'), findsOneWidget);
    expect(find.text('Kata Sandi'), findsOneWidget);
  });

  testWidgets('Validasi email & sandi kosong menampilkan pesan kesalahan',
      (WidgetTester tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
  });

  testWidgets('Tombol "Isi otomatis" mengisi kredensial demo lalu masuk',
      (WidgetTester tester) async {
    await bukaAplikasi(tester);

    // Tombol pertama = akun karyawan.
    await tester.tap(find.text('Isi otomatis').first);
    await tester.pump();

    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Beranda karyawan tampil setelah login berhasil.
    expect(find.textContaining('Halo, Anisa'), findsOneWidget);
    expect(find.text('MENU CEPAT'), findsOneWidget);
  });
}
