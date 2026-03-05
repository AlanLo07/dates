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
      print(response.body);
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
      final response = await http.put(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(lista.map((l) => l.toJson()).toList()),
      );
      if (response.statusCode != 200) {
        throw Exception('Fallo al sincronizar: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
