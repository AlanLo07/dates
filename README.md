# dates

A new Flutter project.

## Checklists de las citas

Al crear o editar una cita en el calendario se puede seleccionar un checklist
existente, crear uno nuevo con titulo e items o dejarla sin checklist.
La creacion de la cita y su nueva lista se envia en una sola solicitud a
`POST /citas`; al editar se utiliza `PUT /citas/{id}`.

- Las citas guardan `checklistId`; el detalle se carga desde `/checklists/{id}`.
- Cambiar items o reiniciar una lista afecta a todas las citas vinculadas.
- Desvincular una lista o eliminar la cita no elimina el checklist.
- Una lista eliminada muestra un aviso y puede reemplazarse o desvincularse
  desde la edicion de la cita.
- Las listas antiguas se siguen mostrando y se conservan al editar otros
  campos. Elegir "Crear nuevo checklist" permite migrar sus items, convirtiendo
  `incluido` a `comprado` sin perder su estado.
- Si no se cambia el vinculo, el PUT omite ambos campos de checklist. La
  respuesta parcial del servidor se combina con los datos del evento y se
  conserva el `checklistId` confirmado, incluido `null`.

Comprobaciones locales:

```cmd
flutter test test/fecha_model_test.dart test/events_service_test.dart
flutter analyze lib/models/fecha.dart lib/services/events.dart lib/services/checklists_service.dart lib/screens/calendar lib/screens/checklist/checklist_detail_screen.dart
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Diagnostico: metas de ahorro y retos mensuales

### Metas de ahorro en web

La app envia `POST /finances/metas`, no `OPTIONS`. El navegador genera el
preflight `OPTIONS` por los headers `Authorization`, `Content-Type` (JSON) e
`Idempotency-Key`. No se debe quitar la autenticacion ni la idempotencia para
evitarlo. Ejemplo de body:

```json
{
  "name": "Viaje",
  "targetAmount": 15000,
  "priority": 1
}
```

`priority` y `bodaId` son opcionales. Se espera HTTP `201`.

Si solo aparece `OPTIONS 204` y nunca el `POST`, revisar en DevTools la consola
y los headers de respuesta del preflight. El `204` no basta para aprobar CORS.
La API debe permitir el origen real de la app y responder, como minimo:

```http
Access-Control-Allow-Origin: <origen real de la app>
Access-Control-Allow-Methods: POST, OPTIONS
Access-Control-Allow-Headers: Authorization, Content-Type, Idempotency-Key
```

Conservar tambien los otros metodos y headers que use la API. El preflight no
debe exigir bearer token. La respuesta al POST, incluidos los errores, tambien
debe incluir `Access-Control-Allow-Origin`. Para leer los identificadores AWS
desde los logs web, exponerlos con
`Access-Control-Expose-Headers: x-amzn-requestid, x-amz-apigw-id`.

### Propuesta personalizada del reto del mes

Solicitud usada para el ejemplo reportado:

```http
POST /monthly-challenges/current/proposals
Authorization: Bearer <token de sesion>
Content-Type: application/json; charset=UTF-8
```

```json
{
  "source": "custom",
  "title": "Cocinar algo nuevo",
  "description": "Vamos a probar una nueva receta para ver que tal sale",
  "category": "diversion"
}
```

Flujo:

1. El formulario recorta titulo y descripcion y valida que no esten vacios.
2. `MonthlyChallengesService.proposeCustom` serializa esos cuatro campos.
3. El cliente compartido obtiene el token, agrega `Authorization` y envia POST.
	Si recibe `401`, intenta renovar la sesion y reenvia una vez.
4. El servicio acepta `200` o `201`, interpreta `MonthlyChallengeState` y la
	pantalla actualiza su estado con la respuesta. Proponer no es votar ni
	completar el reto.
5. Ante error HTTP se propaga `MonthlyChallengesApiException`; un `409` provoca
	una recarga del estado en la pantalla. Una respuesta de error no JSON
	conserva el status HTTP en lugar de ocultarlo con un error de parseo.

Los logs usan semaforos: entrada, estructura/tipos/longitudes de campos,
autenticacion, envio, status HTTP, tiempo transcurrido, request ID de AWS
(si esta disponible) e interpretacion del estado. No imprimen tokens, valores
de headers, texto personal ni cuerpos de respuesta. Buscar las etiquetas
`[AuthenticatedHttpClient]` y `[MonthlyChallengesService]` en la consola.
Si no hay respuesta HTTP accesible en web, revisar CORS; ese log por si solo
no distingue CORS de una desconexion o un fallo de red.
