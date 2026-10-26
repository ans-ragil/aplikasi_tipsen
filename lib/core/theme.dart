import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens TIPSEN — sumber: style guide Modul 4 + ekspor Figma Make.
/// Satu tempat untuk semua warna, radius, dan skala teks agar konsisten.
class T {
  T._();

  // ── Warna utama ──────────────────────────────────────────────
  static const Color navy = Color(0xFF263858); // primer (modul 4)
  static const Color navyDark = Color(0xFF1A2740); // ujung gradien hero
  static const Color navyTopbar = Color(0xFF111A2C); // topbar web admin (fase admin)
  static const Color accent = Color(0xFF2859A5); // tautan / aksen sekunder
  static const Color canvas = Color(0xFFF4F7FB); // latar halaman
  static const Color card = Colors.white;

  // ── Teks & garis ─────────────────────────────────────────────
  static const Color text = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF8994A5);
  static const Color border = Color(0xFFDCE3ED);
  static const Color fieldBorder = Color(0xFFD6DEEA);

  // ── Status (selalu dipakai bersama teks, bukan warna saja) ───
  static const Color green = Color(0xFF087A55);
  static const Color greenBg = Color(0xFFF2FBF7);
  static const Color greenBorder = Color(0xFFC9EEDC);
  static const Color amber = Color(0xFF9A5B06);
  static const Color amberBg = Color(0xFFFFF7E1);
  static const Color amberBorder = Color(0xFFF0D99E);
  static const Color red = Color(0xFFC31840);
  static const Color redBg = Color(0xFFFFF0F3);
  static const Color redBorder = Color(0xFFF0C0CC);
  static const Color blue = Color(0xFF1D4ED8);
  static const Color blueBg = Color(0xFFEDF3FF);
  static const Color blueBorder = Color(0xFFCADBFD);

  // ── Radius & jarak ───────────────────────────────────────────
  static const double rSm = 8;
  static const double rMd = 10;
  static const double rLg = 14;
  static const double rXl = 18;
  static const double buttonHeight = 48; // aturan modul: min 48 px
  static const double margin = 16;

  // ── Gradien hero Beranda ─────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E4468), navy, navyDark],
  );
}

/// Tema aplikasi TIPSEN.
ThemeData buildTipsenTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: T.navy,
      primary: T.navy,
      secondary: T.accent,
      surface: T.card,
      error: T.red,
    ),
    scaffoldBackgroundColor: T.canvas,
  );

  return base.copyWith(
    textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
      // Judul 24 / Subjudul 18 / Isi 14-16 / Keterangan 12 (style guide modul 4)
      displaySmall: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: T.text),
      headlineMedium: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: T.text),
      titleLarge: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700, color: T.text),
      bodyLarge: const TextStyle(
          fontSize: 15, height: 1.5, color: T.text),
      bodyMedium: const TextStyle(
          fontSize: 14, height: 1.5, color: T.text),
      bodySmall: const TextStyle(
          fontSize: 12, height: 1.45, color: T.textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: T.card,
      hintStyle: const TextStyle(color: T.textMuted, fontSize: 14),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: const BorderSide(color: T.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: const BorderSide(color: T.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: const BorderSide(color: T.accent, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: const BorderSide(color: T.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: const BorderSide(color: T.red, width: 1.6),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: T.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(T.rMd),
          borderSide: const BorderSide(color: T.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(T.rMd),
          borderSide: const BorderSide(color: T.fieldBorder),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: T.navy,
      contentTextStyle: TextStyle(
          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: T.blueBg,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? T.navy : T.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          color: active ? T.navy : T.textMuted,
          size: 24,
        );
      }),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: T.canvas,
      foregroundColor: T.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: T.text),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEDF0F5), thickness: 1),
  );
}
