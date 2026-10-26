import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Laporan & Ekspor Data: filter periode, ringkasan, tabel rekap, ekspor.
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _periode = 'Oktober 2026';
  String _statusFilter = 'Semua status';

  static const _opsiPeriode = ['Oktober 2026', 'September 2026', 'Agustus 2026'];
  static const _opsiStatus = ['Semua status', 'Hadir', 'Terlambat', 'WFH'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.monitoring
        .where((m) => _statusFilter == 'Semua status' || m.status.label == _statusFilter)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const AdminPageTitle(
          title: 'Laporan & Ekspor Data',
          subtitle: 'Rekap kehadiran karyawan per periode.',
        ),
        const SizedBox(height: 18),

        // ── Filter ─────────────────────────────────────────
        AdminPanel(
          title: 'Filter Laporan',
          subtitle: 'Pilih periode dan status yang ingin ditampilkan.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminFilterDropdown(
                value: _periode,
                items: _opsiPeriode,
                onChanged: (v) => setState(() => _periode = v),
              ),
              AdminFilterDropdown(
                value: _statusFilter,
                items: _opsiStatus,
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
              AppButton(
                label: 'Terapkan',
                icon: Icons.filter_alt_rounded,
                expand: false,
                height: 40,
                onPressed: () => showToast(
                    context, 'Filter diterapkan: $_periode.', ToastKind.info),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Ringkasan ──────────────────────────────────────
        LayoutBuilder(
          builder: (context, c) {
            final kolom = c.maxWidth > 900 ? 3 : 1;
            return GridView.count(
              crossAxisCount: kolom,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: kolom == 1 ? 3.6 : 2.4,
              children: [
                StatCard(
                  label: 'Total Kehadiran',
                  value: '${app.monitoring.length * 22} catatan',
                  note: 'Akumulasi $_periode',
                  tone: StatTone.blue,
                ),
                StatCard(
                  label: 'Rata-rata Jam Masuk',
                  value: '07:58',
                  note: 'Dari seluruh karyawan',
                  tone: StatTone.slate,
                ),
                StatCard(
                  label: 'Tingkat Kehadiran',
                  value: '${app.persenKehadiran}%',
                  note: 'Target minimal 95%',
                  tone: StatTone.green,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // ── Tabel rekap ────────────────────────────────────
        AdminPanel(
          title: 'Rekap Kehadiran Karyawan',
          subtitle: '$_periode · ${data.length} karyawan',
          child: AdminTable(
            lebarMinimal: 820,
            flex: const [3, 1, 1, 1, 2, 1],
            kolom: const [
              'Karyawan',
              'Hadir',
              'Terlambat',
              'Izin / WFH',
              'Kehadiran',
              'Aksi',
            ],
            baris: [
              for (final m in data)
                [
                  AdminEmployeeCell(
                    inisial: m.inisial,
                    nama: m.nama,
                    subjudul: m.jabatan,
                  ),
                  Text(
                    m.status == StatusPresensi.izinDisetujui ? '0' : '22',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    m.status == StatusPresensi.terlambat ? '2' : '0',
                    style: const TextStyle(fontSize: 12, color: T.textSecondary),
                  ),
                  Text(
                    m.status == StatusPresensi.izinDisetujui ? '1' : '0',
                    style: const TextStyle(fontSize: 12, color: T.textSecondary),
                  ),
                  _PersenKehadiran(
                    persen: m.status == StatusPresensi.izinDisetujui ? 92 : 100,
                  ),
                  AdminTextAction(
                    label: 'Rincian',
                    onTap: () => _bukaRincian(context, m),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Ekspor ─────────────────────────────────────────
        AdminPanel(
          title: 'Ekspor Laporan',
          subtitle: 'Unduh rekap kehadiran untuk kebutuhan administrasi.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppButton(
                label: 'Ekspor Excel (.xlsx)',
                icon: Icons.table_view_rounded,
                expand: false,
                height: 44,
                onPressed: () => showToast(
                    context,
                    'Laporan Excel $_periode sedang diunduh (simulasi).',
                    ToastKind.success),
              ),
              AppButton(
                label: 'Ekspor PDF',
                icon: Icons.picture_as_pdf_rounded,
                expand: false,
                height: 44,
                variant: AppButtonVariant.secondary,
                onPressed: () => showToast(context,
                    'Laporan PDF $_periode disiapkan (simulasi).', ToastKind.info),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _bukaRincian(BuildContext context, BarisMonitoring m) {
    showAdminDialog<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rincian — ${m.nama}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Periode $_periode',
              style: const TextStyle(fontSize: 11.5, color: T.textMuted)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rMd),
              border: Border.all(color: T.border),
            ),
            child: Column(
              children: [
                InfoTile(
                    label: 'Total hari kerja',
                    value: '22 hari'),
                const Divider(height: 1),
                InfoTile(
                    label: 'Hadir tepat waktu',
                    value: m.status == StatusPresensi.terlambat ? '20 hari' : '22 hari'),
                const Divider(height: 1),
                InfoTile(
                    label: 'Terlambat',
                    value: m.status == StatusPresensi.terlambat ? '2 hari' : '0 hari'),
                const Divider(height: 1),
                InfoTile(
                    label: 'Izin / cuti',
                    value: m.status == StatusPresensi.izinDisetujui ? '1 hari' : '0 hari'),
                const Divider(height: 1),
                InfoTile(label: 'Rata-rata jam masuk', value: m.jamMasuk),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Tutup',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _PersenKehadiran extends StatelessWidget {
  const _PersenKehadiran({required this.persen});

  final int persen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: persen / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDF0F4),
              valueColor: AlwaysStoppedAnimation(
                  persen >= 95 ? const Color(0xFF10B981) : T.amber),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$persen%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
