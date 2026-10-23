import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Logo lengkap Event-Tix (gambar asli).
class AppLogo extends StatelessWidget {
  final double size;
  final double radius;
  const AppLogo({super.key, this.size = 96, this.radius = 26});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(size, radius),
      ),
    );
  }
}

/// Ikon tiket saja (untuk header kecil).
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.asset(
        'assets/images/logo_mark.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(size, size * 0.3),
      ),
    );
  }
}

Widget _fallback(double size, double radius) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: AppColors.ink, borderRadius: BorderRadius.circular(radius)),
      child: Icon(Icons.confirmation_number_rounded,
          color: Colors.white, size: size * 0.5),
    );

/// Tulisan "Event-Tix" dengan "Tix" berwarna ungu.
class BrandText extends StatelessWidget {
  final double fontSize;
  const BrandText({super.key, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
            fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.1),
        children: const [
          TextSpan(text: 'Event-'),
          TextSpan(text: 'Tix', style: TextStyle(color: AppColors.purple)),
        ],
      ),
    );
  }
}
