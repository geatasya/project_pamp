import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? bg;
  final Color? fg;
  final double size;
  final String? tooltip;
  final bool bordered;
  const RoundIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.bg,
    this.fg,
    this.size = 44,
    this.tooltip,
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: bg ?? Colors.white,
      shape: CircleBorder(
          side: bordered
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.46, color: fg ?? AppColors.ink),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final Color? dot;
  final Color? borderColor;
  final double fontSize;
  final EdgeInsets padding;
  const Pill(
    this.text, {
    super.key,
    this.icon,
    this.bg = AppColors.subtle,
    this.fg = AppColors.ink,
    this.dot,
    this.borderColor,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SoftCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  const IconTile({
    super.key,
    required this.icon,
    this.color = AppColors.ink,
    this.bg = AppColors.subtle,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class InitialAvatar extends StatelessWidget {
  final String text;
  final double size;
  const InitialAvatar({super.key, required this.text, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final t = text.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Center(
        child: Text(
          t.isEmpty ? '?' : t[0].toUpperCase(),
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.42),
        ),
      ),
    );
  }
}

class CapsLabel extends StatelessWidget {
  final String text;
  const CapsLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
            color: AppColors.muted),
      );
}
