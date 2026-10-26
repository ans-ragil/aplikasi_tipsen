import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import 'admin_approval_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_monitoring_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_tracking_screen.dart';

/// Halaman web admin (HC Portal): topbar gelap + sidebar 6 menu.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _menu = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _menuAdmin = [
    (Icons.dashboard_rounded, 'Dashboard Admin'),
    (Icons.bar_chart_rounded, 'Monitoring Presensi'),
    (Icons.my_location_rounded, 'Live Tracking & Geofence'),
    (Icons.event_available_rounded, 'Persetujuan Cuti & Izin'),
    (Icons.groups_rounded, 'Manajemen Karyawan'),
    (Icons.description_rounded, 'Laporan & Ekspor Data'),
  ];

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.of(context).size.width;
    final sempit = lebar < 940;

    final isi = IndexedStack(
      index: _menu,
      children: [
        AdminDashboardScreen(
          onPindahMenu: (i) => setState(() => _menu = i),
        ),
        const AdminMonitoringScreen(),
        const AdminTrackingScreen(),
        const AdminApprovalScreen(),
        const AdminEmployeesScreen(),
        const AdminReportsScreen(),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: T.canvas,
      drawer: sempit
          ? Drawer(
              width: 260,
              backgroundColor: T.card,
              child: SafeArea(child: _Sidebar(
                menuAktif: _menu,
                items: _menuAdmin,
                onPilih: (i) {
                  setState(() => _menu = i);
                  Navigator.of(context).pop();
                },
              )),
            )
          : null,
      body: Column(
        children: [
          _TopBar(
            sempit: sempit,
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!sempit)
                  Container(
                    width: 252,
                    color: T.card,
                    child: _Sidebar(
                      menuAktif: _menu,
                      items: _menuAdmin,
                      onPilih: (i) => setState(() => _menu = i),
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          left: BorderSide(color: Color(0xFFDFE5ED))),
                    ),
                    child: isi,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  const _TopBar({required this.sempit, required this.onMenu});

  final bool sempit;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: T.navyTopbar,
      child: Row(
        children: [
          if (sempit)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
            ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(T.rSm),
            ),
            alignment: Alignment.center,
            child: const Text('T',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: T.navy)),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TIPSEN',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: Colors.white)),
              Text('HC Portal',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8F9CB1))),
            ],
          ),
          const Spacer(),
          if (!sempit) ...[
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('HC Head',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF96A2B5))),
                SizedBox(height: 2),
                Text('Bambang Santoso',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(width: 10),
            PopupMenuButton<String>(
              tooltip: 'Menu akun',
              offset: const Offset(0, 44),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(T.rMd)),
              onSelected: (v) {
                if (v == 'profil') {
                  _tampilkanProfil(context);
                } else if (v == 'keluar') {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'profil',
                  child: Text('Profil Saya',
                      style: TextStyle(fontSize: 13, color: T.text)),
                ),
                PopupMenuItem(
                  value: 'keluar',
                  child: Text('Kembali ke Aplikasi Karyawan',
                      style: TextStyle(fontSize: 13, color: T.red)),
                ),
              ],
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: T.navy,
                  border: Border.all(color: const Color(0xFF5574AD), width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('BS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _tampilkanProfil(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(T.rLg)),
        title: const Text('Profil Saya',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BarisInfo(label: 'Nama Lengkap', nilai: 'Bambang Santoso'),
            _BarisInfo(label: 'Jabatan', nilai: 'HC Head'),
            _BarisInfo(label: 'Peran Akun', nilai: 'Administrator'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: T.textSecondary)),
          const SizedBox(height: 3),
          Text(nilai,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.menuAktif,
    required this.items,
    required this.onPilih,
  });

  final int menuAktif;
  final List<(IconData, String)> items;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text('MENU UTAMA',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: T.textMuted)),
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Material(
                color: menuAktif == i ? T.blueBg : Colors.transparent,
                borderRadius: BorderRadius.circular(T.rMd),
                child: InkWell(
                  onTap: () => onPilih(i),
                  borderRadius: BorderRadius.circular(T.rMd),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(items[i].$1,
                            size: 18,
                            color: menuAktif == i ? T.accent : T.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            items[i].$2,
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: menuAktif == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color:
                                  menuAktif == i ? T.accent : T.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.greenBg,
              borderRadius: BorderRadius.circular(T.rMd),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 9, color: Color(0xFF10B981)),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sistem Online',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: T.green)),
                      SizedBox(height: 2),
                      Text('Sinkronisasi 2 menit lalu',
                          style:
                              TextStyle(fontSize: 9, color: Color(0xFF6C8C7D))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${app.totalKaryawan} karyawan terdaftar',
                style:
                    const TextStyle(fontSize: 10, color: T.textMuted)),
          ),
        ],
      ),
    );
  }
}
