import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'models/models.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(const TipsenApp());
}

/// Aplikasi TIPSEN — presensi online karyawan (versi web/Chrome).
class TipsenApp extends StatelessWidget {
  const TipsenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: MaterialApp(
        title: 'TIPSEN — Presensi Online',
        debugShowCheckedModeBanner: false,
        theme: buildTipsenTheme(),
        home: const _GerbangSesi(),
      ),
    );
  }
}

/// Menentukan layar: memuat → Login → (aplikasi karyawan | portal HC).
class _GerbangSesi extends StatelessWidget {
  const _GerbangSesi();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.siap) {
      return const Scaffold(
        backgroundColor: T.canvas,
        body: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: T.navy),
          ),
        ),
      );
    }

    final Widget layar;
    if (app.sesi == SesiStatus.belumLogin) {
      layar = const LoginScreen(key: ValueKey('login'));
    } else if (app.peran == PeranAkun.adminHC) {
      layar = const AdminShell(key: ValueKey('admin'));
    } else {
      layar = const ShellScreen(key: ValueKey('shell'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: layar,
    );
  }
}
