import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTheme {
  static const Color _darkBase     = Color(0xFF0D0D1A);
  static const Color _accentPurple = Color(0xFF7B61FF);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBase,
      colorScheme: const ColorScheme.dark(
        primary: _accentPurple,
        surface: Color(0xFF1A1A2E),
      ),
    );
  }
}

// ---- Widget Glass reutilizable ----
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color tint;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.tint = const Color(0x22FFFFFF),
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(24);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: br,
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
