import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/boda.dart';
import 'api_config.dart';

class WeddingMeta {
  final String id;
  final String nombre;
  final String? mensajeBienvenida;
  final String? lugar;
  final String? fechaEvento;
  final String? direccion;
  final String? contacto;
  final String? dressCode;
  final String? instagramHashtag;

  const WeddingMeta({
    required this.id,
    required this.nombre,
    this.mensajeBienvenida,
    this.lugar,
    this.fechaEvento,
    this.direccion,
    this.contacto,
    this.dressCode,
    this.instagramHashtag,
  });

  factory WeddingMeta.fromJson(Map<String, dynamic> json) {
    return WeddingMeta(
      id: (json['id'] ?? json['bodaId'] ?? '').toString(),
      nombre: (json['nombre'] ?? 'Nuestra boda').toString(),
      mensajeBienvenida: json['mensajeBienvenida']?.toString(),
      lugar: json['lugar']?.toString(),
      fechaEvento: json['fechaEvento']?.toString(),
      direccion: json['direccion']?.toString(),
      contacto: json['contacto']?.toString(),
      dressCode: json['dressCode']?.toString(),
      instagramHashtag: json['instagramHashtag']?.toString(),
    );
  }
}

class WeddingService {
  static final WeddingService _instance = WeddingService._internal();
  factory WeddingService() => _instance;
  WeddingService._internal();

  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  String get _base => ApiConfig.baseUrl.endsWith('/')
      ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
      : ApiConfig.baseUrl;

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<WeddingMeta?> getPrimaryWedding() async {
    final response = await http
        .get(_uri('/bodas'))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al obtener boda: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    final items = _extractItems(decoded);
    if (items.isEmpty) return null;
    return WeddingMeta.fromJson(items.first);
  }

  Future<List<Invitado>> getInvitados(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/invitados');
    return items.map(Invitado.fromJson).toList();
  }

  Future<Invitado> createInvitado(String bodaId, Invitado invitado) async {
    final map = await _post(
      '/bodas/$bodaId/invitados',
      body: {
        'nombre': invitado.nombre,
        'grupo': invitado.grupo,
        'personas': invitado.personas,
        'rsvp': invitado.rsvp.name,
      },
    );
    return Invitado.fromJson(map);
  }

  Future<Invitado> updateInvitado(String bodaId, Invitado invitado) async {
    final map = await _put(
      '/bodas/$bodaId/invitados/${invitado.id}',
      body: {
        'nombre': invitado.nombre,
        'grupo': invitado.grupo,
        'personas': invitado.personas,
      },
    );
    return Invitado.fromJson(map);
  }

  Future<void> updateInvitadoRsvp(
    String bodaId,
    String itemId,
    RsvpStatus rsvp,
  ) async {
    await _patch(
      '/bodas/$bodaId/invitados/$itemId/rsvp',
      body: {'rsvp': rsvp.name},
    );
  }

  Future<List<TareaBoda>> getTareas(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/tareas');
    return items.map(TareaBoda.fromJson).toList();
  }

  Future<TareaBoda> createTarea(String bodaId, TareaBoda tarea) async {
    final map = await _post(
      '/bodas/$bodaId/tareas',
      body: {
        'titulo': tarea.titulo,
        'categoria': tarea.categoria,
        'completada': tarea.completada,
        'fechaLimite': tarea.fechaLimite,
      },
    );
    return TareaBoda.fromJson(map);
  }

  Future<TareaBoda> updateTarea(String bodaId, TareaBoda tarea) async {
    final map = await _put(
      '/bodas/$bodaId/tareas/${tarea.id}',
      body: {
        'titulo': tarea.titulo,
        'categoria': tarea.categoria,
        'completada': tarea.completada,
        'fechaLimite': tarea.fechaLimite,
      },
    );
    return TareaBoda.fromJson(map);
  }

  Future<List<PasoBoda>> getItinerario(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/itinerario');
    return items.map(PasoBoda.fromJson).toList();
  }

  Future<PasoBoda> createPaso(String bodaId, PasoBoda paso) async {
    final map = await _post(
      '/bodas/$bodaId/itinerario',
      body: {
        'titulo': paso.titulo,
        'hora': paso.hora,
        'nota': paso.nota,
        'emoji': paso.emoji,
      },
    );
    return PasoBoda.fromJson(map);
  }

  Future<List<GastoBoda>> getGastos(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/gastos');
    return items.map(GastoBoda.fromJson).toList();
  }

  Future<GastoBoda> createGasto(String bodaId, GastoBoda gasto) async {
    final map = await _post(
      '/bodas/$bodaId/gastos',
      body: {
        'concepto': gasto.concepto,
        'categoria': gasto.categoria,
        'estimado': gasto.estimado,
        'pagado': gasto.pagado,
      },
    );
    return GastoBoda.fromJson(map);
  }

  Future<GastoBoda> updateGasto(String bodaId, GastoBoda gasto) async {
    final map = await _put(
      '/bodas/$bodaId/gastos/${gasto.id}',
      body: {
        'concepto': gasto.concepto,
        'categoria': gasto.categoria,
        'estimado': gasto.estimado,
        'pagado': gasto.pagado,
      },
    );
    return GastoBoda.fromJson(map);
  }

  Future<List<CancionBoda>> getCanciones(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/canciones');
    return items.map(CancionBoda.fromJson).toList();
  }

  Future<CancionBoda> createCancion(String bodaId, CancionBoda cancion) async {
    final map = await _post(
      '/bodas/$bodaId/canciones',
      body: {
        'titulo': cancion.titulo,
        'artista': cancion.artista,
        'momento': cancion.momento,
        'link': cancion.link,
      },
    );
    return CancionBoda.fromJson(map);
  }

  Future<List<ProveedorBoda>> getProveedores(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/proveedores');
    return items.map(ProveedorBoda.fromJson).toList();
  }

  Future<ProveedorBoda> createProveedor(
    String bodaId,
    ProveedorBoda proveedor,
  ) async {
    final map = await _post(
      '/bodas/$bodaId/proveedores',
      body: {
        'nombre': proveedor.nombre,
        'categoria': proveedor.categoria,
        'contacto': proveedor.contacto,
        'link': proveedor.link,
        'costo': proveedor.costo,
        'estado': proveedor.estado.name,
        'notas': proveedor.notas,
      },
    );
    return ProveedorBoda.fromJson(map);
  }

  Future<ProveedorBoda> updateProveedor(
    String bodaId,
    ProveedorBoda proveedor,
  ) async {
    final map = await _put(
      '/bodas/$bodaId/proveedores/${proveedor.id}',
      body: {
        'nombre': proveedor.nombre,
        'categoria': proveedor.categoria,
        'contacto': proveedor.contacto,
        'link': proveedor.link,
        'costo': proveedor.costo,
        'estado': proveedor.estado.name,
        'notas': proveedor.notas,
      },
    );
    return ProveedorBoda.fromJson(map);
  }

  Future<List<LookBoda>> getLooks(String bodaId) async {
    final items = await _getItems('/bodas/$bodaId/looks');
    return items.map(LookBoda.fromJson).toList();
  }

  Future<LookBoda> createLook(String bodaId, LookBoda look) async {
    final map = await _post(
      '/bodas/$bodaId/looks',
      body: {
        'persona': look.persona,
        'prenda': look.prenda,
        'tienda': look.tienda,
        'talla': look.talla,
        'precio': look.precio,
        'comprado': look.comprado,
        'notas': look.notas,
      },
    );
    return LookBoda.fromJson(map);
  }

  Future<LookBoda> updateLook(String bodaId, LookBoda look) async {
    final map = await _put(
      '/bodas/$bodaId/looks/${look.id}',
      body: {
        'persona': look.persona,
        'prenda': look.prenda,
        'tienda': look.tienda,
        'talla': look.talla,
        'precio': look.precio,
        'comprado': look.comprado,
        'notas': look.notas,
      },
    );
    return LookBoda.fromJson(map);
  }

  Future<List<Map<String, dynamic>>> _getItems(String path) async {
    final response = await http
        .get(_uri(path))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al consultar $path: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    return _extractItems(decoded);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al crear en $path: ${response.statusCode} - ${response.body}',
      );
    }

    return _extractSingleItem(response.body);
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al actualizar en $path: ${response.statusCode} - ${response.body}',
      );
    }

    return _extractSingleItem(response.body);
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http
        .patch(_uri(path), headers: _jsonHeaders, body: jsonEncode(body))
        .timeout(const Duration(seconds: 12));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al actualizar en $path: ${response.statusCode} - ${response.body}',
      );
    }

    return _extractSingleItem(response.body);
  }

  Map<String, dynamic> _extractSingleItem(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    final decoded = json.decode(body);

    if (decoded is Map<String, dynamic>) {
      final item = decoded['item'];
      if (item is Map<String, dynamic>) return item;
      return decoded;
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractItems(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final rawItems = decoded['items'];
      if (rawItems is List) {
        return rawItems
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [decoded];
    }

    return const [];
  }
}
