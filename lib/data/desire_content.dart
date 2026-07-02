// lib/data/desire_content.dart
import 'package:flutter/material.dart';

enum DesireLevel { suave, picante, atrevido }

extension DesireLevelX on DesireLevel {
  String get label {
    switch (this) {
      case DesireLevel.suave:
        return 'Suave';
      case DesireLevel.picante:
        return 'Picante';
      case DesireLevel.atrevido:
        return 'Atrevido';
    }
  }

  String get emoji {
    switch (this) {
      case DesireLevel.suave:
        return '🌸';
      case DesireLevel.picante:
        return '🌶️';
      case DesireLevel.atrevido:
        return '🔥';
    }
  }

  Color get color {
    switch (this) {
      case DesireLevel.suave:
        return const Color(0xFFA9D1DF); // celeste
      case DesireLevel.picante:
        return const Color(0xFFF48FB1); // rosa
      case DesireLevel.atrevido:
        return const Color(0xFFE53935); // rojo intenso
    }
  }

  Color get bg {
    switch (this) {
      case DesireLevel.suave:
        return const Color(0xFFE3F2FD);
      case DesireLevel.picante:
        return const Color(0xFFFCE4EC);
      case DesireLevel.atrevido:
        return const Color(0xFFFBE9E7);
    }
  }
}

class DiceEntry {
  final String text;
  final DesireLevel level;
  const DiceEntry(this.text, this.level);
}

class ChallengeItem {
  final String text;
  final DesireLevel level;
  final String emoji;
  const ChallengeItem(this.text, this.level, {this.emoji = '💜'});
}

// ── DADO 1: ACCIONES ─────────────────────────────────────────────────────
const List<DiceEntry> kAcciones = [
  DiceEntry('Besa', DesireLevel.suave),
  DiceEntry('Abraza por detrás a', DesireLevel.suave),
  DiceEntry('Acaricia el cabello de', DesireLevel.suave),
  DiceEntry('Susurra un cumplido a', DesireLevel.suave),
  DiceEntry('Toma de la mano y mira fijamente a', DesireLevel.suave),
  DiceEntry('Da pequeños besos por todo', DesireLevel.picante),
  DiceEntry('Muerde suavemente', DesireLevel.picante),
  DiceEntry('Lame lentamente', DesireLevel.picante),
  DiceEntry('Sopla suavemente sobre', DesireLevel.picante),
  DiceEntry('Recorre con los dedos', DesireLevel.picante),
  DiceEntry('Susurra algo atrevido al oído mientras tocas', DesireLevel.picante),
  DiceEntry('Desabotona lentamente mientras besas', DesireLevel.picante),
  DiceEntry('Chupa suavemente', DesireLevel.atrevido),
  DiceEntry('Presiona todo tu cuerpo contra', DesireLevel.atrevido),
  DiceEntry('Recorre con la lengua', DesireLevel.atrevido),
  DiceEntry('Masajea con aceite', DesireLevel.atrevido),
  DiceEntry('Muerde con más intensidad', DesireLevel.atrevido),
  DiceEntry('Sostén contra la pared y besa', DesireLevel.atrevido),
];

// ── DADO 2: ZONAS ─────────────────────────────────────────────────────────
const List<DiceEntry> kZonas = [
  DiceEntry('la frente', DesireLevel.suave),
  DiceEntry('las manos', DesireLevel.suave),
  DiceEntry('las mejillas', DesireLevel.suave),
  DiceEntry('el cabello', DesireLevel.suave),
  DiceEntry('los hombros', DesireLevel.suave),
  DiceEntry('el cuello', DesireLevel.picante),
  DiceEntry('las orejas', DesireLevel.picante),
  DiceEntry('la clavícula', DesireLevel.picante),
  DiceEntry('la espalda', DesireLevel.picante),
  DiceEntry('la nuca', DesireLevel.picante),
  DiceEntry('los labios', DesireLevel.picante),
  DiceEntry('el pecho', DesireLevel.atrevido),
  DiceEntry('el vientre bajo', DesireLevel.atrevido),
  DiceEntry('los muslos internos', DesireLevel.atrevido),
  DiceEntry('la zona lumbar', DesireLevel.atrevido),
  DiceEntry('los glúteos', DesireLevel.atrevido),
];

// ── DADO 3: MODIFICADORES ────────────────────────────────────────────────
const List<DiceEntry> kModificadores = [
  DiceEntry('con mucha ternura', DesireLevel.suave),
  DiceEntry('mirándose a los ojos', DesireLevel.suave),
  DiceEntry('con una sonrisa pícara', DesireLevel.suave),
  DiceEntry('muy despacio', DesireLevel.suave),
  DiceEntry('por 20 segundos sin parar', DesireLevel.suave),
  DiceEntry('con los ojos cerrados', DesireLevel.picante),
  DiceEntry('susurrando algo al oído', DesireLevel.picante),
  DiceEntry('en la oscuridad', DesireLevel.picante),
  DiceEntry('mientras suena su canción favorita', DesireLevel.picante),
  DiceEntry('sin usar las manos', DesireLevel.atrevido),
  DiceEntry('con un cubo de hielo', DesireLevel.atrevido),
  DiceEntry('solo con los labios', DesireLevel.atrevido),
  DiceEntry('hasta que pidan una pausa', DesireLevel.atrevido),
  DiceEntry('con las manos atadas (con algo suave)', DesireLevel.atrevido),
];

// ── RETOS DE LA RULETA ───────────────────────────────────────────────────
const List<ChallengeItem> kChallenges = [
  ChallengeItem('Denle un masaje de manos por 3 minutos, sin hablar',
      DesireLevel.suave, emoji: '🤲'),
  ChallengeItem('Compartan su fantasía favorita (la más inocente)',
      DesireLevel.suave, emoji: '💭'),
  ChallengeItem('Bailen lento abrazados una canción especial',
      DesireLevel.suave, emoji: '💃'),
  ChallengeItem('Denle 10 besos en lugares distintos (nada íntimo)',
      DesireLevel.suave, emoji: '💋'),
  ChallengeItem('Escriban una nota de amor y léanla en voz alta',
      DesireLevel.suave, emoji: '💌'),
  ChallengeItem('Miren a los ojos a su pareja 60 segundos sin reír',
      DesireLevel.suave, emoji: '👀'),
  ChallengeItem('Denle un masaje con aceite por 5 minutos',
      DesireLevel.picante, emoji: '🧴'),
  ChallengeItem('Besen cada centímetro del cuello del otro',
      DesireLevel.picante, emoji: '💜'),
  ChallengeItem('Juego de prendas: quien pierda se quita una',
      DesireLevel.picante, emoji: '👕'),
  ChallengeItem('Denle 20 besos por todo el cuerpo, sin quitar ropa',
      DesireLevel.picante, emoji: '💋'),
  ChallengeItem('Cuéntense su fantasía más atrevida al oído',
      DesireLevel.picante, emoji: '🤫'),
  ChallengeItem('Un striptease lento al ritmo de su canción favorita',
      DesireLevel.picante, emoji: '🎵'),
  ChallengeItem('5 minutos de caricias con los ojos vendados',
      DesireLevel.atrevido, emoji: '🙈'),
  ChallengeItem('Recreen su primera cita romántica, en la cama',
      DesireLevel.atrevido, emoji: '🔥'),
  ChallengeItem('El ganador elige una posición del Kamasutra para probar',
      DesireLevel.atrevido, emoji: '🃏'),
  ChallengeItem('Jueguen con hielo por todo el cuerpo del otro',
      DesireLevel.atrevido, emoji: '🧊'),
  ChallengeItem('Denle órdenes por 5 minutos (dentro de lo acordado)',
      DesireLevel.atrevido, emoji: '👑'),
  ChallengeItem('Apaguen la luz y exploren solo con las manos',
      DesireLevel.atrevido, emoji: '🌙'),
];