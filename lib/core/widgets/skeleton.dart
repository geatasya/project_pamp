import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder berkedip saat data sedang dimuat.
class Skeleton extends StatefulWidget {
  final double radius;
  const Skeleton({super.key, this.radius = 24});
  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1000))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFEDEEF4), const Color(0xFFE1E3EC), _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
