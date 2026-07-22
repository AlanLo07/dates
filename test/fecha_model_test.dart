import 'package:flutter_test/flutter_test.dart';
import 'package:dates/models/fecha.dart';

void main() {
  group('EventoImportante', () {
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
