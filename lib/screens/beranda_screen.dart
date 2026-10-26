import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import 'pengajuan_screen.dart';
import 'shell_screen.dart';

/// Halaman Beranda.
///
/// Web (≥ 1000 px): dua kolom — hero jam & menu cepat di kiri, ringkasan
/// bulan di kanan — sehingga ruang layar lebar terpakai, bukan menumpuk
/// satu kolom memanjang.
/// Sempit: kembali menjadi satu kolom seperti aplikasi ponsel.
class BerandaScreen extends StatefulWidget {
  const BerandaScreen({
    super.key,
    required this.onBukaProfil,
    required this.onBukaRiwayat,
    required this.onBukaPresensi,
  });

  final VoidCallback onBukaProfil;
  final void Function(RiwayatFilter) onBukaRiwayat;
  final VoidCallback onBukaPresensi;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.pengguna;
    final hariIni = app.presensiHariIni;
    final bulan = DateTime(_now.year, _now.month);

    // Durasi berjalan sejak Clock In (bila belum Clock Out).
    final menitBerjalan = hariIni?.clockIn == null
        ? 0
        : (_now.hour * 60 + _now.minute) - (menitDariJam(hariIni!.clockIn) ?? 0);

    final (statusTeks, labelTombol, ikonTombol) = switch (app.langkah) {
      LangkahPresensi.belumClockIn => (
          'Anda belum melakukan presensi hari ini',
          'Clock In Sekarang',
          Icons.fingerprint_rounded
        ),
      LangkahPresensi.sudahClockIn => (
          'Masuk ${hariIni?.clockIn} · durasi berjalan '
              '${durasiLabel(menitBerjalan)}',
          'Clock Out Sekarang',
          Icons.logout_rounded
        ),
      LangkahPresensi.sudahClockOut => (
          'Masuk ${hariIni?.clockIn} · Pulang ${hariIni?.clockOut} · '
              '${hariIni?.durasi ?? '—'}',
          'Lihat Riwayat Presensi',
          Icons.history_rounded
        ),
    };

    return LayoutBuilder(
      builder: (context, c) {
        final web = c.maxWidth >= lebarWeb;

        final sapaan = _Sapaan(
          user: user,
          foto: app.fotoProfil,
          onTap: widget.onBukaProfil,
          tampilkanAvatar: !web,
        );

        final hero = _KartuHero(
          user: user,
          now: _now,
          statusTeks: statusTeks,
          labelTombol: labelTombol,
          ikonTombol: ikonTombol,
          menitBerjalan: menitBerjalan,
          tampilkanProgres: hariIni != null && hariIni.clockOut == null,
          onTap: _aksiHero,
          web: web,
        );

        final ringkasan = _RingkasanBulan(
          app: app,
          bulan: bulan,
          onBukaRiwayat: widget.onBukaRiwayat,
        );

        final menu = _MenuCepatGrid(
          web: web,
          onPresensi: widget.onBukaPresensi,
          onPengajuan: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PengajuanScreen()),
          ),
          onRiwayat: () => widget.onBukaRiwayat(RiwayatFilter.semua),
          onProfil: widget.onBukaProfil,
        );

        if (web) {
          return SingleChildScrollView(
            padding: paddingHalaman(c.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sapaan,
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: hero),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: ringkasan),
                  ],
                ),
                const SizedBox(height: 22),
                const SectionLabel('Menu Cepat'),
                const SizedBox(height: 10),
                menu,
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: SectionLabel('Aktivitas Terakhir')),
                    TextButton(
                      onPressed: () => widget.onBukaRiwayat(RiwayatFilter.semua),
                      style: TextButton.styleFrom(
                        foregroundColor: T.accent,
                        textStyle: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Lihat semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _AktivitasTerakhir(riwayat: app.riwayat),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: paddingHalaman(c.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sapaan,
              const SizedBox(height: 16),
              hero,
              const SizedBox(height: 20),
              ringkasan,
              const SizedBox(height: 20),
              const SectionLabel('Menu Cepat'),
              const SizedBox(height: 10),
              menu,
            ],
          ),
        );
      },
    );
  }

  void _aksiHero() {
    final app = context.read<AppState>();
    switch (app.langkah) {
      case LangkahPresensi.belumClockIn:
      case LangkahPresensi.sudahClockIn:
        widget.onBukaPresensi();
      case LangkahPresensi.sudahClockOut:
        widget.onBukaRiwayat(RiwayatFilter.hadir);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// SAPAAN
// ═══════════════════════════════════════════════════════════════
class _Sapaan extends StatelessWidget {
  const _Sapaan({
    required this.user,
    required this.foto,
    required this.onTap,
    required this.tampilkanAvatar,
  });

  final Karyawan user;
  final Uint8List? foto;
  final VoidCallback onTap;
  final bool tampilkanAvatar;

  @override
  Widget build(BuildContext context) {
    final namaDepan = user.nama.split(' ').first;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tampilkanAvatar ? 'Halo, $namaDepan 👋' : 'Selamat datang kembali 👋',
                style: TextStyle(
                    fontSize: tampilkanAvatar ? 12 : 12.5,
                    color: T.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                tampilkanAvatar ? user.nama : 'Halo, $namaDepan',
                style: TextStyle(
                    fontSize: tampilkanAvatar ? 16 : 22,
                    fontWeight: FontWeight.w800),
              ),
              if (!tampilkanAvatar) ...[
                const SizedBox(height: 3),
                const Text(
                  'Berikut ringkasan presensi Anda hari ini.',
                  style: TextStyle(fontSize: 12, color: T.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (tampilkanAvatar)
          GestureDetector(
            onTap: onTap,
            child: AvatarFoto(
              inisial: user.inisial,
              foto: foto,
              size: 44,
              bg: T.blueBg,
              fg: T.accent,
              borderColor: T.accent,
              borderWidth: 2,
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KARTU HERO (jam + status)
// ═══════════════════════════════════════════════════════════════
class _KartuHero extends StatelessWidget {
  const _KartuHero({
    required this.user,
    required this.now,
    required this.statusTeks,
    required this.labelTombol,
    required this.ikonTombol,
    required this.menitBerjalan,
    required this.tampilkanProgres,
    required this.onTap,
    required this.web,
  });

  final Karyawan user;
  final DateTime now;
  final String statusTeks;
  final String labelTombol;
  final IconData ikonTombol;
  final int menitBerjalan;
  final bool tampilkanProgres;
  final VoidCallback onTap;
  final bool web;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(web ? 24 : 18),
      decoration: BoxDecoration(
        gradient: T.heroGradient,
        borderRadius: BorderRadius.circular(T.rXl),
        boxShadow: [
          BoxShadow(
            color: T.navy.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: AppBadge(user.jadwal, tone: AppBadgeTone.onHero)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(tanggalPanjang(now),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFFCBDCFF))),
              ),
            ],
          ),
          SizedBox(height: web ? 20 : 16),
          Text(jamLengkap(now),
              style: TextStyle(
                  fontSize: web ? 46 : 40,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(statusTeks,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDCE7FF))),
          if (tampilkanProgres) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (menitBerjalan / 540).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF7DD3A8)),
              ),
            ),
          ],
          SizedBox(height: web ? 18 : 14),
          _TombolHero(label: labelTombol, ikon: ikonTombol, onTap: onTap),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RINGKASAN BULAN
// ═══════════════════════════════════════════════════════════════
class _RingkasanBulan extends StatelessWidget {
  const _RingkasanBulan({
    required this.app,
    required this.bulan,
    required this.onBukaRiwayat,
  });

  final AppState app;
  final DateTime bulan;
  final void Function(RiwayatFilter) onBukaRiwayat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Ringkasan Bulan Ini')),
            Text(bulanTahun(bulan),
                style: const TextStyle(fontSize: 11, color: T.textMuted)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Hadir',
                value: '${app.hadirBulan(bulan)} hari',
                note: '${app.terlambatBulan(bulan)} kali terlambat',
                tone: StatTone.green,
                onTap: () => onBukaRiwayat(RiwayatFilter.hadir),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                label: 'Izin / Cuti',
                value: '${app.izinDisetujuiBulanIni} disetujui',
                note: '${app.pengajuanMenunggu} pengajuan menunggu',
                tone: StatTone.blue,
                onTap: () => onBukaRiwayat(RiwayatFilter.izin),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: T.amberBg,
                  borderRadius: BorderRadius.circular(T.rMd),
                ),
                child: const Icon(Icons.timer_outlined,
                    size: 18, color: T.amber),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Total jam kerja bulan ini',
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              Text(durasiLabel(app.menitKerjaBulan(bulan)),
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: T.navy)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MENU CEPAT
// ═══════════════════════════════════════════════════════════════
class _MenuCepatGrid extends StatelessWidget {
  const _MenuCepatGrid({
    required this.web,
    required this.onPresensi,
    required this.onPengajuan,
    required this.onRiwayat,
    required this.onProfil,
  });

  final bool web;
  final VoidCallback onPresensi;
  final VoidCallback onPengajuan;
  final VoidCallback onRiwayat;
  final VoidCallback onProfil;

  @override
  Widget build(BuildContext context) {
    final kartu = <Widget>[
      _MenuCepat(
        ikon: Icons.fingerprint_rounded,
        judul: 'Presensi',
        ket: 'Clock In / Out dengan selfie & lokasi',
        onTap: onPresensi,
      ),
      _MenuCepat(
        ikon: Icons.event_note_rounded,
        judul: 'Pengajuan Izin',
        ket: 'Ajukan cuti / izin secara online',
        onTap: onPengajuan,
      ),
      _MenuCepat(
        ikon: Icons.history_rounded,
        judul: 'Riwayat',
        ket: 'Lihat catatan presensi dan status izin',
        onTap: onRiwayat,
      ),
      _MenuCepat(
        ikon: Icons.person_rounded,
        judul: 'Profil Saya',
        ket: 'Data akun, kata sandi, dan kebijakan privasi',
        onTap: onProfil,
      ),
    ];

    if (web) {
      // Empat kartu sejajar dalam satu baris (tinggi disamakan).
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < kartu.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: kartu[i]),
            ],
          ],
        ),
      );
    }

    // Dua kolom untuk layar sempit.
    return Column(
      children: [
        for (var i = 0; i < kartu.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: kartu[i]),
                const SizedBox(width: 10),
                Expanded(child: kartu[i + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Tombol putih di atas hero card (kontras dengan gradien navy).
class _TombolHero extends StatelessWidget {
  const _TombolHero({
    required this.label,
    required this.ikon,
    required this.onTap,
  });

  final String label;
  final IconData ikon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: T.buttonHeight,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: T.navy,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(T.rMd)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Kartu menu cepat.
class _MenuCepat extends StatelessWidget {
  const _MenuCepat({
    required this.ikon,
    required this.judul,
    required this.ket,
    required this.onTap,
  });

  final IconData ikon;
  final String judul;
  final String ket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.card,
      borderRadius: BorderRadius.circular(T.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rLg),
        child: Container(
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(minHeight: 116),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rLg),
            border: Border.all(color: T.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: T.blueBg,
                  borderRadius: BorderRadius.circular(T.rMd),
                ),
                child: Icon(ikon, size: 19, color: T.accent),
              ),
              const SizedBox(height: 10),
              Text(judul,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(ket,
                  style: const TextStyle(
                      fontSize: 11, color: T.textMuted, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daftar empat catatan presensi terakhir (versi web).
class _AktivitasTerakhir extends StatelessWidget {
  const _AktivitasTerakhir({required this.riwayat});

  final List<Presensi> riwayat;

  @override
  Widget build(BuildContext context) {
    final data = [...riwayat]
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
    final tampil = data.take(4).toList();

    if (tampil.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 26),
        child: const Center(
          child: Text('Belum ada catatan presensi.',
              style: TextStyle(fontSize: 11.5, color: T.textSecondary)),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < tampil.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _BarisAktivitas(presensi: tampil[i]),
          ],
        ],
      ),
    );
  }
}

class _BarisAktivitas extends StatelessWidget {
  const _BarisAktivitas({required this.presensi});

  final Presensi presensi;

  @override
  Widget build(BuildContext context) {
    final p = presensi;
    final tone = switch (p.status) {
      StatusPresensi.hadir => AppBadgeTone.green,
      StatusPresensi.terlambat => AppBadgeTone.amber,
      StatusPresensi.wfh => AppBadgeTone.blue,
      StatusPresensi.izinDisetujui => AppBadgeTone.slate,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: T.blueBg,
              borderRadius: BorderRadius.circular(T.rSm),
            ),
            child: const Icon(Icons.event_available_rounded,
                size: 17, color: T.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tanggalSingkat(p.tanggal),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  p.clockIn == null
                      ? 'Tidak ada catatan jam'
                      : 'Masuk ${p.clockIn} · Pulang ${p.clockOut ?? '—'} · '
                          '${p.durasi}',
                  style: const TextStyle(
                      fontSize: 11, color: T.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(p.lokasiNama,
              style: const TextStyle(fontSize: 11, color: T.textMuted)),
          const SizedBox(width: 12),
          AppBadge(p.status.label, tone: tone),
        ],
      ),
    );
  }
}
