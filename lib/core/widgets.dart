import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Komponen UI inti TIPSEN — padanan komponen React pada prototipe Figma
/// (ActionButton, Badge, StatCard, Field, PageHeader, SectionLabel).

// ═══════════════════════════════════════════════════════════════
// TOMBOL
// ═══════════════════════════════════════════════════════════════
enum AppButtonVariant { primary, secondary, danger, success, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expand = true,
    this.height = T.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      AppButtonVariant.primary => (T.navy, Colors.white, BorderSide.none),
      AppButtonVariant.secondary => (
          T.card,
          T.navy,
          const BorderSide(color: T.border)
        ),
      AppButtonVariant.danger => (T.redBg, T.red, const BorderSide(color: T.redBorder)),
      AppButtonVariant.success => (T.green, Colors.white, BorderSide.none),
      AppButtonVariant.ghost => (Colors.transparent, T.accent, BorderSide.none),
    };

    final child = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: bg,
        disabledForegroundColor: T.textMuted,
        disabledBackgroundColor: bg.withValues(alpha: 0.45),
        // Lebar minimum 0 (bukan Size.fromHeight yang berarti lebar tak
        // hingga). Tanpa ini, tombol dengan expand:false tetap memaksa
        // selebar induknya dan mendorong elemen lain ke baris baru.
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(T.rMd),
          side: border,
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

// ═══════════════════════════════════════════════════════════════
// BADGE STATUS (selalu dengan teks — aturan aksesibilitas)
// ═══════════════════════════════════════════════════════════════
enum AppBadgeTone { blue, green, amber, red, slate, onHero }

class AppBadge extends StatelessWidget {
  const AppBadge(this.text, {super.key, this.tone = AppBadgeTone.blue});

  final String text;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg, bc) = switch (tone) {
      AppBadgeTone.blue => (T.blue, T.blueBg, T.blueBorder),
      AppBadgeTone.green => (T.green, T.greenBg, T.greenBorder),
      AppBadgeTone.amber => (T.amber, T.amberBg, T.amberBorder),
      AppBadgeTone.red => (T.red, T.redBg, T.redBorder),
      AppBadgeTone.slate => (T.textSecondary, const Color(0xFFF2F5F8), T.border),
      AppBadgeTone.onHero => (
          Colors.white,
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.28)
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: bc),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KARTU STATISTIK (StatCard)
// ═══════════════════════════════════════════════════════════════
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    this.tone = StatTone.slate,
    this.onTap,
  });

  final String label;
  final String value;
  final String note;
  final StatTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const map = {
      StatTone.slate: (T.text, T.card, T.border),
      StatTone.green: (T.green, T.greenBg, T.greenBorder),
      StatTone.amber: (T.amber, T.amberBg, T.amberBorder),
      StatTone.red: (T.red, T.redBg, T.redBorder),
      StatTone.blue: (T.blue, T.blueBg, T.blueBorder),
    };
    final (fg, bg, bc) = map[tone]!;

    final card = Container(
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(minHeight: 98),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: bc),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: T.textSecondary)),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: fg)),
          const SizedBox(height: 3),
          Text(note, style: const TextStyle(fontSize: 11, color: T.textMuted)),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.rLg),
      child: card,
    );
  }
}

enum StatTone { slate, green, amber, red, blue }

// ═══════════════════════════════════════════════════════════════
// JUDUL SEKSI
// ═══════════════════════════════════════════════════════════════
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: T.textSecondary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// KEPALA HALAMAN TURUNAN (judul + tombol kembali)
// ═══════════════════════════════════════════════════════════════
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          _IconAction(icon: Icons.arrow_back_rounded, onTap: onBack!),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: T.text)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!,
                    style: const TextStyle(fontSize: 12, color: T.textSecondary)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: T.card,
      borderRadius: BorderRadius.circular(T.rMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rMd),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: T.border),
          ),
          child: Icon(icon, size: 19, color: T.textSecondary),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BARIS INFO (label kiri — nilai kanan)
// ═══════════════════════════════════════════════════════════════
class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: T.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: T.text),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOAST — padanan komponen Toast prototipe (info/success/error)
// ═══════════════════════════════════════════════════════════════
enum ToastKind { info, success, error }

void showToast(BuildContext context, String text, ToastKind kind) {
  final (icon, bg, fg, bc) = switch (kind) {
    ToastKind.success => (
        Icons.check_circle_rounded,
        T.greenBg,
        T.green,
        T.greenBorder
      ),
    ToastKind.error => (Icons.cancel_rounded, T.redBg, T.red, T.redBorder),
    ToastKind.info => (Icons.info_rounded, T.blueBg, T.blue, T.blueBorder),
  };

  // Toast melayang di tengah bawah dengan lebar terbatas, seperti notifikasi
  // aplikasi web pada umumnya. Di layar sempit tetap memakai margin.
  final lebarLayar = MediaQuery.of(context).size.width;
  final melayang = lebarLayar > 640;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      elevation: 0,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      width: melayang ? 440 : null,
      margin: melayang ? null : const EdgeInsets.fromLTRB(12, 0, 12, 12),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(T.rMd),
          border: Border.all(color: bc),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// KARTU PUTIH DASAR
// ═══════════════════════════════════════════════════════════════
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: T.card,
        borderRadius: BorderRadius.circular(T.rLg),
        border: Border.all(color: T.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.rLg),
      child: card,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// AVATAR (foto profil atau inisial)
// ═══════════════════════════════════════════════════════════════

/// Avatar bulat: menampilkan foto profil bila tersedia, jika belum
/// menampilkan inisial nama seperti sebelumnya.
class AvatarFoto extends StatelessWidget {
  const AvatarFoto({
    super.key,
    required this.inisial,
    this.foto,
    this.size = 40,
    this.bg = T.blueBg,
    this.fg = T.accent,
    this.borderColor,
    this.borderWidth = 2,
  });

  final String inisial;
  final Uint8List? foto;
  final double size;
  final Color bg;
  final Color fg;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: foto == null
          ? Text(
              inisial,
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            )
          : Image.memory(
              foto!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // Avatar tidak perlu disaring ulang saat ukuran berubah.
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}

/// Avatar + lencana kamera kecil di kanan bawah, dipakai di halaman Profil
/// sebagai tombol "ganti foto".
class AvatarFotoBisaDiubah extends StatelessWidget {
  const AvatarFotoBisaDiubah({
    super.key,
    required this.inisial,
    required this.foto,
    required this.onTap,
    this.size = 84,
    this.bg = T.blueBg,
    this.fg = T.accent,
    this.borderColor,
  });

  final String inisial;
  final Uint8List? foto;
  final VoidCallback onTap;
  final double size;
  final Color bg;
  final Color fg;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ganti foto profil',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarFoto(
              inisial: inisial,
              foto: foto,
              size: size,
              bg: bg,
              fg: fg,
              borderColor: borderColor,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: T.accent,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.photo_camera_rounded,
                    size: size * 0.16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BANTUAN TATA LETAK WEB
// ═══════════════════════════════════════════════════════════════

/// Ambang lebar untuk tata letak web (sidebar + konten lebar).
const double lebarWeb = 1000;

/// Padding isi halaman: 16 px di layar sempit, 28 px di web.
EdgeInsets paddingHalaman(double lebar, {double bawah = 28}) {
  final samping = lebar >= lebarWeb ? 28.0 : 16.0;
  return EdgeInsets.fromLTRB(samping, 8, samping, bawah);
}
