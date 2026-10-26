import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../state/app_state.dart';

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
  String? _lampiran;
  bool _berhasil = false;

  @override
  void dispose() {
    _alasanC.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) {
    const bulan = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${bulan[d.month]} ${d.year}';
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
      if (mulai) {
        _mulai = hasil;
        if (_selesai != null && _selesai!.isBefore(hasil)) _selesai = hasil;
      } else {
        _selesai = hasil;
      }
    });
  }

  void _kirim() {
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
          lampiranNama: _lampiran,
        );

    setState(() => _berhasil = true);
    showToast(context, 'Pengajuan berhasil dikirim ke HC.', ToastKind.success);

    _alasanC.clear();
    setState(() {
      _mulai = null;
      _selesai = null;
      _lampiran = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Pengajuan Izin & Cuti'),
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
              const Text(
                'Ajukan cuti atau izin tanpa formulir manual. '
                'Pengajuan akan diteruskan ke HC untuk disetujui.',
                style: TextStyle(fontSize: 12.5, color: T.textSecondary, height: 1.5),
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
                              'Status pengajuan dapat dipantau pada menu Riwayat.',
                              style: TextStyle(fontSize: 11.5, color: T.green),
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
                      // Jenis pengajuan
                      DropdownButtonFormField<String>(
                        initialValue: _jenis,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Pengajuan',
                        ),
                        style: const TextStyle(fontSize: 14, color: T.text),
                        items: [
                          for (final j in daftarJenisPengajuan)
                            DropdownMenuItem(value: j, child: Text(j)),
                        ],
                        onChanged: (v) => setState(() => _jenis = v ?? _jenis),
                      ),
                      const SizedBox(height: 14),

                      // Tanggal
                      Row(
                        children: [
                          Expanded(
                            child: _TombolTanggal(
                              label: 'Tanggal Mulai',
                              nilai: _mulai == null ? 'Pilih tanggal' : _fmt(_mulai!),
                              terisi: _mulai != null,
                              onTap: () => _pilihTanggal(mulai: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _TombolTanggal(
                              label: 'Tanggal Selesai',
                              nilai:
                                  _selesai == null ? 'Pilih tanggal' : _fmt(_selesai!),
                              terisi: _selesai != null,
                              onTap: () => _pilihTanggal(mulai: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Alasan
                      TextFormField(
                        controller: _alasanC,
                        maxLines: 4,
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

                      // Lampiran (simulasi)
                      GestureDetector(
                        onTap: () {
                          setState(() => _lampiran = 'lampiran-pengajuan.pdf');
                          showToast(context,
                              'Lampiran dipilih (simulasi): lampiran-pengajuan.pdf',
                              ToastKind.info);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: T.blueBg,
                            borderRadius: BorderRadius.circular(T.rMd),
                            border: Border.all(color: T.blueBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file_rounded,
                                  size: 18, color: T.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lampiran ?? 'Lampiran pendukung (opsional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: _lampiran == null
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: T.accent,
                                  ),
                                ),
                              ),
                              if (_lampiran != null)
                                GestureDetector(
                                  onTap: () => setState(() => _lampiran = null),
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: T.accent),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Format PDF/JPG/PNG maksimal 1 MB (simulasi pada fase ini).',
                        style: TextStyle(fontSize: 10.5, color: T.textMuted),
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
                style: const TextStyle(fontSize: 10.5, color: T.textSecondary)),
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
