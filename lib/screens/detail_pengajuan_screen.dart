import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import 'pengajuan_screen.dart';

/// Detail satu pengajuan izin/cuti (halaman turunan — punya tombol kembali).
class DetailPengajuanScreen extends StatelessWidget {
  const DetailPengajuanScreen({super.key, required this.pengajuan});

  final PengajuanIzin pengajuan;

  @override
  Widget build(BuildContext context) {
    final p = pengajuan;
    final (pesan, warna, bg, border, ikon) = switch (p.status) {
      StatusPengajuan.disetujui => (
          'Pengajuan telah disetujui oleh HC. Kehadiran Anda pada tanggal '
              'tersebut dicatat sebagai izin.',
          T.green,
          T.greenBg,
          T.greenBorder,
          Icons.verified_rounded
        ),
      StatusPengajuan.menunggu => (
          'Pengajuan sedang ditinjau HC. Anda akan menerima pembaruan status '
              'pada halaman ini.',
          T.amber,
          T.amberBg,
          T.amberBorder,
          Icons.hourglass_top_rounded
        ),
      StatusPengajuan.ditolak => (
          'Pengajuan ditolak oleh HC.',
          T.red,
          T.redBg,
          T.redBorder,
          Icons.cancel_rounded
        ),
    };

    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Detail Pengajuan'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.margin, 4, T.margin, 28),
            children: [
              // ── Ringkasan ────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: T.heroGradient,
                  borderRadius: BorderRadius.circular(T.rXl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(p.status.label, tone: AppBadgeTone.onHero),
                    const SizedBox(height: 12),
                    Text(p.jenis,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${p.periodeLabel} · ${p.jumlahHari} hari',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFDCE7FF))),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Status ───────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(ikon, color: warna, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(pesan,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                              color: warna)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Rincian ──────────────────────────────────
              const SectionLabel('Rincian Pengajuan'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: T.card,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: T.border),
                ),
                child: Column(
                  children: [
                    InfoTile(label: 'Jenis', value: p.jenis),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Tanggal mulai',
                        value: tanggalPanjang(p.tanggalMulai)),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Tanggal selesai',
                        value: tanggalPanjang(p.tanggalSelesai)),
                    const Divider(height: 1),
                    InfoTile(label: 'Jumlah hari', value: '${p.jumlahHari} hari'),
                    const Divider(height: 1),
                    InfoTile(label: 'Status', value: p.status.label),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Diajukan pada',
                        value: p.diajukanPada == null
                            ? '—'
                            : '${tanggalSingkat(p.diajukanPada!)} · '
                                '${jamMenit(p.diajukanPada!)}'),
                    const Divider(height: 1),
                    InfoTile(
                        label: 'Diproses oleh',
                        value: p.diprosesOleh ?? 'Belum diproses'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Alasan ───────────────────────────────────
              const SectionLabel('Alasan Pengajuan'),
              const SizedBox(height: 8),
              AppCard(
                child: Text(p.alasan,
                    style: const TextStyle(fontSize: 12.5, height: 1.6)),
              ),

              // ── Alasan penolakan ─────────────────────────
              if (p.status == StatusPengajuan.ditolak &&
                  (p.alasanPenolakan ?? '').isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionLabel('Catatan dari HC'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: T.redBg,
                    borderRadius: BorderRadius.circular(T.rLg),
                    border: Border.all(color: T.redBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18, color: T.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.alasanPenolakan!,
                            style: const TextStyle(
                                fontSize: 12,
                                height: 1.55,
                                color: T.red,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Lampiran ─────────────────────────────────
              const SizedBox(height: 16),
              const SectionLabel('Lampiran Pendukung'),
              const SizedBox(height: 8),
              if (p.lampiran == null)
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file_rounded,
                          size: 17, color: T.textMuted),
                      const SizedBox(width: 8),
                      const Text('Tidak ada lampiran',
                          style: TextStyle(
                              fontSize: 12, color: T.textSecondary)),
                    ],
                  ),
                )
              else
                AppCard(
                  onTap: () => tampilkanLampiran(context, p.lampiran!),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: T.blueBg,
                          borderRadius: BorderRadius.circular(T.rSm),
                          border: Border.all(color: T.blueBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(p.lampiran!.ekstensi,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: T.accent)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.lampiran!.nama,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                                '${p.lampiran!.ukuranLabel} · ketuk untuk melihat',
                                style: const TextStyle(
                                    fontSize: 10.5, color: T.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded,
                          size: 16, color: T.accent),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Tutup',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
