// lib/services/upload_service.dart
//
// Compatible con Flutter Web y movil (iOS/Android).
// - Web: usa package:web + dart:js_interop.
// - Movil: usa image_picker para imagenes.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'upload_service_web.dart'
    if (dart.library.io) 'upload_service_mobile.dart' as platform;

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final String _uploadEndpoint = '${ApiConfig.baseUrl}${ApiConfig.uploadPath}';

  /// Abre el selector de imagen segun la plataforma y sube a S3.
  /// Devuelve la URL publica, o null si el usuario cancelo.
  Future<String?> pickAndUpload() {
    return _pickAndUpload(
      picker: platform.pickImage,
      mediaLabel: 'imagen',
      uploadPrefix: 'cita',
      defaultExtension: '.jpg',
      contentTypes: const {
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.webp': 'image/webp',
        '.heic': 'image/heic',
        '.gif': 'image/gif',
      },
    );
  }

  /// Abre el selector de audio segun la plataforma y sube a S3.
  /// Devuelve la URL publica, o null si el usuario cancelo.
  Future<String?> pickAndUploadAudio() {
    return _pickAndUpload(
      picker: platform.pickAudio,
      mediaLabel: 'audio',
      uploadPrefix: 'carta_audio',
      defaultExtension: '.mp3',
      contentTypes: const {
        '.aac': 'audio/aac',
        '.m4a': 'audio/mp4',
        '.mp3': 'audio/mpeg',
        '.oga': 'audio/ogg',
        '.ogg': 'audio/ogg',
        '.opus': 'audio/opus',
        '.wav': 'audio/wav',
        '.weba': 'audio/webm',
        '.webm': 'audio/webm',
      },
    );
  }

  Future<String?> _pickAndUpload({
    required Future<PickedImage?> Function() picker,
    required String mediaLabel,
    required String uploadPrefix,
    required String defaultExtension,
    required Map<String, String> contentTypes,
  }) async {
    debugPrint(
      '[UploadService] Seleccionando $mediaLabel (${kIsWeb ? "web" : "movil"})...',
    );

    late Uint8List bytes;
    late String fileName;
    try {
      final result = await picker();
      if (result == null) {
        debugPrint('[UploadService] Usuario cancelo');
        return null;
      }
      bytes = result.bytes;
      fileName = result.name;
      debugPrint('[UploadService] Archivo: $fileName (${bytes.length} bytes)');
    } catch (e, st) {
      debugPrint('[UploadService] Error al seleccionar $mediaLabel: $e\n$st');
      rethrow;
    }

    final ext = _extension(fileName, defaultExtension);
    final fileType = _contentType(ext, contentTypes);
    final uploadName =
        '${uploadPrefix}_${DateTime.now().millisecondsSinceEpoch}$ext';

    debugPrint('[UploadService] POST presigned URL...');
    late http.Response presignedRes;
    try {
      presignedRes = await http
          .post(
            Uri.parse(_uploadEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fileName': uploadName, 'fileType': fileType}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e, st) {
      debugPrint('[UploadService] Fallo POST presigned: $e\n$st');
      rethrow;
    }

    debugPrint('   status: ${presignedRes.statusCode}');
    debugPrint('   body  : ${presignedRes.body}');

    if (presignedRes.statusCode != 200) {
      throw Exception(
        'Error al obtener presigned URL\n'
        'Status: ${presignedRes.statusCode}\n'
        'Body: ${presignedRes.body}',
      );
    }

    late Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(presignedRes.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'Respuesta de Lambda no es JSON valido.\n'
        'Body: ${presignedRes.body}\nError: $e',
      );
    }

    final uploadUrl = responseBody['uploadUrl'] as String?;
    final finalUrl = responseBody['finalUrl'] as String?;

    debugPrint('   uploadUrl: $uploadUrl');
    debugPrint('   finalUrl : $finalUrl');

    if (uploadUrl == null || finalUrl == null) {
      throw Exception(
        'Lambda no devolvio uploadUrl o finalUrl.\n'
        'Campos: ${responseBody.keys.toList()}\n'
        'Body: ${presignedRes.body}',
      );
    }

    debugPrint('[UploadService] PUT a S3...');
    late http.Response putRes;
    try {
      putRes = await http
          .put(
            Uri.parse(uploadUrl),
            headers: {'Content-Type': fileType},
            body: bytes,
          )
          .timeout(const Duration(seconds: 60));
    } catch (e, st) {
      debugPrint('[UploadService] Error PUT S3: $e\n$st');
      rethrow;
    }

    debugPrint('   PUT status: ${putRes.statusCode}');
    if (putRes.body.isNotEmpty) debugPrint('   PUT body  : ${putRes.body}');

    if (putRes.statusCode != 200 && putRes.statusCode != 204) {
      throw Exception(
        'Error al subir a S3\n'
        'Status: ${putRes.statusCode}\n'
        'Body: ${putRes.body}',
      );
    }

    debugPrint('[UploadService] Subida completa -> $finalUrl');
    return finalUrl;
  }

  String _extension(String name, String fallback) {
    final parts = name.split('.');
    return parts.length < 2 ? fallback : '.${parts.last.toLowerCase()}';
  }

  String _contentType(String ext, Map<String, String> contentTypes) {
    return contentTypes[ext] ?? 'application/octet-stream';
  }
}

/// Resultado de seleccion de archivo (plataforma-agnostico).
class PickedImage {
  final Uint8List bytes;
  final String name;
  const PickedImage({required this.bytes, required this.name});
}
