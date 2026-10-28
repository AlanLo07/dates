import 'dart:convert';

import 'package:dates/models/fecha.dart';
import 'package:dates/services/authenticated_http_client.dart' as http;
import 'package:dates/services/events.dart';
import 'package:flutter_test/flutter_test.dart';

class _EventClient extends http.Client {
  _EventClient(this.response, {this.statusCode = 200});

  final Map<String, dynamic> response;
  final int statusCode;
  Map<String, dynamic>? sent;

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    sent = jsonDecode(body as String) as Map<String, dynamic>;
    return http.Response(jsonEncode(response), statusCode);
  }

  @override
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) => post(url, headers: headers, body: body, encoding: encoding);
}

void main() {
  EventoImportante evento() => EventoImportante(
    id: 'evento-1',
    title: 'Picnic',
    description: 'Parque',
    date: '31-10-2026',
    documentos: ['https://example.com'],
  );

  test('POST conserva los datos y usa el checklistId generado', () async {
    final client = _EventClient({
      'id': 'evento-2', 'checklistId': 'lista-1', 'message': 'Cita creada',
    }, statusCode: 201);
    final creado = await EventService(client: client).createEvento(
      evento().copyWith(checklist: const ChecklistEvento(
        titulo: 'Preparativos',
        items: [ItemChecklist(nombre: 'Manta', incluido: true)],
      )),
    );
    expect(creado.id, 'evento-2');
    expect(creado.title, 'Picnic');
    expect(creado.date, '31-10-2026');
    expect(creado.documentos, ['https://example.com']);
    expect(creado.checklistId, 'lista-1');
    expect(creado.checklist.items, isEmpty);
    expect(creado.checklist.titulo, isNull);
    expect(creado.actualizarChecklist, isFalse);
    expect(client.sent!.containsKey('checklistId'), isFalse);
    expect(client.sent!['checklist'], {
      'titulo': 'Preparativos',
      'items': [{'nombre': 'Manta', 'comprado': true}],
    });
  });

  test('POST vincula una lista existente sin clonarla', () async {
    final client = _EventClient({
      'id': 'evento-1', 'checklistId': 'default-viaje',
    }, statusCode: 201);
    final creado = await EventService(client: client).createEvento(
      evento().copyWith(checklistId: 'default-viaje'),
    );
    expect(client.sent!['checklistId'], 'default-viaje');
    expect(client.sent!.containsKey('checklist'), isFalse);
    expect(creado.checklistId, 'default-viaje');
  });

  test('PUT conserva campos ante respuesta parcial y omite vinculo intacto', () async {
    final client = _EventClient({
      'id': 'evento-1', 'checklistId': 'lista-1',
    });
    final original = EventoImportante.fromJson({
      ...evento().toJson(), 'checklistId': 'lista-1',
    });
    final actualizado = await EventService(client: client).updateEvento(
      original.copyWith(title: 'Otro titulo'),
    );
    expect(actualizado.title, 'Otro titulo');
    expect(actualizado.description, 'Parque');
    expect(actualizado.date, '31-10-2026');
    expect(actualizado.documentos, ['https://example.com']);
    expect(actualizado.checklistId, 'lista-1');
    expect(client.sent!.containsKey('checklistId'), isFalse);
    expect(client.sent!.containsKey('checklist'), isFalse);
  });

  test('PUT desvincula enviando null y descarta el contenido antiguo', () async {
    final client = _EventClient({'id': 'evento-1', 'checklistId': null});
    final original = evento().copyWith(checklist: const ChecklistEvento(
      items: [ItemChecklist(nombre: 'Manta', incluido: true)],
    ));
    final actualizado = await EventService(client: client).updateEvento(
      original.copyWith(checklistId: null),
    );
    expect(client.sent!.containsKey('checklistId'), isTrue);
    expect(client.sent!['checklistId'], isNull);
    expect(client.sent!.containsKey('checklist'), isFalse);
    expect(actualizado.checklistId, isNull);
    expect(actualizado.checklist.items, isEmpty);
  });

  test('PUT normal conserva legacy aunque respuesta informe referencia null', () async {
    final client = _EventClient({'id': 'evento-1', 'checklistId': null});
    final original = evento().copyWith(checklist: const ChecklistEvento(
      items: [ItemChecklist(nombre: 'Manta', incluido: true)],
    ));
    final actualizado = await EventService(client: client).updateEvento(original);
    expect(actualizado.checklist.items.single.incluido, isTrue);
    expect(client.sent!.containsKey('checklist'), isFalse);
    expect(client.sent!.containsKey('checklistId'), isFalse);
  });

  test('PUT acepta una respuesta con item completo y referencia null', () async {
    final client = _EventClient({
      'item': {...evento().toJson(), 'title': 'Confirmado', 'checklistId': null},
    });
    final actualizado = await EventService(client: client).updateEvento(
      evento().copyWith(checklistId: null),
    );
    expect(actualizado.title, 'Confirmado');
    expect(actualizado.checklistId, isNull);
  });

  test('un 404 del vinculo no se convierte en guardado local exitoso', () async {
    final client = _EventClient({'message': 'Checklist inexistente'}, statusCode: 404);
    await expectLater(
      EventService(client: client).createEvento(evento().copyWith(checklistId: 'borrado')),
      throwsA(isA<Exception>()),
    );
  });
}