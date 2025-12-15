import 'package:flutter/material.dart';

Route createRoute(Widget targetScreen) {
  return PageRouteBuilder(
    // 1. Duración de la animación
    transitionDuration: const Duration(milliseconds: 700),
    // 2. La pantalla a la que navegamos
    pageBuilder: (context, animation, secondaryAnimation) => targetScreen,

    // 3. El constructor de la transición (ejemplo: Deslizamiento o Fade)
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // --- Opción A: Deslizamiento (Slide Transition) ---
      // Hace que la nueva pantalla se deslice desde la derecha (puedes cambiarlo)
      const begin = Offset(
        1.0,
        0.0,
      ); // Inicia fuera de la pantalla a la derecha
      const end = Offset.zero; // Termina en la posición normal (cero)
      const curve = Curves.easeOutCubic; // Define la aceleración

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(position: animation.drive(tween), child: child);

      // --- Opción B: Desvanecimiento (Fade Transition) ---
      /*
      return FadeTransition(
        opacity: animation,
        child: child,
      );
      */
    },
  );
}
