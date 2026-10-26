import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../state/app_state.dart';
import 'admin_approval_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_monitoring_screen.dart';
import 'admin_profil_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_tracking_screen.dart';

/// Portal HC (web admin): topbar gelap + sidebar 7 menu.
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
    (Icons.manage_accounts_rounded, 'Profil & Pengaturan'),
  ];

  void _pindah(int i) => setState(() => _menu = i);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showToast(context, 'Masuk sebagai HC Admin. Selamat bekerja, Bambang!',
          ToastKind.success);
    });
  }

  Future<void> _konfirmasiKeluar() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
        title: const Text('Keluar dari Portal HC?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'Anda akan kembali ke halaman login TIPSEN.',
          style: TextStyle(fontSize: 13, color: T.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal',
                style: TextStyle(fontSize: 13, color: T.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: T.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(T.rSm)),
            ),
            child: const Text('Keluar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (keluar == true && mounted) {
      context.read<AppState>().keluar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.of(context).size.width;
    final sempit = lebar < 940;

    final isi = IndexedStack(
      index: _menu,
      children: [
        AdminDashboardScreen(onPindahMenu: _pindah),
        const AdminMonitoringScreen(),
        const AdminTrackingScreen(),
        const AdminApprovalScreen(),
        const AdminEmployeesScreen(),
        const AdminReportsScreen(),
        const AdminProfilScreen(),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: T.canvas,
      drawer: sempit
          ? Drawer(
              width: 268,
              backgroundColor: T.card,
              child: SafeArea(
                child: _Sidebar(
                  menuAktif: _menu,
                  items: _menuAdmin,
                  onPilih: (i) {
                    _pindah(i);
                    Navigator.of(context).pop();
                  },
                  onKeluar: _konfirmasiKeluar,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          _TopBar(
            sempit: sempit,
            onMenu: () => _scaffoldKey.currentState?.openDrawer(),
            onProfil: () => _pindah(6),
            onKeluar: _konfirmasiKeluar,
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
                      onPilih: _pindah,
                      onKeluar: _konfirmasiKeluar,
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border:
                          Border(left: BorderSide(color: Color(0xFFDFE5ED))),
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
  const _TopBar({
    required this.sempit,
    required this.onMenu,
    required this.onProfil,
    required this.onKeluar,
  });

  final bool sempit;
  final VoidCallback onMenu;
  final VoidCallback onProfil;
  final VoidCallback onKeluar;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AppState>().adminHC;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: T.navyTopbar,
      child: Row(
        children: [
          if (sempit)
            IconButton(
              onPressed: onMenu,
              tooltip: 'Buka menu',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(admin.jabatan,
                    style: const TextStyle(
                        fontSize: 10.5, color: Color(0xFF96A2B5))),
                const SizedBox(height: 2),
                Text(admin.nama,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ],
            ),
            const SizedBox(width: 10),
          ],
          PopupMenuButton<String>(
            tooltip: 'Menu akun',
            offset: const Offset(0, 44),
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(T.rMd)),
            onSelected: (v) {
              if (v == 'profil') {
                onProfil();
              } else if (v == 'keluar') {
                onKeluar();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'profil',
                child: Text('Profil & Pengaturan',
                    style: TextStyle(fontSize: 13, color: T.text)),
              ),
              PopupMenuItem(
                value: 'keluar',
                child: Text('Keluar',
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
              child: Text(admin.inisial,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
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
    required this.onKeluar,
  });

  final int menuAktif;
  final List<(IconData, String)> items;
  final ValueChanged<int> onPilih;
  final VoidCallback onKeluar;

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
                        if (i == 3 && app.totalMenungguPersetujuan > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: T.amberBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: T.amberBorder),
                            ),
                            child: Text('${app.totalMenungguPersetujuan}',
                                style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: T.amber)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: T.greenBg,
              borderRadius: BorderRadius.circular(T.rMd),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 9, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sistem Online',
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: T.green)),
                      const SizedBox(height: 2),
                      Text('${app.totalKaryawan} karyawan aktif',
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF6C8C7D))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: onKeluar,
              icon: const Icon(Icons.logout_rounded, size: 16, color: T.red),
              label: const Text('Keluar',
                  style: TextStyle(fontSize: 11.5, color: T.red)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
