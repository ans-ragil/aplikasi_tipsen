import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Persetujuan Cuti & Izin: daftar pengajuan + panel detail + keputusan.
class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  String _filter = 'Semua';
  String? _dipilih;

  static const _opsiFilter = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    final data = app.pengajuanMasuk.where((p) {
      if (_filter == 'Semua') return true;
      return p.status.label == _filter;
    }).toList();

    // Pilih otomatis item pertama bila belum ada pilihan valid.
    PengajuanIzin? terpilih;
    if (data.isNotEmpty) {
      terpilih = data.firstWhere(
        (p) => p.id == _dipilih,
        orElse: () => data.first,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Persetujuan Cuti & Izin',
          subtitle:
              '${app.totalMenungguPersetujuan} pengajuan menunggu keputusan HC.',
          actions: [
            AppBadge('${app.totalMenungguPersetujuan} menunggu',
                tone: AppBadgeTone.amber),
          ],
        ),
        const SizedBox(height: 18),

        // ── Filter ─────────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in _opsiFilter)
              ChoiceChip(
                label: Text(f, style: const TextStyle(fontSize: 11.5)),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: T.navy,
                backgroundColor: T.card,
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _filter == f ? Colors.white : T.textSecondary,
                ),
                side: BorderSide(
                    color: _filter == f ? T.navy : T.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(T.rMd)),
              ),
          ],
        ),
        const SizedBox(height: 14),

        if (data.isEmpty)
          AdminPanel(
            title: 'Tidak ada pengajuan',
            subtitle: 'Belum ada pengajuan pada filter ini.',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Icon(Icons.inbox_rounded, size: 34, color: T.textMuted),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final lebar = c.maxWidth > 980;
              final daftar = Column(
                children: [
                  for (final p in data)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _KartuPengajuan(
                        pengajuan: p,
                        dipilih: p.id == terpilih?.id,
                        onPilih: () => setState(() => _dipilih = p.id),
                        onSetujui: () => _putuskan(context, p.id, true),
                        onTolak: () => _putuskan(context, p.id, false),
                      ),
                    ),
                ],
              );
              final detail = _PanelDetail(pengajuan: terpilih!);

              if (!lebar) {
                return Column(
                  children: [daftar, const SizedBox(height: 16), detail],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: daftar),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: detail),
                ],
              );
            },
          ),
      ],
    );
  }

  void _putuskan(BuildContext context, String id, bool setujui) {
    context.read<AppState>().putuskanPengajuan(id, setujui);
    showToast(
      context,
      setujui
          ? 'Pengajuan disetujui. Karyawan akan menerima notifikasi.'
          : 'Pengajuan ditolak dan dikembalikan ke karyawan.',
      setujui ? ToastKind.success : ToastKind.error,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _KartuPengajuan extends StatelessWidget {
  const _KartuPengajuan({
    required this.pengajuan,
    required this.dipilih,
    required this.onPilih,
    required this.onSetujui,
    required this.onTolak,
  });

  final PengajuanIzin pengajuan;
  final bool dipilih;
  final VoidCallback onPilih;
  final VoidCallback onSetujui;
  final VoidCallback onTolak;

  @override
  Widget build(BuildContext context) {
    final p = pengajuan;
    final tone = switch (p.status) {
      StatusPengajuan.disetujui => AppBadgeTone.green,
      StatusPengajuan.menunggu => AppBadgeTone.amber,
      StatusPengajuan.ditolak => AppBadgeTone.red,
    };

    return Material(
      color: T.card,
      borderRadius: BorderRadius.circular(T.rLg),
      child: InkWell(
        onTap: onPilih,
        borderRadius: BorderRadius.circular(T.rLg),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rLg),
            border: Border.all(color: dipilih ? T.blueBorder : T.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.namaPemohon ?? 'Karyawan',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          Text('${p.jabatanPemohon ?? '-'} · ${p.jenis}',
                              style: const TextStyle(
                                  fontSize: 11, color: T.textMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(p.periodeLabel,
                          style: const TextStyle(
                              fontSize: 11.5, color: T.textSecondary)),
                    ),
                    AppBadge(p.status.label, tone: tone),
                  ],
                ),
              ),
              if (p.status == StatusPengajuan.menunggu)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFBFD),
                    border: Border(top: BorderSide(color: Color(0xFFEDF0F4))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _TombolKecil(
                        label: 'Setujui',
                        ikon: Icons.check_rounded,
                        warna: T.green,
                        border: T.greenBorder,
                        onTap: onSetujui,
                      ),
                      const SizedBox(width: 8),
                      _TombolKecil(
                        label: 'Tolak',
                        ikon: Icons.close_rounded,
                        warna: T.red,
                        border: T.redBorder,
                        onTap: onTolak,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TombolKecil extends StatelessWidget {
  const _TombolKecil({
    required this.label,
    required this.ikon,
    required this.warna,
    required this.border,
    required this.onTap,
  });

  final String label;
  final IconData ikon;
  final Color warna;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.card,
      borderRadius: BorderRadius.circular(T.rSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rSm),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, size: 14, color: warna),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: warna)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _PanelDetail extends StatelessWidget {
  const _PanelDetail({required this.pengajuan});

  final PengajuanIzin pengajuan;

  @override
  Widget build(BuildContext context) {
    final p = pengajuan;
    final tone = switch (p.status) {
      StatusPengajuan.disetujui => AppBadgeTone.green,
      StatusPengajuan.menunggu => AppBadgeTone.amber,
      StatusPengajuan.ditolak => AppBadgeTone.red,
    };

    return AdminPanel(
      title: 'Detail Pengajuan',
      subtitle: p.namaPemohon ?? 'Pilih pengajuan pada daftar',
      trailing: AppBadge(p.status.label, tone: tone),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Baris(label: 'Jenis pengajuan', nilai: p.jenis),
          _Baris(label: 'Periode', nilai: p.periodeLabel),
          _Baris(
              label: 'Jumlah hari',
              nilai:
                  '${p.tanggalSelesai.difference(p.tanggalMulai).inDays + 1} hari'),
          _Baris(
              label: 'Diproses oleh',
              nilai: p.diprosesOleh ?? 'Belum diproses'),
          const SizedBox(height: 12),
          const Text('Alasan',
              style: TextStyle(fontSize: 10.5, color: T.textMuted)),
          const SizedBox(height: 5),
          Text(p.alasan,
              style: const TextStyle(fontSize: 12, height: 1.55)),
          const SizedBox(height: 14),
          if (p.lampiranNama != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: T.blueBg,
                borderRadius: BorderRadius.circular(T.rSm),
                border: Border.all(color: T.blueBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 15, color: T.accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(p.lampiranNama!,
                        style: const TextStyle(
                            fontSize: 11, color: T.accent)),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      size: 14, color: T.accent),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (p.status == StatusPengajuan.menunggu)
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Setujui',
                    icon: Icons.check_rounded,
                    variant: AppButtonVariant.success,
                    height: 42,
                    onPressed: () {
                      context
                          .read<AppState>()
                          .putuskanPengajuan(p.id, true);
                      showToast(context, 'Pengajuan disetujui.',
                          ToastKind.success);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    label: 'Tolak',
                    icon: Icons.close_rounded,
                    variant: AppButtonVariant.danger,
                    height: 42,
                    onPressed: () {
                      context
                          .read<AppState>()
                          .putuskanPengajuan(p.id, false);
                      showToast(context, 'Pengajuan ditolak.', ToastKind.error);
                    },
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.status == StatusPengajuan.disetujui
                    ? T.greenBg
                    : T.redBg,
                borderRadius: BorderRadius.circular(T.rSm),
              ),
              child: Text(
                p.status == StatusPengajuan.disetujui
                    ? 'Pengajuan telah disetujui.'
                    : 'Pengajuan telah ditolak.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: p.status == StatusPengajuan.disetujui
                      ? T.green
                      : T.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 10.5, color: T.textMuted)),
          ),
          Expanded(
            child: Text(nilai,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
