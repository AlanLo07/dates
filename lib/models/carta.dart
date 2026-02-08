class CartaSorpresa {
  final String fechaLiberacion; // "dd-mm-yyyy"
  final String titulo;
  final String mensaje;
  bool abierta;

  CartaSorpresa({
    required this.fechaLiberacion,
    required this.titulo,
    required this.mensaje,
    this.abierta = false,
  });
}

// Ejemplo de tu lista
List<CartaSorpresa> misCartas = [
  CartaSorpresa(
    fechaLiberacion: "14-02-2026", 
    titulo: "Para mi San Valentín",
    mensaje: "Eres lo mejor que me ha pasado..."
  ),
];