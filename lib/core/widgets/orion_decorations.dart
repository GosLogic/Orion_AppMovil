import 'package:flutter/material.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/core/widgets/orion_logo.dart';

/// Fondo con gradiente suave para pantallas de auth.
class OrionHeroBackground extends StatelessWidget {
  const OrionHeroBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: OrionColors.heroGradient),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OrionColors.primary.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OrionColors.accent.withValues(alpha: 0.08),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Tarjeta elevada con borde sutil.
class OrionSurfaceCard extends StatelessWidget {
  const OrionSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: OrionColors.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Header del drawer con gradiente de marca.
class OrionDrawerHeader extends StatelessWidget {
  const OrionDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: const BoxDecoration(gradient: OrionColors.primaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OrionLogoMark(size: 56),
          const SizedBox(height: 16),
          Text(
            'Orion Driver',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gestión de flota inteligente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }
}

/// Scaffold con AppBar en gradiente Orion (pantallas secundarias).
class OrionPageScaffold extends StatelessWidget {
  const OrionPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OrionColors.background,
      appBar: AppBar(
        title: Text(title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: OrionColors.primaryGradient),
        ),
        actions: actions,
        bottom: bottom,
      ),
      body: body,
    );
  }
}

/// Barra inferior fija para acciones principales.
class OrionBottomActionBar extends StatelessWidget {
  const OrionBottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: OrionColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// Fila de detalle etiqueta / valor.
class OrionDetailRow extends StatelessWidget {
  const OrionDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: OrionColors.primaryLight),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                ),
          ),
        ),
      ],
    );
  }
}
