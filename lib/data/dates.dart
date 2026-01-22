// lib/data/important_dates_data.dart
import '../models/date.dart';

final Map<String, List<DateEvent>> kImportantDates = {
  // Ejemplo: Primer Aniversario (Asegúrate de cambiar las fechas al año actual)
  "12-18": [
    const DateEvent(
      'Aniversario: Un año juntos',
      '¡Celebramos 365 días de risas, aventuras y mucho amor! Por muchos más.',
      'assets/novios.jpeg', // Debe existir en tu carpeta assets
    ),
  ],
  // Ejemplo: Primer beso
  "11-28": [
    const DateEvent(
      'Primera Cita',
      'El día en que el mundo se detuvo por primera vez. Un recuerdo precioso.',
      'assets/beso.jpeg',
    ),
  ],
  // Ejemplo: Cumpleaños de tu Novia
  "10-17": [
    const DateEvent(
      '¡Feliz Cumpleaños, Amor!',
      'El día más importante del año, celebramos tu vida. ¡Te amo!',
      'assets/nati.jpeg',
    ),
  ],
};
