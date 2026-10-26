import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Komponen khusus tata letak web admin (desktop-first).

/// Judul halaman admin + aksi di kanan.
class AdminPageTitle extends StatelessWidget {
  const AdminPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(subtitle,
                style: const TextStyle(fontSize: 12.5, color: T.textSecondary)),
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}

/// Panel putih dengan judul — dipakai hampir di semua halaman admin.
class AdminPanel extends StatelessWidget {
  const AdminPanel({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: const TextStyle(
                              fontSize: 11.5, color: T.textMuted)),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Tabel sederhana dengan header abu-abu dan scroll horizontal.
class AdminTable extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.kolom,
    required this.baris,
    this.lebarMinimal = 760,
  });

  /// Label kolom; panjangnya harus sama dengan jumlah sel tiap baris.
  final List<String> kolom;
  final List<List<Widget>> baris;
  final double lebarMinimal;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: lebarMinimal),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FB),
                borderRadius: BorderRadius.circular(T.rSm),
              ),
              child: Row(
                children: [
                  for (final k in kolom)
                    Expanded(
                      child: Text(k.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: T.textSecondary)),
                    ),
                ],
              ),
            ),
            for (var i = 0; i < baris.length; i++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Color(0xFFEDF0F5))),
                ),
                child: Row(
                  children: [
                    for (final sel in baris[i])
                      Expanded(child: sel),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Sel tabel berisi avatar inisial + nama + subjudul (kolom karyawan).
class AdminEmployeeCell extends StatelessWidget {
  const AdminEmployeeCell({
    super.key,
    required this.inisial,
    required this.nama,
    required this.subjudul,
  });

  final String inisial;
  final String nama;
  final String subjudul;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: T.blueBg,
            borderRadius: BorderRadius.circular(T.rSm),
          ),
          alignment: Alignment.center,
          child: Text(inisial,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: T.accent)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subjudul,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: T.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tombol kecil untuk aksi dalam tabel.
class AdminTextAction extends StatelessWidget {
  const AdminTextAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle:
              const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Kotak pencarian + filter untuk toolbar.
class AdminSearchField extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 40,
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: T.textMuted),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: T.textMuted),
          contentPadding: EdgeInsets.zero,
          isDense: true,
          fillColor: T.card,
        ),
      ),
    );
  }
}

/// Dropdown filter ringkas.
class AdminFilterDropdown extends StatelessWidget {
  const AdminFilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: T.fieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: T.text),
          items: [
            for (final i in items)
              DropdownMenuItem(value: i, child: Text(i)),
          ],
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}

/// Modal pembungkus (dipakai halaman karyawan & monitoring).
Future<R?> showAdminDialog<R>(
  BuildContext context, {
  required Widget child,
  double maxWidth = 480,
}) {
  return showDialog<R>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: T.card,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(T.rLg)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: child,
        ),
      ),
    ),
  );
}
