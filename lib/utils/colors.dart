import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
// Paleta central de la app — importa SOLO desde aquí.
// Nunca definas estos colores inline en otros archivos.
// ─────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._(); // No instanciable

  static const Color violeta = Color(0xFF796B9B);
  static const Color lavanda = Color(0xFFD8C9E7);
  static const Color celeste = Color(0xFFA9D1DF);
  static const Color malva = Color(0xFFB0B6E8);
  static const Color grisCalido = Color(0xFFF0F0F0);

  // Alias semánticos (facilitan cambio de tema futuro)
  static const Color primary = violeta;
  static const Color background = lavanda;
  static const Color accent = celeste;
  static const Color secondary = malva;
  static const Color surface = Colors.white;

  // Estados
  static const Color error = Color(0xFFE57373);
  static const Color success = Color(0xFF81C784);
  static const Color locked = Colors.grey;
  static const Color unlocked = Colors.pinkAccent;

  // Fondo especial de cartas
  static const Color letterBg = Color(0xFFFDEEF4);
}
