import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import 'admin_widgets.dart';

/// Manajemen Karyawan: daftar, tambah, ubah, nonaktifkan, hapus.
class AdminEmployeesScreen extends StatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  String _cari = '';
  String _filter = 'Semua';

  static const _opsiFilter = ['Semua', 'Aktif', 'WFH', 'Nonaktif'];
  static const _departemen = [
    'Teknologi Informasi',
    'Produk',
    'Keuangan',
    'Human Capital',
    'Pemasaran',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final data = app.karyawanAdmin.where((k) {
      final cocokCari = k.nama.toLowerCase().contains(_cari.toLowerCase()) ||
          k.email.toLowerCase().contains(_cari.toLowerCase()) ||
          k.jabatan.toLowerCase().contains(_cari.toLowerCase());
      final cocokFilter = _filter == 'Semua' || k.status == _filter;
      return cocokCari && cocokFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageTitle(
          title: 'Manajemen Karyawan',
          subtitle:
              '${app.karyawanAdmin.length} karyawan terdaftar · '
              '${app.totalKaryawan} aktif.',
          actions: [
            AppButton(
              label: 'Tambah Karyawan',
              icon: Icons.person_add_alt_1_rounded,
              expand: false,
              height: 40,
              onPressed: () => _bukaForm(context, null),
            ),
          ],
        ),
        const SizedBox(height: 18),

        AdminPanel(
          title: 'Daftar Karyawan',
          subtitle: 'Kelola data karyawan dan status keaktifannya.',
          trailing: AppBadge('${data.length} ditampilkan',
              tone: AppBadgeTone.slate),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AdminSearchField(
                    hint: 'Cari nama, jabatan, atau email…',
                    onChanged: (v) => setState(() => _cari = v),
                  ),
                  AdminFilterDropdown(
                    value: _filter,
                    items: _opsiFilter,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Icon(Icons.group_off_rounded,
                          size: 34, color: T.textMuted),
                      SizedBox(height: 8),
                      Text('Tidak ada karyawan yang cocok.',
                          style: TextStyle(
                              fontSize: 11.5, color: T.textSecondary)),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, c) {
                    final kolom = c.maxWidth > 1080
                        ? 3
                        : (c.maxWidth > 720 ? 2 : 1);
                    return AdminGrid(
                      kolom: kolom,
                      children: [
                        for (final k in data)
                          _KartuKaryawan(
                            karyawan: k,
                            onEdit: () => _bukaForm(context, k),
                            onToggle: () {
                              app.aturAktifKaryawan(k.id, !k.aktif);
                              showToast(
                                  context,
                                  k.aktif
                                      ? '${k.nama} dinonaktifkan.'
                                      : '${k.nama} diaktifkan kembali.',
                                  k.aktif
                                      ? ToastKind.info
                                      : ToastKind.success);
                            },
                            onHapus: () => _hapus(context, k),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _hapus(BuildContext context, KaryawanAdmin k) async {
    final ya = await showAdminDialog<bool>(
      context,
      maxWidth: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hapus Karyawan?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '${k.nama} (${k.email}) akan dihapus dari daftar karyawan. '
            'Catatan presensi yang sudah ada tetap tersimpan.',
            style: const TextStyle(
                fontSize: 12, height: 1.5, color: T.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Batal',
                  variant: AppButtonVariant.secondary,
                  height: 42,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Hapus',
                  variant: AppButtonVariant.danger,
                  height: 42,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ya != true || !context.mounted) return;
    context.read<AppState>().hapusKaryawan(k.id);
    showToast(context, '${k.nama} dihapus dari daftar.', ToastKind.info);
  }

  Future<void> _bukaForm(BuildContext context, KaryawanAdmin? awal) async {
    final namaC = TextEditingController(text: awal?.nama ?? '');
    final jabatanC = TextEditingController(text: awal?.jabatan ?? '');
    final emailC = TextEditingController(text: awal?.email ?? '');
    var departemen = awal?.departemen ?? _departemen.first;
    var status = awal?.status ?? 'Aktif';
    String? error;
    final formKey = GlobalKey<FormState>();

    final simpan = await showAdminDialog<bool>(
      context,
      maxWidth: 480,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(awal == null ? 'Tambah Karyawan' : 'Ubah Data Karyawan',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Data ini dipakai untuk akun presensi karyawan.',
                  style: TextStyle(fontSize: 11.5, color: T.textSecondary)),
              const SizedBox(height: 16),
              TextFormField(
                controller: namaC,
                decoration: const InputDecoration(labelText: 'Nama lengkap'),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) =>
                    (v ?? '').trim().length < 3 ? 'Nama minimal 3 karakter.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: jabatanC,
                decoration: const InputDecoration(labelText: 'Jabatan'),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Jabatan wajib diisi.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailC,
                decoration: const InputDecoration(labelText: 'Email'),
                style: const TextStyle(fontSize: 13.5),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return 'Email wajib diisi.';
                  if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(t)) {
                    return 'Format email belum benar.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: departemen,
                      decoration:
                          const InputDecoration(labelText: 'Departemen'),
                      style: const TextStyle(fontSize: 13, color: T.text),
                      items: [
                        for (final d in _departemen)
                          DropdownMenuItem(value: d, child: Text(d)),
                      ],
                      onChanged: (v) => setLocal(() => departemen = v ?? departemen),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      style: const TextStyle(fontSize: 13, color: T.text),
                      items: const [
                        DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                        DropdownMenuItem(value: 'WFH', child: Text('WFH')),
                        DropdownMenuItem(
                            value: 'Nonaktif', child: Text('Nonaktif')),
                      ],
                      onChanged: (v) => setLocal(() => status = v ?? status),
                    ),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: T.redBg,
                    borderRadius: BorderRadius.circular(T.rSm),
                    border: Border.all(color: T.redBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: T.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(error!,
                            style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: T.red)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Batal',
                      variant: AppButtonVariant.secondary,
                      height: 42,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Simpan',
                      height: 42,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final app = context.read<AppState>();
                        final data = KaryawanAdmin(
                          id: awal?.id ?? 'EMP-${DateTime.now().millisecondsSinceEpoch % 10000}',
                          nama: namaC.text.trim(),
                          jabatan: jabatanC.text.trim(),
                          departemen: departemen,
                          status: status,
                          email: emailC.text.trim(),
                          aktif: status != 'Nonaktif',
                        );
                        final pesan = awal == null
                            ? app.tambahKaryawan(data)
                            : app.perbaruiKaryawan(
                                app.karyawanAdmin.indexWhere(
                                    (e) => e.id == awal.id),
                                data,
                              );
                        if (pesan != null) {
                          setLocal(() => error = pesan);
                          return;
                        }
                        Navigator.of(ctx).pop(true);
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

    namaC.dispose();
    jabatanC.dispose();
    emailC.dispose();
    if (simpan == true && context.mounted) {
      showToast(context,
          awal == null ? 'Karyawan ditambahkan.' : 'Data karyawan diperbarui.',
          ToastKind.success);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
class _KartuKaryawan extends StatelessWidget {
  const _KartuKaryawan({
    required this.karyawan,
    required this.onEdit,
    required this.onToggle,
    required this.onHapus,
  });

  final KaryawanAdmin karyawan;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final k = karyawan;
    final tone = switch (k.status) {
      'Aktif' => AppBadgeTone.green,
      'WFH' => AppBadgeTone.blue,
      _ => AppBadgeTone.slate,
    };

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: k.aktif ? T.blueBg : const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(T.rMd),
                ),
                alignment: Alignment.center,
                child: Text(k.inisial,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: k.aktif ? T.accent : T.textMuted)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                    Text(k.jabatan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: T.textMuted)),
                  ],
                ),
              ),
              AppBadge(k.status, tone: tone),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded,
                  size: 13, color: T.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(k.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5, color: T.textSecondary)),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 13, color: T.textMuted),
              const SizedBox(width: 5),
              Expanded(
                child: Text(k.departemen,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10.5, color: T.textSecondary)),
              ),
            ],
          ),
          const Spacer(),
          const Divider(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminTextAction(label: 'Ubah', onTap: onEdit),
              ),
              Expanded(
                child: AdminTextAction(
                    label: k.aktif ? 'Nonaktifkan' : 'Aktifkan',
                    onTap: onToggle),
              ),
              Expanded(
                child: AdminTextAction(label: 'Hapus', onTap: onHapus),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
