import 'package:dates/models/checklist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChecklistItem', () {
    test('lee y serializa prioridadOrden', () {
      final item = ChecklistItem.fromJson({
        'id': '1',
        'nombre': 'Pasaportes',
        'prioridad': 'baja',
        'prioridadOrden': 1,
      });

      expect(item.prioridadOrden, 1);
      expect(item.toJson()['prioridadOrden'], 1);
    });

    test('usa la prioridad existente como respaldo si falta el orden', () {
      final item = ChecklistItem.fromJson({
        'id': '1',
        'nombre': 'Pasaportes',
        'prioridad': 'alta',
      });

      expect(item.prioridadOrden, 1);
    });
  });

  test('ordena los items por prioridadOrden ascendente dentro del grupo', () {
    final board = ChecklistBoard(
      id: 'board',
      titulo: 'Viaje',
      items: [
        ChecklistItem(
          id: '3',
          nombre: 'Cargador',
          prioridadOrden: 3,
          comprado: true,
        ),
        ChecklistItem(id: '1', nombre: 'Pasaporte', prioridadOrden: 1),
        ChecklistItem(id: '2', nombre: 'Medicinas', prioridadOrden: 2),
      ],
    );

    expect(
      board.itemsByGroup(null).map((item) => item.nombre).toList(),
      ['Pasaporte', 'Medicinas', 'Cargador'],
    );
  });
}
