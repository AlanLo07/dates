// lib/services/upload_service.dart
//
// Compatible con Flutter Web Y móvil (iOS/Android).
// - Web: usa dart:html FileUploadInputElement (sin plugins)
// - Móvil: usa image_picker (XFile)
//
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

// Importaciones condicionales según plataforma
import 'upload_service_web.dart'
    if (dart.library.io) 'upload_service_mobile.dart'
    as platform;

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final String _uploadEndpoint = '${ApiConfig.baseUrl}${ApiConfig.uploadPath}';

  /// Abre el selector de imagen según la plataforma y sube a S3.
  /// Devuelve la URL pública, o null si el usuario canceló.
  Future<String?> pickAndUpload() async {
    debugPrint(
      '📷 [UploadService] Seleccionando imagen (${kIsWeb ? "web" : "móvil"})...',
    );

    // 1. Elegir imagen según plataforma
    late Uint8List bytes;
    late String fileName;
    try {
      final result = await platform.pickImage();
      if (result == null) {
        debugPrint('ℹ️ [UploadService] Usuario canceló');
        return null;
      }
      bytes = result.bytes;
      fileName = result.name;
      debugPrint('✅ [UploadService] Imagen: $fileName (${bytes.length} bytes)');
    } catch (e, st) {
      debugPrint('❌ [UploadService] Error al seleccionar imagen: $e\n$st');
      rethrow;
    }

    final ext = _extension(fileName);
    final fileType = _contentType(ext);
    final uploadName = 'cita_${DateTime.now().millisecondsSinceEpoch}$ext';

    // 2. Presigned URL
    debugPrint('📡 [UploadService] POST presigned URL...');
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
      debugPrint('❌ [UploadService] Fallo POST presigned: $e\n$st');
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
        'Respuesta de Lambda no es JSON válido.\n'
        'Body: ${presignedRes.body}\nError: $e',
      );
    }

    final uploadUrl = responseBody['uploadUrl'] as String?;
    final finalUrl = responseBody['finalUrl'] as String?;

    debugPrint('   uploadUrl: $uploadUrl');
    debugPrint('   finalUrl : $finalUrl');

    if (uploadUrl == null || finalUrl == null) {
      throw Exception(
        'Lambda no devolvió uploadUrl o finalUrl.\n'
        'Campos: ${responseBody.keys.toList()}\n'
        'Body: ${presignedRes.body}',
      );
    }

    // 3. PUT a S3
    debugPrint('🚀 [UploadService] PUT a S3...');
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
      debugPrint('❌ [UploadService] Error PUT S3: $e\n$st');
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

    debugPrint('✅ [UploadService] Subida completa → $finalUrl');
    return finalUrl;
  }

  String _extension(String name) {
    final parts = name.split('.');
    return parts.length < 2 ? '.jpg' : '.${parts.last.toLowerCase()}';
  }

  String _contentType(String ext) {
    const map = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.heic': 'image/heic',
      '.gif': 'image/gif',
    };
    return map[ext] ?? 'image/jpeg';
  }
}

/// Resultado de selección de imagen (plataforma-agnóstico)
class PickedImage {
  final Uint8List bytes;
  final String name;
  const PickedImage({required this.bytes, required this.name});
}
