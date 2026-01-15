// lib/services/cita_service.dart
import 'dart:convert'; // Necesario para codificar y decodificar JSON
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cita.dart';
import '../data/planes.dart';

// Clave para guardar y cargar los datos
const String _citasKey = 'custom_citas_list';

// La lista principal de citas. Inicializada con las citas por defecto.
List<Cita> planesDeCitas = [...planesDisponibles];

// ==========================================================
// A. PERSISTENCIA (GUARDAR Y CARGAR)
// ==========================================================

// Función para guardar la lista completa de citas en el dispositivo
Future<void> saveCitas() async {
  final prefs = await SharedPreferences.getInstance();

  // 1. Convertir la lista de objetos Cita a una lista de mapas JSON.
  final jsonList = planesDeCitas.map((cita) => cita.toJson()).toList();

  // 2. Convertir la lista de mapas en una sola cadena JSON.
  final jsonString = json.encode(jsonList);

  // 3. Guardar la cadena en shared_preferences.
  await prefs.setString(_citasKey, jsonString);
}

// Función para cargar las citas guardadas
Future<void> loadCitas() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString(_citasKey);

  if (jsonString != null) {
    // 1. Decodificar la cadena JSON a una lista de mapas.
    final jsonList = json.decode(jsonString) as List;

    // 2. Convertir la lista de mapas de vuelta a objetos Cita.
    final loadedCitas = jsonList.map((item) => Cita.fromJson(item)).toList();

    // 3. Si se cargaron citas, reemplazamos la lista global.
    // De lo contrario, mantenemos la lista inicial (planesDisponibles).
    if (loadedCitas.isNotEmpty) {
      planesDeCitas = loadedCitas;
    }
  }
}

// ==========================================================
// B. FUNCIÓN DE AÑADIR (QUE AHORA TAMBIÉN GUARDA)
// ==========================================================

void agregarNuevaCita(Cita nuevaCita) {
  // 1. Añadir la cita a la lista en memoria
  planesDeCitas.add(nuevaCita);

  // 2. ¡GUARDAR LOS CAMBIOS EN EL DISPOSITIVO!
  saveCitas();
}

List<Cita> listaLugares = planesDisponibles;

const String _lugaresKey = 'lugares_checklist';

Future<void> saveLugares() async {
  final prefs = await SharedPreferences.getInstance();
  final String encoded = json.encode(
    listaLugares.map((l) => l.toJson()).toList(),
  );
  await prefs.setString(_lugaresKey, encoded);
}

Future<void> loadLugares() async {
  final prefs = await SharedPreferences.getInstance();
  final String? encoded = prefs.getString(_lugaresKey);
  if (encoded != null) {
    final List<dynamic> decoded = json.decode(encoded);
    listaLugares = decoded.map((item) => Cita.fromJson(item)).toList();
  }
}
