import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Manajemen Karyawan: pencarian, filter status, kartu karyawan, modal
/// detail / edit / tambah.
class AdminEmployeesScreen extends StatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  String _cari = '';
  String _status = 'Semua status';

  static const _opsiStatus = ['Semua status', 'Aktif', 'WFH'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.karyawanAdmin.where((k) {
      final cocokCari = k.nama.toLowerCase().contains(_cari.toLowerCase()) ||
          k.jabatan.toLowerCase().contains(_cari.toLowerCase()) ||
          k.departemen.toLowerCase().contains(_cari.toLowerCase());
      final cocokStatus = _status == 'Semua status' || k.status == _status;
      return cocokCari && cocokStatus;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Manajemen Karyawan',
          subtitle: '${app.totalKaryawan} karyawan terdaftar di TIPSEN.',
          actions: [
            AppButton(
              label: 'Tambah Karyawan',
              icon: Icons.person_add_alt_1_rounded,
              expand: false,
              height: 40,
              onPressed: () => _bukaForm(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdminSearchField(
              hint: 'Cari nama, jabatan, departemen…',
              onChanged: (v) => setState(() => _cari = v),
            ),
            AdminFilterDropdown(
              value: _status,
              items: _opsiStatus,
              onChanged: (v) => setState(() => _status = v),
            ),
            Text('${data.length} karyawan',
                style: const TextStyle(fontSize: 11.5, color: T.textMuted)),
          ],
        ),
        const SizedBox(height: 14),
        if (data.isEmpty)
          AdminPanel(
            title: 'Tidak ada karyawan',
            subtitle: 'Ubah kata kunci pencarian atau filter status.',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 26),
              child: Center(
                child: Icon(Icons.person_off_rounded,
                    size: 34, color: T.textMuted),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final kolom = c.maxWidth > 1000 ? 3 : (c.maxWidth > 640 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: kolom,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 196,
                ),
                itemBuilder: (context, i) {
                  final k = data[i];
                  return _KartuKaryawan(
                    karyawan: k,
                    onDetail: () => _bukaDetail(context, k),
                    onEdit: () => _bukaForm(context,
                        karyawan: k, indeks: app.karyawanAdmin.indexOf(k)),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  // ── Modal detail ────────────────────────────────────────────
  void _bukaDetail(BuildContext context, KaryawanAdmin k) {
    showAdminDialog<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text('${k.jabatan} · ${k.departemen}',
                        style: const TextStyle(
                            fontSize: 11.5, color: T.textMuted)),
                  ],
                ),
              ),
              AppBadge(k.status,
                  tone: k.status == 'Aktif'
                      ? AppBadgeTone.green
                      : AppBadgeTone.amber),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(T.rMd),
              border: Border.all(color: T.border),
            ),
            child: Column(
              children: [
                InfoTile(label: 'Email', value: k.email),
                const Divider(height: 1),
                InfoTile(label: 'Jabatan', value: k.jabatan),
                const Divider(height: 1),
                InfoTile(label: 'Departemen', value: k.departemen),
                const Divider(height: 1),
                InfoTile(label: 'Status', value: k.status),
                const Divider(height: 1),
                const InfoTile(
                    label: 'Jadwal kerja', value: 'Shift Pagi · 08:00 – 17:00'),
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

  // ── Modal tambah / edit ─────────────────────────────────────
  void _bukaForm(BuildContext context,
      {KaryawanAdmin? karyawan, int? indeks}) {
    final formKey = GlobalKey<FormState>();
    final namaC = TextEditingController(text: karyawan?.nama ?? '');
    final jabatanC = TextEditingController(text: karyawan?.jabatan ?? '');
    final deptC = TextEditingController(text: karyawan?.departemen ?? '');
    final emailC = TextEditingController(text: karyawan?.email ?? '');
    String status = karyawan?.status ?? 'Aktif';
    final baru = karyawan == null;

    showAdminDialog<void>(
      context,
      child: StatefulBuilder(
        builder: (context, setModal) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baru ? 'Tambah Karyawan' : 'Edit Data Karyawan',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Data karyawan baru akan tampil pada daftar HC.',
                  style: TextStyle(fontSize: 11.5, color: T.textMuted)),
              const SizedBox(height: 18),
              TextFormField(
                controller: namaC,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                style: const TextStyle(fontSize: 13),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: jabatanC,
                decoration: const InputDecoration(labelText: 'Jabatan'),
                style: const TextStyle(fontSize: 13),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Jabatan wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: deptC,
                decoration: const InputDecoration(labelText: 'Departemen'),
                style: const TextStyle(fontSize: 13),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Departemen wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailC,
                decoration: const InputDecoration(labelText: 'Email karyawan'),
                style: const TextStyle(fontSize: 13),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Email wajib diisi.';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
                    return 'Format email tidak valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status kerja'),
                style: const TextStyle(fontSize: 13, color: T.text),
                items: const [
                  DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                  DropdownMenuItem(value: 'WFH', child: Text('WFH')),
                ],
                onChanged: (v) => setModal(() => status = v ?? 'Aktif'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Simpan',
                      icon: Icons.save_rounded,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final data = KaryawanAdmin(
                          nama: namaC.text.trim(),
                          jabatan: jabatanC.text.trim(),
                          departemen: deptC.text.trim(),
                          status: status,
                          email: emailC.text.trim(),
                        );
                        final app = context.read<AppState>();
                        if (baru) {
                          app.tambahKaryawan(data);
                        } else {
                          app.perbaruiKaryawan(indeks ?? 0, data);
                        }
                        Navigator.of(context).pop();
                        showToast(context,
                            baru ? 'Karyawan ditambahkan.' : 'Data karyawan diperbarui.',
                            ToastKind.success);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _KartuKaryawan extends StatelessWidget {
  const _KartuKaryawan({
    required this.karyawan,
    required this.onDetail,
    required this.onEdit,
  });

  final KaryawanAdmin karyawan;
  final VoidCallback onDetail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final k = karyawan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminEmployeeCell(
                inisial: k.inisial,
                nama: k.nama,
                subjudul: k.jabatan,
              ),
              const SizedBox(width: 6),
              AppBadge(k.status,
                  tone: k.status == 'Aktif'
                      ? AppBadgeTone.green
                      : AppBadgeTone.amber),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFEDF0F5)),
                bottom: BorderSide(color: Color(0xFFEDF0F5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Departemen',
                          style:
                              TextStyle(fontSize: 9.5, color: T.textMuted)),
                      const SizedBox(height: 3),
                      Text(k.departemen,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email',
                          style:
                              TextStyle(fontSize: 9.5, color: T.textMuted)),
                      const SizedBox(height: 3),
                      Text(k.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton(
                    onPressed: onDetail,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: T.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(T.rSm)),
                      foregroundColor: T.textSecondary,
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Lihat Detail'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 13),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: T.blueBorder),
                      backgroundColor: T.blueBg,
                      foregroundColor: T.accent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(T.rSm)),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
