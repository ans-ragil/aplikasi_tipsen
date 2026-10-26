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

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 3),
      elevation: 6,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      content: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
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
