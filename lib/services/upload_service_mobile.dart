// lib/services/upload_service_mobile.dart
// Solo se compila en iOS/Android (dart:io disponible)
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'upload_service.dart';

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
