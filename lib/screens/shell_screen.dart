import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'beranda_screen.dart';
import 'presensi_screen.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';

/// Filter riwayat yang bisa diaktifkan dari Beranda.
enum RiwayatFilter { semua, hadir, izin }

/// Shell utama aplikasi karyawan: 4 tab (Beranda | Presensi | Riwayat | Profil)
/// dengan bottom navigation. Di layar lebar (Chrome), konten dan nav ditampilkan
/// dalam frame terpusat — meniru mockup Figma; di layar sempit full-width.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  RiwayatFilter _filterRiwayat = RiwayatFilter.semua;

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
          Widget konten = IndexedStack(
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

          if (!sempit) {
            // Frame "ponsel" terpusat di Chrome — seperti mockup Figma.
            konten = Center(
              child: Container(
                width: 560,
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: T.canvas,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(T.rXl)),
                ),
                child: konten,
              ),
            );
          }
          return konten;
        },
      ),
      bottomNavigationBar: _TipsenNavBar(
        selectedIndex: _index,
        onPilih: bukaTab,
      ),
    );
  }
}

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

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lebar = constraints.maxWidth;
          final lebarNav = lebar >= 800 ? 460.0 : lebar;
          final melayang = lebar >= 800;

          final bar = NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onPilih,
            destinations: [
              for (final (icon, label) in items)
                NavigationDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(icon, fill: 1),
                  label: label,
                ),
            ],
          );

          if (!melayang) return bar;

          // Di Chrome/layar lebar: nav melayang membulat di bawah frame.
          return Center(
            child: Container(
              width: lebarNav,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(T.rXl),
                border: Border.all(color: T.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(T.rXl),
                child: bar,
              ),
            ),
          );
        },
      ),
    );
  }
}
