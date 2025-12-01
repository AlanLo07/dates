class Cita {
  final String nombre;
  final String descripcion;
  final String categoria; // Ejemplo: 'Romántico', 'Aventura', 'Relajante'
  final String presupuesto; // Ejemplo: 'Bajo', 'Medio', 'Alto'
  final int tiempo; // Tiempo estimado en horas
  final String link; // Enlace a Google Maps o a una web

  Cita({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.presupuesto,
    required this.tiempo,
    required this.link,
  });
}
