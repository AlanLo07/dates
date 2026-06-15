// lib/services/upload_service_web.dart
// Implementación web SIN dart:html (deprecado en Flutter 3.19+)
// Usa package:web + dart:js_interop
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'upload_service.dart';

Future<PickedImage?> pickImage() async {
  final completer = Completer<PickedImage?>();

  // Crear <input type="file" accept="image/*"> programáticamente
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = 'image/*';

  input.onchange = (web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      return;
    }
    final file = files.item(0)!;
    final reader = web.FileReader();

    reader.onload = (web.Event _) {
      final result = reader.result;
      if (result == null) {
        completer.completeError('FileReader result es null');
        return;
      }
      // result es un JSArrayBuffer — convertir a Uint8List
      final buffer = (result as JSArrayBuffer).toDart;
      final bytes = Uint8List.view(buffer);
      completer.complete(PickedImage(bytes: bytes, name: file.name));
    }.toJS;

    reader.onerror = (web.Event _) {
      completer.completeError('Error al leer el archivo con FileReader');
    }.toJS;

    reader.readAsArrayBuffer(file);
  }.toJS;

  // Adjuntar al DOM brevemente (necesario en algunos browsers)
  web.document.body!.append(input);
  input.click();

  // Limpiar el input del DOM cuando termine
  completer.future.whenComplete(() {
    try {
      input.remove();
    } catch (_) {}
  });

  return completer.future;
}
