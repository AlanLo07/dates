class EventoImportante {
  final String nombre;
  final String fecha; // Formato "dd-mm-yyyy"

  EventoImportante({required this.nombre, required this.fecha});
}

// Tu lista de eventos
List<EventoImportante> misEventos = [
  EventoImportante(nombre: "San Luis Potosi", fecha: "15-03-2026"),
];