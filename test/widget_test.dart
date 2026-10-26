// Uji asap (smoke test) aplikasi TIPSEN:
// memastikan halaman Login tampil saat aplikasi pertama dibuka.

import 'package:flutter_test/flutter_test.dart';

import 'package:aplikasi_tipsen/main.dart';

void main() {
  testWidgets('Halaman Login tampil saat aplikasi dibuka',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TipsenApp());
    await tester.pump();

    expect(find.text('TIPSEN'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
    expect(find.text('Email Karyawan'), findsOneWidget);
  });

  testWidgets('Validasi email kosong menampilkan pesan kesalahan',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TipsenApp());
    await tester.pump();

    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pump();

    expect(find.text('Email karyawan wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
  });
}
