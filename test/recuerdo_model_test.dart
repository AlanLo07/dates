import 'package:dates/models/recuerdos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recuerdo', () {
    test('lee la respuesta nueva con varias imagenes', () {
      final recuerdo = Recuerdo.fromJson({
        'id': '1',
        'title': 'Viaje',
        'description': 'Nuestro viaje',
        'date': '31-08-2026',
        'imagesPath': ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      });

      expect(recuerdo.imagePath, isNull);
      expect(recuerdo.imageUrls, [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
      ]);
    });

    test('mantiene compatibilidad con imagePath', () {
      final recuerdo = Recuerdo.fromJson({
        'id': '1',
        'title': 'Viaje',
        'description': 'Nuestro viaje',
        'date': '31-08-2026',
        'imagePath': 'https://example.com/legacy.jpg',
      });

      expect(recuerdo.imageUrls, ['https://example.com/legacy.jpg']);
    });

    test('serializa imagesPath y omite imagePath vacio', () {
      const recuerdo = Recuerdo(
        id: '1',
        title: 'Viaje',
        description: 'Nuestro viaje',
        date: '31-08-2026',
        imagesPath: ['https://example.com/1.jpg'],
      );

      expect(recuerdo.toJson()['imagesPath'], ['https://example.com/1.jpg']);
      expect(recuerdo.toJson().containsKey('imagePath'), isFalse);
    });
  });
}