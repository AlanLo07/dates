import 'package:flutter_test/flutter_test.dart';
import 'package:dates/models/fecha.dart';

void main() {
  group('EventoImportante', () {
    EventoImportante eventoDesde(Map<String, dynamic> extra) {
      return EventoImportante.fromJson({
        'id': 'evento-1',
        'title': 'Picnic',
        'date': '31-10-2026',
        ...extra,
      });
    }

    test('un evento nuevo puede omitir el checklist', () {
      final payload = eventoDesde({}).toJson();
      expect(payload.containsKey('checklist'), isFalse);
      expect(payload.containsKey('checklistId'), isFalse);
    });

    test('lee y conserva una referencia sin expandir items', () {
      final evento = eventoDesde({'checklistId': 'default-viaje'});
      final editado = evento.copyWith(title: 'Otro titulo');
      expect(editado.checklistId, 'default-viaje');
      expect(editado.checklist.items, isEmpty);
      expect(editado.actualizarChecklist, isFalse);
      expect(editado.toJson()['checklistId'], 'default-viaje');
      expect(editado.toJson().containsKey('checklist'), isFalse);
      final patch = editado.toJson(incluirVinculo: editado.actualizarChecklist);
      expect(patch.containsKey('checklistId'), isFalse);
    });

    test('permite cambiar y desvincular con null real', () {
      final evento = eventoDesde({'checklistId': 'default-viaje'});
      final vinculado = evento.copyWith(checklistId: 'otro');
      expect(vinculado.actualizarChecklist, isTrue);
      expect(vinculado.toJson()['checklistId'], 'otro');
      final desvinculado = vinculado.copyWith(checklistId: null);
      expect(desvinculado.toJson().containsKey('checklistId'), isTrue);
      expect(desvinculado.toJson()['checklistId'], isNull);
      expect(desvinculado.toJson().containsKey('checklist'), isFalse);
      expect(desvinculado.copyWith(title: 'Cambio').checklistId, isNull);
    });

    test('tolera legacy y lo omite en una edicion normal', () {
      final evento = eventoDesde({
        'checklist': {
          'items': [
            {'nombre': 'Manta', 'incluido': true},
          ],
        },
      });
      expect(evento.checklist.items.single.incluido, isTrue);
      final editado = evento.copyWith(title: 'Nuevo titulo');
      expect(editado.checklist.items.single.incluido, isTrue);
      expect(editado.toJson().containsKey('checklist'), isFalse);
      expect(editado.toJson().containsKey('checklistId'), isFalse);
    });

    test('migrar envia titulo y comprado, nunca incluido ni checklistId', () {
      final antiguo = eventoDesde({
        'checklist': {
          'items': [
            {'nombre': 'Manta', 'incluido': true},
          ],
        },
      });
      final migrado = antiguo.copyWith(checklist: ChecklistEvento(
        titulo: 'Preparativos', items: antiguo.checklist.items,
      ));
      final payload = migrado.toJson();
      expect(migrado.actualizarChecklist, isTrue);
      expect(payload.containsKey('checklistId'), isFalse);
      expect(payload['checklist'], {
        'titulo': 'Preparativos',
        'items': [{'nombre': 'Manta', 'comprado': true}],
      });
    });

    test('crear sustituye la referencia y vincular retira el borrador', () {
      final evento = eventoDesde({'checklistId': 'default-viaje'});
      final nuevo = evento.copyWith(checklist: const ChecklistEvento(
        titulo: 'Lista nueva',
      ));
      expect(nuevo.checklistId, isNull);
      expect(nuevo.toJson()['checklist'], {'titulo': 'Lista nueva', 'items': []});
      expect(nuevo.toJson().containsKey('checklistId'), isFalse);
      final existente = nuevo.copyWith(checklistId: 'otro');
      expect(existente.toJson().containsKey('checklist'), isFalse);
      expect(existente.toJson()['checklistId'], 'otro');
    });

    test('valida titulo y limite de items antes de crear', () {
      expect(() => const ChecklistEvento(titulo: ' ').toJson(), throwsArgumentError);
      final items = List.generate(99, (index) => ItemChecklist(nombre: '$index'));
      expect(
        () => ChecklistEvento(titulo: 'Lista', items: items).toJson(),
        throwsArgumentError,
      );
      expect(
        ChecklistEvento(titulo: 'Lista', items: items.take(98).toList())
            .toJson()['items'],
        hasLength(98),
      );
    });

    test('acepta comprado al leer y respeta false frente a legacy', () {
      final item = ItemChecklist.fromJson({
        'nombre': 'Manta', 'comprado': false, 'incluido': true,
      });
      expect(item.incluido, isFalse);
      expect(item.toJson(), {'nombre': 'Manta', 'comprado': false});
    });

    test('copyWith preserves and overrides the fields', () {
      final evento = EventoImportante(
        id: '1',
        title: 'Cena romántica',
        description: 'Descripción inicial',
        date: '01-01-2026',
        icon: 'star',
        itinerario: const ItinerarioEvento(
          actividades: [
            ActividadItinerario(
              fecha: '02-01-2026',
              tiempo: '20:00',
              actividad: 'Cena',
            ),
          ],
        ),
        presupuesto: const PresupuestoEvento(
          gastado: 50,
          limite: 100,
          conceptos: [
            ConceptoGasto(concepto: 'Comida', monto: 50),
          ],
        ),
        documentos: const ['https://ejemplo.com'],
      );

      final actualizado = evento.copyWith(
        title: 'Cena editada',
        description: 'Nueva descripción',
      );

      expect(actualizado.title, 'Cena editada');
      expect(actualizado.description, 'Nueva descripción');
      expect(actualizado.date, '01-01-2026');
      expect(actualizado.itinerario.actividades.single.actividad, 'Cena');
      expect(actualizado.presupuesto.conceptos.single.concepto, 'Comida');
      expect(actualizado.documentos.single, 'https://ejemplo.com');
    });
  });
}
