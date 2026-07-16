import 'package:flutter/material.dart';

/// Shared visual constants reused across the app. Keeping the gradient
/// and the rounded card decoration in one place ensures the new
/// subscription screens match the look of the existing home / quiz
/// screens.
const LinearGradient appGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFFD9BEDC),
    Color(0xFFB086BC),
    Color(0xFF834FA0),
  ],
  stops: [0.0, 0.41, 0.82],
);

BoxDecoration cardDecoration({double radius = 32}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD9BEDC),
      Color(0xFFB086BC),
      Color(0xFF834FA0),
    ],
    stops: [1.0, 0.41, 0.0512],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(
    color: const Color(0xFFD9BEDC).withValues(alpha: 0.55),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF612A7E).withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ],
);

/// Background wrapper that paints [appGradient] behind its child and
/// keeps content inset by [SafeArea]. All new screens use this wrapper
/// so they share the existing theme without any visual redesign.
class AppBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const AppBackground({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: appGradient),
      child: SafeArea(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
