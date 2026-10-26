import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import 'beranda_screen.dart';
import 'presensi_screen.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';

/// Filter riwayat yang bisa diaktifkan dari Beranda.
enum RiwayatFilter { semua, hadir, izin }

/// Shell utama aplikasi karyawan: 4 tab (Beranda | Presensi | Riwayat | Profil).
///
/// Tata letak:
/// • Layar sempit (< 800 px) → full-width, seperti aplikasi ponsel biasa.
/// • Layar lebar (Chrome)    → frame "ponsel" terpusat; nav berada DI DALAM
///   frame supaya proporsinya selalu benar dan tidak pernah kolaps.
///
/// Catatan penting: navigasi bawah tidak lagi dipasang pada slot
/// `Scaffold.bottomNavigationBar`, karena `Center` di dalam slot tersebut
/// memuai memenuhi tinggi layar dan membuat area konten menjadi 0 px.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  RiwayatFilter _filterRiwayat = RiwayatFilter.semua;

  @override
  void initState() {
    super.initState();
    // Toast selamat datang ditampilkan setelah frame pertama supaya bisa
    // dirender oleh messenger di dalam frame (bukan oleh Scaffold terluar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showToast(context, 'Login berhasil. Selamat datang, Anisa!',
          ToastKind.success);
    });
  }

  // Dipanggil dari Beranda (avatar, kartu statistik, menu cepat).
  void bukaTab(int index) => setState(() => _index = index);

  void bukaRiwayat(RiwayatFilter filter) => setState(() {
        _filterRiwayat = filter;
        _index = 2;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sempit = constraints.maxWidth < 800;

          final isi = IndexedStack(
            index: _index,
            children: [
              BerandaScreen(
                onBukaProfil: () => bukaTab(3),
                onBukaRiwayat: bukaRiwayat,
                onBukaPresensi: () => bukaTab(1),
              ),
              const PresensiScreen(),
              RiwayatScreen(
                key: ValueKey(_filterRiwayat),
                filterAwal: _filterRiwayat,
              ),
              const ProfilScreen(),
            ],
          );

          // ScaffoldMessenger + Scaffold lokal di dalam frame:
          // • Scaffold terluar ShellScreen selebar jendela browser, sehingga
          //   snackbar dirender di dasar halaman dan MENUTUPI navigasi bawah.
          // • Dengan messenger + Scaffold sendiri di dalam frame, toast muncul
          //   di dalam "ponsel", tepat di atas navigasi.
          final isiBerToast = ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: T.canvas,
              body: isi,
            ),
          );

          final nav = _TipsenNavBar(selectedIndex: _index, onPilih: bukaTab);

          if (sempit) {
            return Column(
              children: [
                Expanded(child: isiBerToast),
                nav,
              ],
            );
          }

          // Layar lebar: frame ponsel terpusat, nav ikut di dalam frame.
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE7EEF9), Color(0xFFF7FAFE), Color(0xFFE6EDF8)],
              ),
            ),
            child: Center(
              child: Container(
                width: 520,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: T.canvas,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFDDE5F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B2A46).withValues(alpha: 0.12),
                      blurRadius: 44,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Expanded(child: isiBerToast),
                    nav,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Navigasi bawah 4 tab. Selalu shrink-wrap (tidak pernah memuai).
class _TipsenNavBar extends StatelessWidget {
  const _TipsenNavBar({required this.selectedIndex, required this.onPilih});

  final int selectedIndex;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Beranda'),
      (Icons.fingerprint_rounded, 'Presensi'),
      (Icons.history_rounded, 'Riwayat'),
      (Icons.person_rounded, 'Profil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7ECF3))),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 66,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: selectedIndex,
          onDestinationSelected: onPilih,
          destinations: [
            for (final (icon, label) in items)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(icon, fill: 1),
                label: label,
                // Tooltip bawaan Material muncul saat kursor berhenti di nav
                // dan menutupi label; untuk aplikasi web tidak diperlukan.
                tooltip: '',
              ),
          ],
        ),
      ),
    );
  }
}
