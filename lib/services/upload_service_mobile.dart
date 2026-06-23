// lib/services/upload_service_mobile.dart
// Solo se compila en iOS/Android (dart:io disponible)
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'upload_service.dart';

const MethodChannel _uploadPickerChannel = MethodChannel(
  'dates/upload_picker',
);

Future<PickedImage?> pickImage() async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 85,
  );
  if (xfile == null) return null;
  final bytes = await xfile.readAsBytes();
  return PickedImage(bytes: bytes, name: xfile.name);
}

Future<PickedImage?> pickAudio() {
  if (!Platform.isAndroid) {
    throw UnsupportedError(
      'La seleccion de audio movil solo esta implementada en Android.',
    );
  }
  return _pickAndroidAudio();
}

Future<PickedImage?> _pickAndroidAudio() async {
  final result = await _uploadPickerChannel.invokeMapMethod<String, dynamic>(
    'pickAudio',
  );
  if (result == null) return null;

  final bytes = result['bytes'];
  final name = result['name'] as String? ?? 'audio.mp3';

  if (bytes is Uint8List) {
    return PickedImage(bytes: bytes, name: name);
  }

  throw StateError('El selector de audio no devolvio bytes validos.');
}
