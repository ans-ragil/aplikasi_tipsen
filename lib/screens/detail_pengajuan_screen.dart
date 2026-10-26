import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';

/// Detail satu pengajuan izin/cuti (halaman turunan).
class DetailPengajuanScreen extends StatelessWidget {
  const DetailPengajuanScreen({super.key, required this.pengajuan});

  final PengajuanIzin pengajuan;

  @override
  Widget build(BuildContext context) {
    final (pesan, warna, bg, border, ikon) = switch (pengajuan.status) {
      StatusPengajuan.disetujui => (
          'Pengajuan Anda telah disetujui oleh HC.',
          T.green,
          T.greenBg,
          T.greenBorder,
          Icons.check_circle_rounded
        ),
      StatusPengajuan.menunggu => (
          'Pengajuan sedang menunggu persetujuan HC.',
          T.amber,
          T.amberBg,
          T.amberBorder,
          Icons.schedule_rounded
        ),
      StatusPengajuan.ditolak => (
          'Pengajuan Anda ditolak. Silakan hubungi HC untuk keterangan.',
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
              // ── Ringkasan status ────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(ikon, color: warna, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pengajuan.status.label,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: warna)),
                          const SizedBox(height: 3),
                          Text(pesan,
                              style: TextStyle(
                                  fontSize: 12, color: warna, height: 1.45)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Rincian pengajuan ──────────────────────
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
                    InfoTile(label: 'Jenis', value: pengajuan.jenis),
                    const Divider(height: 1),
                    InfoTile(label: 'Periode', value: pengajuan.periodeLabel),
                    const Divider(height: 1),
                    InfoTile(label: 'Status', value: pengajuan.status.label),
                    const Divider(height: 1),
                    InfoTile(
                      label: 'Diproses oleh',
                      value: pengajuan.diprosesOleh ?? 'Belum diproses',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Alasan ─────────────────────────────────
              const SectionLabel('Alasan Pengajuan'),
              const SizedBox(height: 8),
              AppCard(
                child: Text(pengajuan.alasan,
                    style: const TextStyle(
                        fontSize: 13, height: 1.6, color: T.text)),
              ),
              const SizedBox(height: 16),

              // ── Lampiran ───────────────────────────────
              const SectionLabel('Lampiran'),
              const SizedBox(height: 8),
              AppCard(
                onTap: () => showToast(
                    context, 'Pratinjau lampiran (simulasi).', ToastKind.info),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: T.blueBg,
                        borderRadius: BorderRadius.circular(T.rMd),
                      ),
                      child: const Icon(Icons.description_rounded,
                          size: 19, color: T.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pengajuan.lampiranNama ?? 'Tidak ada lampiran',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: pengajuan.lampiranNama == null
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: pengajuan.lampiranNama == null
                              ? T.textMuted
                              : T.text,
                        ),
                      ),
                    ),
                    if (pengajuan.lampiranNama != null)
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
