import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'beranda_screen.dart';
import 'presensi_screen.dart';
import 'profil_screen.dart';
import 'riwayat_screen.dart';

/// Filter riwayat yang bisa diaktifkan dari Beranda.
enum RiwayatFilter { semua, hadir, izin }

/// Shell aplikasi karyawan.
///
/// Versi web (≥ 1000 px): topbar navy + sidebar menu + area konten selebar
/// maksimal 1180 px — pola yang sama dengan portal HC, bukan lagi bingkai
/// ponsel di tengah layar.
///
/// Versi sempit (< 1000 px): topbar + drawer menu + navigasi bawah, sehingga
/// aplikasi tetap nyaman dipakai di ponsel.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;
  RiwayatFilter _filterRiwayat = RiwayatFilter.semua;
  final GlobalKey<ScaffoldState> _kunciScaffold = GlobalKey<ScaffoldState>();

  static const _menu = <(IconData, String)>[
    (Icons.home_rounded, 'Beranda'),
    (Icons.fingerprint_rounded, 'Presensi'),
    (Icons.history_rounded, 'Riwayat'),
    (Icons.person_rounded, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nama = context.read<AppState>().pengguna.nama.split(' ').first;
      showToast(context, 'Login berhasil. Selamat datang, $nama!',
          ToastKind.success);
    });
  }

  // Dipanggil dari Beranda (avatar, kartu statistik, menu cepat).
  void bukaTab(int index) => setState(() => _index = index);

  void bukaRiwayat(RiwayatFilter filter) => setState(() {
        _filterRiwayat = filter;
        _index = 2;
      });

  void _keluar() {
    context.read<AppState>().keluar();
  }

  Future<void> _konfirmasiKeluar() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
        title: const Text('Keluar Akun?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text(
          'Anda perlu masuk kembali untuk melakukan presensi.',
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
    if (keluar == true && mounted) _keluar();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final web = c.maxWidth >= 1000;

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

        return Scaffold(
          key: _kunciScaffold,
          backgroundColor: T.canvas,
          drawer: web
              ? null
              : Drawer(
                  width: 264,
                  backgroundColor: T.card,
                  child: SafeArea(
                    child: _Sidebar(
                      menuAktif: _index,
                      items: _menu,
                      onPilih: (i) {
                        bukaTab(i);
                        Navigator.of(context).pop();
                      },
                      onBantuan: _konfirmasiKeluar,
                    ),
                  ),
                ),
          bottomNavigationBar:
              web ? null : _TipsenNavBar(selectedIndex: _index, onPilih: bukaTab),
          body: Column(
            children: [
              _TopBar(
                web: web,
                onMenu: () => _kunciScaffold.currentState?.openDrawer(),
                onProfil: () => bukaTab(3),
                onKeluar: _konfirmasiKeluar,
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (web)
                      Container(
                        width: 244,
                        color: T.card,
                        child: _Sidebar(
                          menuAktif: _index,
                          items: _menu,
                          onPilih: bukaTab,
                          onBantuan: _konfirmasiKeluar,
                        ),
                      ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                              left: BorderSide(color: Color(0xFFDFE5ED))),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: isi,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOPBAR
// ═══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.web,
    required this.onMenu,
    required this.onProfil,
    required this.onKeluar,
  });

  final bool web;
  final VoidCallback onMenu;
  final VoidCallback onProfil;
  final VoidCallback onKeluar;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: web ? 20 : 10),
      color: T.navyTopbar,
      child: Row(
        children: [
          if (!web)
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
              Text('Employee Portal',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8F9CB1))),
            ],
          ),
          const Spacer(),
          // Jam berjalan sengaja tidak ditampilkan di sini: satu-satunya jam
          // aplikasi ada di kartu hero Beranda, supaya tidak dobel.
          InkWell(
            onTap: onProfil,
            borderRadius: BorderRadius.circular(T.rMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: [
                  AvatarFoto(
                    inisial: user.inisial,
                    foto: app.fotoProfil,
                    size: 34,
                    bg: Colors.white.withValues(alpha: 0.14),
                    fg: Colors.white,
                    borderColor: Colors.white.withValues(alpha: 0.55),
                    borderWidth: 1.5,
                  ),
                  if (web) ...[
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(user.nama.split(' ').take(2).join(' '),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text(user.jabatan,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF8F9CB1))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onKeluar,
            tooltip: 'Keluar akun',
            icon: const Icon(Icons.logout_rounded,
                size: 19, color: Color(0xFFB9C4D6)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.menuAktif,
    required this.items,
    required this.onPilih,
    required this.onBantuan,
  });

  final int menuAktif;
  final List<(IconData, String)> items;
  final ValueChanged<int> onPilih;
  final VoidCallback onBantuan;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final hariIni = app.presensiHariIni;

    final (statusTeks, warna) = switch (app.langkah) {
      LangkahPresensi.belumClockIn => ('Belum presensi', T.amber),
      LangkahPresensi.sudahClockIn => ('Sudah Clock In', T.green),
      LangkahPresensi.sudahClockOut => ('Presensi selesai', T.green),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 20, 18, 10),
          child: Text('MENU',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: T.textMuted)),
        ),
        for (var i = 0; i < items.length; i++)
          _ItemSidebar(
            ikon: items[i].$1,
            label: items[i].$2,
            aktif: i == menuAktif,
            onTap: () => onPilih(i),
          ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: T.canvas,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STATUS HARI INI',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: T.textMuted)),
              const SizedBox(height: 7),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: warna),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(statusTeks,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                hariIni == null
                    ? 'Belum ada catatan'
                    : '${hariIni.clockIn ?? '—'} – ${hariIni.clockOut ?? '—'}',
                style: const TextStyle(fontSize: 10.5, color: T.textMuted),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: OutlinedButton.icon(
            onPressed: onBantuan,
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Keluar Akun'),
            style: OutlinedButton.styleFrom(
              foregroundColor: T.textSecondary,
              side: const BorderSide(color: T.border),
              minimumSize: const Size(0, 40),
              textStyle: const TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(T.rSm)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemSidebar extends StatelessWidget {
  const _ItemSidebar({
    required this.ikon,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final IconData ikon;
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: aktif ? T.blueBg : Colors.transparent,
        borderRadius: BorderRadius.circular(T.rSm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(T.rSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rSm),
              border: Border.all(
                  color: aktif ? T.blueBorder : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(ikon, size: 18, color: aktif ? T.accent : T.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: aktif ? FontWeight.w800 : FontWeight.w600,
                      color: aktif ? T.accent : T.textSecondary,
                    ),
                  ),
                ),
                if (aktif)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: T.accent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NAVIGASI BAWAH (layar sempit)
// ═══════════════════════════════════════════════════════════════
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
                tooltip: '',
              ),
          ],
        ),
      ),
    );
  }
}
