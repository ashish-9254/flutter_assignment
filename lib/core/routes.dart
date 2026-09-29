import 'package:flutter/material.dart';

/// Cross-fade between two screens. Used for splash -> next screen, login ->
/// app shell, and feed -> photo detail (the Hero flies during this fade).
Route<T> fadeRoute<T>(
    Widget page, {
      Duration duration = const Duration(milliseconds: 350),
    }) {
  return PageRouteBuilder<T>(
    opaque: true,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
        child: child,
      );
    },
  );
}

/// Gentle slide-in from the right combined with a fade. Used between the
/// login and signup screens.
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.08, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(slide),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}