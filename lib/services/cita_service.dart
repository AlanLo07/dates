// lib/services/cita_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita.dart';
import 'api_config.dart';

class ApiService {
  final String _url = ApiConfig.baseUrl + ApiConfig.citasPath;

  Future<List<Cita>> getCitas() async {
    try {
      final response = await http.get(Uri.parse(_url));
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
}
