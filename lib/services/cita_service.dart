// lib/services/cita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita.dart';
import 'api_config.dart';

class ApiService {
  final String _urlCitas = ApiConfig.baseUrl + ApiConfig.citasPath;
  final String _urlEventos = ApiConfig.baseUrl + ApiConfig.eventosPath;

  Future<List<Cita>> getCitas() async {
    try {
      final response = await http.get(Uri.parse(_urlCitas));
      if (response.statusCode == 200) {
        Map<String, dynamic> body = json.decode(response.body);
        List<dynamic> items = body['items'];
        return items.map((item) => Cita.fromJson(item)).toList();
      } else {
        throw Exception('Error al cargar las citas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('No se pudo conectar con el servidor: $e');
    }
  }

  Future<void> syncLugares(List<Cita> lista) async {
    try {
      for (final cita in lista) {
        final url =
            '${ApiConfig.baseUrl}${ApiConfig.citasPath}/${cita.nombre}'; // 👈 id en el path

        final response = await http.put(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(cita.toJson()),
        );

        if (response.statusCode != 200) {
          throw Exception(
            'Fallo al sincronizar ${cita.nombre}: ${response.statusCode}',
          );
        }
      }
      print("Sincronización exitosa con la nube");
    } catch (e) {
      rethrow;
    }
  }

  /// Agenda una cita enviando su data + la fecha seleccionada al backend.
  /// El backend debe tener un endpoint POST /citas o similar.
  Future<void> agendarCita({
    required Cita cita,
    required String fecha, // Formato "dd-MM-yyyy"
  }) async {
    try {
      final body = {
        'type': 'evento',
        'title': cita.nombre,
        'date': fecha, // Campo extra para la fecha programada
        'description': cita.descripcion,
        'icon': 'backpack_outlined',
      };

      final response = await http.post(
        Uri.parse(_urlEventos),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al agendar la cita: ${response.statusCode}');
      }
      print("Cita agendada exitosamente para $fecha");
    } catch (e) {
      print("Error al agendar: $e");
      rethrow;
    }
  }
}
