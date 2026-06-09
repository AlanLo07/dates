// lib/services/upload_service.dart
//
// Flujo:
//   1. POST /upload {fileName, contentType}  → Lambda devuelve { uploadUrl, publicUrl }
//   2. PUT uploadUrl  con los bytes del archivo
//   3. Retorna publicUrl (la URL pública en S3)
//
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class UploadService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final String _uploadUrl = ApiConfig.baseUrl + ApiConfig.uploadPath;

  // ── Upload principal ───────────────────────────────────────────────────────
  /// Sube [file] a S3 a través de la presigned URL que genera Lambda.
  /// Devuelve la URL pública del objeto en S3.
  Future<String> uploadImage(File file, XFile? image) async {
    print("File: ${file}");
    // 1. Pedir presigned URL a Lambda
    final fileName = _uniqueFileName(file);
    final contentType = _contentType(file);

    print("File Name: ${fileName}");
    print("Content Type: ${contentType}");

    final presignedRes = await http
        .post(
          Uri.parse(_uploadUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fileName': fileName, 'fileType': contentType}),
        )
        .timeout(const Duration(seconds: 15));

    if (presignedRes.statusCode != 200 && presignedRes.statusCode != 201) {
      throw Exception(
        'Error al obtener presigned URL: ${presignedRes.statusCode} — ${presignedRes.body}',
      );
    }

    final body = jsonDecode(presignedRes.body) as Map<String, dynamic>;
    final uploadUrl = body['uploadUrl'] as String?;
    final publicUrl = body['finalUrl'] as String?;

    if (uploadUrl == null || publicUrl == null) {
      throw Exception(
        'La Lambda no devolvió uploadUrl o publicUrl. Respuesta: ${presignedRes.body}',
      );
    }

    // 2. PUT directo a S3 con los bytes del archivo
    final Uint8List bytes = await image!.readAsBytes();
    final putRes = await http
        .put(
          Uri.parse(uploadUrl),
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length.toString(),
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));

    print("Respuesta PUT: ${putRes} ${putRes.body}");

    if (putRes.statusCode != 200 && putRes.statusCode != 204) {
      throw Exception(
        'Error al subir a S3: ${putRes.statusCode} — ${putRes.body}',
      );
    }

    return publicUrl;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Genera un nombre único para evitar colisiones en el bucket.
  String _uniqueFileName(File file) {
    final ext = p.extension(file.path).toLowerCase(); // .jpg, .png, etc.
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'citas/$ts$ext';
  }

  String _contentType(File file) {
    final ext = p.extension(file.path).toLowerCase();
    const map = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.heic': 'image/heic',
    };
    return map[ext] ?? 'image/jpeg';
  }
}
