// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita.dart';

class ApiService {
  // Reemplaza con la URL de tu API Gateway
  final String url =
      'https://4gwpsw5bk6xxkxv4bdnuvvbnve0kgjfx.lambda-url.us-east-2.on.aws/';

  Future<List<Cita>> getCitas() async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Si el servidor devuelve una respuesta OK, parseamos el JSON
        List<dynamic> body = json.decode(response.body);
        return body.map((dynamic item) => Cita.fromJson(item)).toList();
      } else {
        throw Exception('Error al cargar las citas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor: $e');
    }
  }

  Future<void> syncLugares(List<Cita> lista) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(lista.map((l) => l.toJson()).toList()),
      );

      if (response.statusCode != 200) {
        throw Exception('Fallo al sincronizar: ${response.statusCode}');
      }
      print("Sincronización exitosa con la nube");
    } catch (e) {
      print("Error de red: $e");
      rethrow; // Re-lanzamos el error para manejarlo en la UI si es necesario
    }
  }
}
