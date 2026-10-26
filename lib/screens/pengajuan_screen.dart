import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/berkas/unduh.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

const _maksUkuranLampiran = 1024 * 1024; // 1 MB
const _ekstensiDiizinkan = ['pdf', 'jpg', 'jpeg', 'png'];

/// Form pengajuan izin/cuti (halaman turunan dari Beranda).
class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alasanC = TextEditingController();

  String _jenis = daftarJenisPengajuan.first;
  DateTime? _mulai;
  DateTime? _selesai;
  Lampiran? _lampiran;
  bool _berhasil = false;
  bool _mengunggah = false;

  @override
  void dispose() {
    _alasanC.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal({required bool mulai}) async {
    final awal = mulai ? DateTime.now() : (_mulai ?? DateTime.now());
    final hasil = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: mulai ? 'Pilih tanggal mulai' : 'Pilih tanggal selesai',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (hasil == null) return;
    setState(() {
      _berhasil = false;
      if (mulai) {
        _mulai = hasil;
        if (_selesai != null && _selesai!.isBefore(hasil)) _selesai = hasil;
      } else {
        _selesai = hasil;
      }
    });
  }

  /// Pilih berkas dari perangkat (Chrome membuka dialog file).
  Future<void> _pilihLampiran() async {
    setState(() => _mengunggah = true);
    try {
      final f = await FilePicker.pickFile(
        dialogTitle: 'Pilih lampiran pengajuan',
        type: FileType.custom,
        allowedExtensions: _ekstensiDiizinkan,
      );
      if (!mounted) return;
      if (f == null) {
        setState(() => _mengunggah = false);
        return;
      }
      final ext = (f.extension ?? '').toLowerCase();

      if (!_ekstensiDiizinkan.contains(ext)) {
        setState(() => _mengunggah = false);
        showToast(context, 'Format .$ext belum didukung. Gunakan PDF, JPG, atau PNG.',
            ToastKind.error);
        return;
      }
      final ukuran = f.lengthSync() ?? await f.length() ?? 0;
      if (!mounted) return;
      if (ukuran > _maksUkuranLampiran) {
        setState(() => _mengunggah = false);
        showToast(
            context,
            'Ukuran berkas ${ukuranFile(ukuran)} melebihi batas 1 MB.',
            ToastKind.error);
        return;
      }
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        setState(() => _mengunggah = false);
        showToast(context, 'Berkas kosong. Silakan pilih berkas lain.',
            ToastKind.error);
        return;
      }

      setState(() {
        _lampiran = Lampiran(
          nama: f.name,
          ukuran: bytes.length,
          tipe: switch (ext) {
            'pdf' => 'application/pdf',
            'png' => 'image/png',
            _ => 'image/jpeg',
          },
          bytes: bytes,
        );
        _mengunggah = false;
        _berhasil = false;
      });
      showToast(context, 'Lampiran "${f.name}" berhasil diunggah.',
          ToastKind.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengunggah = false);
      showToast(context, 'Gagal memilih berkas: $e', ToastKind.error);
    }
  }

  Future<void> _kirim() async {
    setState(() => _berhasil = false);
    final valid = _formKey.currentState!.validate();
    if (_mulai == null) {
      showToast(context, 'Tanggal mulai wajib dipilih.', ToastKind.error);
      return;
    }
    if (_selesai == null) {
      showToast(context, 'Tanggal selesai wajib dipilih.', ToastKind.error);
      return;
    }
    if (_selesai!.isBefore(_mulai!)) {
      showToast(context, 'Tanggal selesai tidak boleh lebih awal.', ToastKind.error);
      return;
    }
    if (!valid) return;

    context.read<AppState>().kirimPengajuan(
          jenis: _jenis,
          mulai: _mulai!,
          selesai: _selesai!,
          alasan: _alasanC.text.trim(),
          lampiran: _lampiran,
        );

    setState(() {
      _berhasil = true;
      _mulai = null;
      _selesai = null;
      _lampiran = null;
      _jenis = daftarJenisPengajuan.first;
    });
    _alasanC.clear();
    showToast(context, 'Pengajuan berhasil dikirim ke HC.', ToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Pengajuan Izin & Cuti'),
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
              const Text(
                'Ajukan cuti atau izin tanpa formulir manual. Pengajuan akan '
                'diteruskan ke HC untuk disetujui.',
                style: TextStyle(
                    fontSize: 12.5, color: T.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),

              if (_berhasil) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: T.greenBg,
                    borderRadius: BorderRadius.circular(T.rLg),
                    border: Border.all(color: T.greenBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, color: T.green, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pengajuan berhasil dikirim',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: T.green)),
                            SizedBox(height: 3),
                            Text(
                              'Pantau status persetujuannya pada menu Riwayat.',
                              style:
                                  TextStyle(fontSize: 11.5, color: T.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: T.card,
                  borderRadius: BorderRadius.circular(T.rXl),
                  border: Border.all(color: T.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _jenis,
                        decoration: const InputDecoration(
                            labelText: 'Jenis Pengajuan'),
                        style: const TextStyle(fontSize: 14, color: T.text),
                        items: [
                          for (final j in daftarJenisPengajuan)
                            DropdownMenuItem(value: j, child: Text(j)),
                        ],
                        onChanged: (v) => setState(() {
                          _jenis = v ?? _jenis;
                          _berhasil = false;
                        }),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _TombolTanggal(
                              label: 'Tanggal Mulai',
                              nilai:
                                  _mulai == null ? 'Pilih tanggal' : tanggalSingkat(_mulai!),
                              terisi: _mulai != null,
                              onTap: () => _pilihTanggal(mulai: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TombolTanggal(
                              label: 'Tanggal Selesai',
                              nilai: _selesai == null
                                  ? 'Pilih tanggal'
                                  : tanggalSingkat(_selesai!),
                              terisi: _selesai != null,
                              onTap: () => _pilihTanggal(mulai: false),
                            ),
                          ),
                        ],
                      ),
                      if (_mulai != null && _selesai != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Total ${_selesai!.difference(_mulai!).inDays + 1} hari pengajuan',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: T.accent),
                        ),
                      ],
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _alasanC,
                        maxLines: 4,
                        onChanged: (_) {
                          if (_berhasil) setState(() => _berhasil = false);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Alasan Pengajuan',
                          hintText:
                              'Tuliskan alasan secara jelas (minimal 10 karakter)',
                          alignLabelWithHint: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Alasan wajib diisi.';
                          if (t.length < 10) {
                            return 'Tuliskan alasan minimal 10 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ── Lampiran ─────────────────────────
                      if (_lampiran == null)
                        InkWell(
                          onTap: _mengunggah ? null : _pilihLampiran,
                          borderRadius: BorderRadius.circular(T.rMd),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: T.blueBg,
                              borderRadius: BorderRadius.circular(T.rMd),
                              border: Border.all(
                                  color: T.blueBorder, style: BorderStyle.solid),
                            ),
                            child: Row(
                              children: [
                                if (_mengunggah)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: T.accent),
                                  )
                                else
                                  const Icon(Icons.upload_file_rounded,
                                      size: 20, color: T.accent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _mengunggah
                                            ? 'Membuka berkas…'
                                            : 'Pilih berkas lampiran',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: T.accent),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'PDF, JPG, atau PNG · maksimal 1 MB',
                                        style: TextStyle(
                                            fontSize: 10.5, color: T.accent),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_rounded,
                                    size: 16, color: T.accent),
                              ],
                            ),
                          ),
                        )
                      else
                        _KartuLampiran(
                          lampiran: _lampiran!,
                          onGanti: _mengunggah ? null : _pilihLampiran,
                          onHapus: () => setState(() => _lampiran = null),
                        ),
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Kirim Pengajuan',
                        icon: Icons.send_rounded,
                        onPressed: _kirim,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
class _KartuLampiran extends StatelessWidget {
  const _KartuLampiran({
    required this.lampiran,
    required this.onGanti,
    required this.onHapus,
  });

  final Lampiran lampiran;
  final VoidCallback? onGanti;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: T.greenBg,
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: T.greenBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: T.card,
              borderRadius: BorderRadius.circular(T.rSm),
              border: Border.all(color: T.greenBorder),
            ),
            alignment: Alignment.center,
            child: Text(lampiran.ekstensi,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: T.green)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lampiran.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${lampiran.ukuranLabel} · berhasil diunggah',
                    style: const TextStyle(fontSize: 10.5, color: T.green)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ganti berkas',
            onPressed: onGanti,
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            color: T.accent,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Hapus lampiran',
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: T.red,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TombolTanggal extends StatelessWidget {
  const _TombolTanggal({
    required this.label,
    required this.nilai,
    required this.terisi,
    required this.onTap,
  });

  final String label;
  final String nilai;
  final bool terisi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.rMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(T.rMd),
          border: Border.all(color: T.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10.5, color: T.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    nilai,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: terisi ? FontWeight.w700 : FontWeight.w500,
                      color: terisi ? T.text : T.textMuted,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: T.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pratinjau lampiran — dipakai di Detail Pengajuan (karyawan) & portal HC.
Future<void> tampilkanLampiran(BuildContext context, Lampiran lampiran) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        Text(lampiran.nama,
                            maxLines: 2,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text('${lampiran.ekstensi} · ${lampiran.ukuranLabel}',
                            style: const TextStyle(
                                fontSize: 11, color: T.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: lampiran.bytes == null
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: T.canvas,
                          borderRadius: BorderRadius.circular(T.rMd),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.insert_drive_file_outlined,
                                size: 36, color: T.textMuted),
                            SizedBox(height: 8),
                            Text(
                              'Berkas contoh dari data awal tidak menyimpan isi '
                              'file. Unggah lampiran baru untuk mencoba pratinjau.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  color: T.textSecondary,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      )
                    : lampiran.gambar
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(T.rMd),
                            child: Image.memory(lampiran.bytes!,
                                fit: BoxFit.contain),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: T.canvas,
                              borderRadius: BorderRadius.circular(T.rMd),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded,
                                    size: 40, color: T.red),
                                const SizedBox(height: 10),
                                const Text(
                                  'Dokumen PDF siap diunduh untuk diperiksa.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12, color: T.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                AppButton(
                                  label: 'Unduh Berkas',
                                  icon: Icons.download_rounded,
                                  height: 40,
                                  expand: false,
                                  onPressed: () => unduhBerkas(
                                      lampiran.nama,
                                      lampiran.bytes!,
                                      lampiran.tipe),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
