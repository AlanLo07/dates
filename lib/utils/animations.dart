import 'package:flutter/material.dart';

class MotionDurations {
  MotionDurations._();

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 360);
  static const Duration long = Duration(milliseconds: 520);
  static const Duration route = Duration(milliseconds: 540);
}

class MotionCurves {
  MotionCurves._();

  static const Curve entrance = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;
  static const Curve spring = Curves.elasticOut;
}

enum AppRouteMotion { slide, fade, sharedAxisX }

Route createRoute(
  Widget targetScreen, {
  AppRouteMotion motion = AppRouteMotion.slide,
}) {
  return PageRouteBuilder(
    transitionDuration: MotionDurations.route,
    reverseTransitionDuration: const Duration(milliseconds: 430),
    pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: MotionCurves.entrance,
        reverseCurve: MotionCurves.exit,
      );

      switch (motion) {
        case AppRouteMotion.fade:
          return FadeTransition(opacity: curved, child: child);
        case AppRouteMotion.sharedAxisX:
          final slide = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: MotionCurves.entrance));
          final scale = Tween<double>(
            begin: 0.96,
            end: 1,
          ).chain(CurveTween(curve: MotionCurves.entrance));
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: animation.drive(slide),
              child: ScaleTransition(scale: animation.drive(scale), child: child),
            ),
          );
        case AppRouteMotion.slide:
          final slide = Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: MotionCurves.entrance));
          return SlideTransition(position: animation.drive(slide), child: child);
      }
    },
  );
}
