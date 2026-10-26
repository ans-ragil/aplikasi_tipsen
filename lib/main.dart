import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(const TipsenApp());
}

/// Aplikasi TIPSEN — presensi online karyawan.
class TipsenApp extends StatelessWidget {
  const TipsenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'TIPSEN — Presensi Online',
        debugShowCheckedModeBanner: false,
        theme: buildTipsenTheme(),
        home: const _GerbangSesi(),
      ),
    );
  }
}

/// Menentukan layar berdasarkan status sesi: Login atau aplikasi utama.
class _GerbangSesi extends StatelessWidget {
  const _GerbangSesi();

  @override
  Widget build(BuildContext context) {
    final sesi = context.watch<AppState>().sesi;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: sesi == SesiStatus.belumLogin
          ? const LoginScreen(key: ValueKey('login'))
          : const ShellScreen(key: ValueKey('shell')),
    );
  }
}
