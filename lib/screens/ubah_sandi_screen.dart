import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// Halaman Ubah Kata Sandi (karyawan & HC).
class UbahSandiScreen extends StatefulWidget {
  const UbahSandiScreen({super.key});

  @override
  State<UbahSandiScreen> createState() => _UbahSandiScreenState();
}

class _UbahSandiScreenState extends State<UbahSandiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lamaC = TextEditingController();
  final _baruC = TextEditingController();
  final _ulangC = TextEditingController();

  bool _lihat = false;
  String? _error;

  @override
  void dispose() {
    _lamaC.dispose();
    _baruC.dispose();
    _ulangC.dispose();
    super.dispose();
  }

  /// 0–4 berdasarkan panjang & variasi karakter.
  int get _kekuatan {
    final v = _baruC.text;
    if (v.isEmpty) return 0;
    var skor = 0;
    if (v.length >= 6) skor++;
    if (v.length >= 10) skor++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) skor++;
    if (RegExp(r'[0-9]').hasMatch(v) || RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      skor++;
    }
    return skor.clamp(0, 4);
  }

  void _simpan() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final pesan = context
        .read<AppState>()
        .ubahSandi(_lamaC.text, _baruC.text);
    if (pesan != null) {
      setState(() => _error = pesan);
      return;
    }
    showToast(context, 'Kata sandi berhasil diperbarui.', ToastKind.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kuat = _kekuatan;
    final (labelKuat, warnaKuat) = switch (kuat) {
      0 => ('', T.textMuted),
      1 => ('Lemah', T.red),
      2 => ('Cukup', T.amber),
      3 => ('Kuat', T.green),
      _ => ('Sangat kuat', T.green),
    };

    return Scaffold(
      backgroundColor: T.canvas,
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi'),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.margin, 4, T.margin, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: T.blueBg,
                  borderRadius: BorderRadius.circular(T.rLg),
                  border: Border.all(color: T.blueBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 18, color: T.accent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gunakan kata sandi yang tidak dipakai di layanan lain. '
                        'Minimal 6 karakter, disarankan kombinasi huruf dan angka.',
                        style: TextStyle(
                            fontSize: 11.5, height: 1.5, color: T.accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                      TextFormField(
                        controller: _lamaC,
                        obscureText: !_lihat,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi Saat Ini',
                          prefixIcon: Icon(Icons.lock_outline_rounded,
                              size: 19, color: T.textMuted),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (v) => (v ?? '').isEmpty
                            ? 'Kata sandi saat ini wajib diisi.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _baruC,
                        obscureText: !_lihat,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi Baru',
                          prefixIcon: const Icon(Icons.lock_reset_rounded,
                              size: 19, color: T.textMuted),
                          suffixIcon: IconButton(
                            tooltip: _lihat ? 'Sembunyikan' : 'Lihat sandi',
                            onPressed: () => setState(() => _lihat = !_lihat),
                            icon: Icon(
                              _lihat
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 19,
                              color: T.textMuted,
                            ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (v) {
                          if ((v ?? '').isEmpty) {
                            return 'Kata sandi baru wajib diisi.';
                          }
                          if ((v ?? '').length < 6) {
                            return 'Kata sandi baru minimal 6 karakter.';
                          }
                          if (v == _lamaC.text) {
                            return 'Kata sandi baru harus berbeda dari yang lama.';
                          }
                          return null;
                        },
                      ),
                      if (kuat > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Expanded(
                                child: Container(
                                  height: 4,
                                  margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                                  decoration: BoxDecoration(
                                    color: i < kuat
                                        ? warnaKuat
                                        : const Color(0xFFE8EDF4),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(labelKuat,
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: warnaKuat)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ulangC,
                        obscureText: !_lihat,
                        decoration: const InputDecoration(
                          labelText: 'Ulangi Kata Sandi Baru',
                          prefixIcon: Icon(Icons.check_circle_outline_rounded,
                              size: 19, color: T.textMuted),
                        ),
                        style: const TextStyle(fontSize: 14),
                        validator: (v) => v != _baruC.text
                            ? 'Konfirmasi kata sandi belum sama.'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: T.redBg,
                            borderRadius: BorderRadius.circular(T.rSm),
                            border: Border.all(color: T.redBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 17, color: T.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: T.red)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      AppButton(
                        label: 'Simpan Kata Sandi',
                        icon: Icons.save_rounded,
                        onPressed: _simpan,
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
