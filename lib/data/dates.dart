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
      '¡Feliz Cumpleaños, Nati!',
      'El día más importante del año, celebramos tu vida. ¡Te amo!',
      'assets/nati.jpeg',
    ),
  ],
  "10-24": [
    const DateEvent(
      '¡Feliz Cumpleaños, Alan!',
      'Me debes un regalo',
      'assets/alan.jpeg',
    ),
  ],
  "04-08": [
    const DateEvent(
      'Primera vez en tu lugar seguro',
      'Fuimos por primera vez a tu lugar seguro',
      'assets/lugarSeguro.jpeg',
    ),
  ],
  "04-20": [
    const DateEvent(
      'Primera vez que fuiste a Tepa y tocaste una vaquita',
      'Fuimos por primera vez a tocar una vaquita y que conocieras mi lugar seguro',
      'assets/tepa.jpeg',
    ),
  ],
  "09-07": [
    const DateEvent(
      'Primera vez en un viaje juntos',
      'Fuimos de viaje solos tu y yo. Fuimos a Real del monte',
      'assets/viaje.jpeg',
    ),
  ],
  "11-22": [
    const DateEvent(
      'Primera vez en una boda juntos',
      'Fuimos por primera vez a un boda juntos, esperando que sea la nuestra',
      'assets/boda.jpeg',
    ),
  ],
  "05-16": [
    const DateEvent(
      'Primera vez que fuimos a un viaje por toda una semana',
      'Fuimos por primera vez de viaje, a Nayarit, a la playa y pasando por el Zoologico de Guadalajara',
      'assets/playa.jpeg',
    ),
  ],
  "06-20": [
    const DateEvent(
      'Primera vez en Monterrey',
      'Fuimos por primera vez a monterrey y a conocer el horno 3',
      'assets/monterrey.jpeg',
    ),
  ],
  "09-05": [
    const DateEvent(
      'Primera vez que vimos a Imagine Dragons',
      'Viomos a los dragones imaginarios en vivo',
      'assets/ID.jpeg',
    ),
  ],
  "11-15": [
    const DateEvent(
      'Primera vez en el festival del globo',
      'Fuimos por priemra vez al festival del globo y maldijimos al MArtino',
      'assets/globo.jpeg',
    ),
  ],
  "12-21": [
    const DateEvent(
      'Primera vez eque vimos una cascada juntos',
      'Fuimos a Zacatlan de las manzanas y nos sorprendio mucho sus cascadas',
      'assets/cascada.jpeg',
    ),
  ],
};
