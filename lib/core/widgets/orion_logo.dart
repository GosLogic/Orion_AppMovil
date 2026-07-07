import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';

/// Logo de marca Orion Driver (imagen o fallback vectorial).
class OrionLogo extends StatelessWidget {
  const OrionLogo({
    super.key,
    this.size = 120,
    this.showShadow = true,
    this.borderRadius = 28,
  });

  final double size;
  final bool showShadow;
  final double borderRadius;

  static const _assetPath = 'assets/images/orion_logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: OrionColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: OrionColors.accent.withValues(alpha: 0.15),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          _assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackLogo(borderRadius: borderRadius),
        ),
      ),
    );
  }
}

class OrionLogoMark extends StatelessWidget {
  const OrionLogoMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        OrionLogo._assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: OrionColors.primaryGradient,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.borderRadius});

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: OrionColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(
          Icons.local_shipping_rounded,
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }
}
