# Pregunta de la Semana - Integración en Home Completada

**Estado**: ✅ COMPLETADO - Weekly Questions ahora visible en Home como Menu Card

---

## 📋 Resumen de Cambios Realizados

### 1. Home Menu Card Creado
- **Archivo**: `lib/screens/home/widgets/home_weekly_questions_card.dart`
- **Características**:
  - Diseño visual con gradiente purpura coherente
  - Muestra estado actual de la pregunta semanal
  - Iconos emoji según estado (✅ completada, ⏳ parcial, 📝 pendiente, ❓ no disponible)
  - Carga asincrónica de pregunta al inicializar
  - Navegación a `WeeklyQuestionsScreen` con animación personalizada

### 2. Home.dart Actualizado
- Importado `home_weekly_questions_card.dart`
- Agregado card como índice 11 en lista de menú
- Posicionado después del "Reto del mes"
- Integrado con animaciones existentes

### 3. Navegación
- Usa sistema `createRoute()` con `AppRouteMotion.sharedAxisX`
- Navega directamente a `WeeklyQuestionsScreen`
- Mantiene consistencia con otros cards

---

## 📁 Estructura de Archivos

```
lib/
├── models/
│   └── weekly_question.dart                 # Modelos de datos
├── services/
│   └── weekly_questions_service.dart        # Servicio de API
├── screens/
│   ├── weekly_questions_screen.dart                    # Pantalla principal (3 tabs)
│   ├── weekly_questions_detail_screen.dart            # Detalle de pregunta
│   ├── weekly_questions_create_screen.dart            # Crear pregunta
│   ├── weekly_questions_answer_screen.dart            # Responder pregunta
│   ├── weekly_questions_catalog_screen.dart           # Catálogo filtrado
│   ├── weekly_questions_history_screen.dart           # Historial de preguntas
│   └── home/
│       └── widgets/
│           └── home_weekly_questions_card.dart        # ✨ NUEVO - Card en home
├── widgets/
│   └── weekly_question_card.dart            # Widget reutilizable
└── home.dart                                 # ✨ ACTUALIZADO

test/
└── weekly_questions_model_test.dart         # Tests unitarios
```

---

## 🎨 Estados Visuales del Card

| Estado | Emoji | Texto | Uso |
|--------|-------|-------|-----|
| Completada | ✅ | "Completada" | Ambos respondieron |
| Parcial | ⏳ | "Una respuesta pendiente" | Solo uno respondió |
| Pendiente | 📝 | "Pendiente de respuestas" | Ninguno respondió |
| Sin preguntas | ❓ | "No hay preguntas disponibles" | Catálogo vacío |
| Cargando | — | "Cargando..." | Espera inicial |
| Error | — | "Error al cargar" | Fallo de API |

**Colores Gradiente**:
- Inicio: `#9C8DC4` (purpura claro)
- Fin: `#6B5B95` (purpura oscuro)
- Sombra: 30% opacidad

---

## 🚀 Verificación de Funcionalidad

Comprobar en la app:
- ✅ Card aparece en home después de "Reto del mes"
- ✅ Muestra correctamente el estado de la pregunta semanal
- ✅ Animación de entrada coherente con otros cards
- ✅ Al hacer tap navega a `WeeklyQuestionsScreen`
- ✅ Maneja estados de error y carga gracefully

---

## 🔧 Integración Técnica

### WeeklyQuestionsService
- Singleton: `WeeklyQuestionsService.instance`
- Método: `getCurrentQuestion()`
- Manejo robusto de errores

### Animaciones
- Duraciones sincronizadas con otros cards
- `HomeAnimatedEntryCard` para efecto de entrada
- `MotionPressable` para interacción

### Sin Breaking Changes
- Reutiliza dependencias existentes
- No modifica servicios existentes
- Integración completamente aislada

---

## 📝 Próximos Pasos (Opcional)

### Reorganización en Subcarpeta
Para mejor estructura, puede organizar weekly_questions en:
```
lib/screens/weekly_questions/
├── weekly_questions_screen.dart
├── question_detail_screen.dart
├── question_create_screen.dart
├── question_answer_screen.dart
├── question_catalog_screen.dart
├── question_history_screen.dart
└── index.dart (barrel export)
```

Esto requeriría actualizar imports en:
- Cada archivo de pantalla
- `home_weekly_questions_card.dart`: `'../../weekly_questions/weekly_questions_screen.dart'`

---

## 🎯 Estado Final

✅ **Weekly Questions visible en Home**
✅ **Navegación completa implementada**
✅ **Animaciones sincronizadas**
✅ **Manejo de errores robusto**
✅ **Listo para producción**


### 3. Localización en español

Asegúrate de agregar localizaciones en `main.dart`:
```dart
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('es', 'ES'),
    Locale('en', 'US'),
  ],
  // ...
)
```

## 🔧 Integración en main.dart

Importa y agrega la pantalla a tu navegación:

```dart
import 'screens/weekly_questions_screen.dart';

// En tu NavigationBar o similar:
case 'weekly_questions':
  return const WeeklyQuestionsScreen();

// O en tu AppBar/drawer:
ListTile(
  leading: const Icon(Icons.question_answer),
  title: const Text('Pregunta de la Semana'),
  onTap: () => Navigator.pushNamed(context, '/weekly-questions'),
)
```

## 📋 Modelos de Datos

### WeeklyQuestion
Representa una pregunta con estado actual.

```dart
WeeklyQuestion(
  id: 'uuid',
  text: 'Pregunta?',
  category: 'profundas',
  status: 'partial',           // unseen, pending, partial, completed
  canAnswer: false,
  canEdit: true,
  answers: {
    'sub-user-1': Answer(...),  // Respuestas por sub de Cognito
  },
);
```

### Answer
Respuesta individual a una pregunta.

```dart
Answer(
  text: 'Mi respuesta es...',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

### CatalogQuestion
Pregunta en el catálogo (editable).

```dart
CatalogQuestion(
  id: 'uuid',
  text: 'Pregunta?',
  category: 'divertidas',
  version: 2,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  createdBy: 'sub-user-1',
  updatedBy: 'sub-user-1',
);
```

## 🌐 Servicio de API

El `WeeklyQuestionsService` maneja toda la comunicación con el backend.

### Métodos principales

```dart
// Obtener pregunta de la semana actual
Future<WeeklyQuestionsResponse> getCurrentQuestion()

// Crear pregunta en catálogo
Future<CatalogQuestion> createCatalogQuestion({
  required String text,
  required String category,
})

// Obtener catálogo con filtros
Future<PaginatedResponse<CatalogQuestion>> getCatalog({
  String? category,
  int limit = 20,
  String? nextToken,
})

// Responder pregunta (crea o edita)
Future<WeeklyQuestion> submitAnswer({
  required String questionId,
  required String text,
})

// Obtener historial con filtros
Future<PaginatedResponse<WeeklyQuestion>> getQuestions({
  String? status,
  String? pendingFor,
  String? category,
  int limit = 20,
  String? nextToken,
})
```

### Uso típico

```dart
final service = WeeklyQuestionsService.instance;

try {
  final response = await service.getCurrentQuestion();
  final question = response.question;
  
  if (question != null) {
    if (question.canAnswer) {
      await service.submitAnswer(
        questionId: question.id,
        text: 'Mi respuesta',
      );
    }
  }
} catch (e) {
  print('Error: $e');
}
```

## 🎨 Pantallas y Widgets

### WeeklyQuestionsScreen (Principal)
Pantalla con 3 tabs:

1. **Actual** - Pregunta de esta semana
   - Muestra la pregunta actual
   - Formulario para responder (si `canAnswer`)
   - Respuesta de la pareja (si existe)
   - FAB para responder (si puede)

2. **Catálogo** - Lista de todas las preguntas
   - Filtro por categoría
   - Lista con scroll infinito
   - FAB para crear pregunta

3. **Historial** - Preguntas anteriores
   - Filtro por estado (completada, parcial, pendiente, nueva)
   - Scroll infinito
   - Tap en pregunta para detalles

### WeeklyQuestionCard (Widget)
Tarjeta reutilizable que muestra:
- Categoría (chip de color)
- Texto de pregunta
- Estado con icono
- Progreso (1/2 respuestas)
- Indicadores visuales de estado

Colores por categoría:
- **divertidas**: amarillo
- **profundas**: púrpura
- **romanticas**: rosa
- **absurdas**: azul
- **otras**: gris

## 🔄 Flujo de Interacción

### Primera carga
```
1. App abre → WeeklyQuestionsScreen
2. Llama getCurrentQuestion() → Obtiene pregunta semanal
3. Muestra pregunta actual o estado vacío
```

### Responder pregunta
```
1. Usuario toca "Escribe tu respuesta"
2. Navega a WeeklyQuestionsAnswerScreen
3. Escribe respuesta (máx 5000 caracteres)
4. Toca "Guardar Respuesta"
5. POST /weekly-questions/{id}/answer (201 o 200)
6. Regresa a pantalla principal actualizada
```

### Ver historial
```
1. Usuario va a tab "Historial"
2. Selecciona filtro (completadas por defecto)
3. Se cargan preguntas paginadas
4. Scroll infinito carga más
5. Tap en pregunta → WeeklyQuestionsDetailScreen
```

### Crear pregunta
```
1. Usuario toca FAB en tab "Catálogo"
2. Navega a WeeklyQuestionsCreateScreen
3. Rellena texto y categoría
4. POST /weekly-questions/catalog (201)
5. Regresa al catálogo
```

## 🧪 Testing

Ejecuta tests con:
```bash
flutter test test/weekly_questions_model_test.dart
```

Los tests cubren:
- Serialización/deserialización de modelos
- Validación de datos
- Transformación de respuestas
- Estados de preguntas

## ⚠️ Notas Importantes

### Autenticación
- Todos los endpoints requieren JWT de Cognito
- El header `Authorization: Bearer <token>` se envía automáticamente
- El `AuthenticatedHttpClient` maneja renovación de tokens

### Zonas horarias
- Semanas basadas en `America/Mexico_City`
- Lunes 00:00 → Lunes siguiente 00:00
- El servidor maneja todo con UTC

### Validaciones
- Texto de pregunta: 1-1000 caracteres
- Categoría: 1-60 caracteres
- Respuesta: 1-5000 caracteres
- Ambas se recortan automáticamente (`.trim()`)

### Estados de preguntas
- **unseen**: Nunca presentada
- **pending**: Presentada, sin respuestas
- **partial**: Presentada, una respuesta
- **completed**: Ambos respondieron

### Permisos
No habilites formularios basándote solo en `locked`:
```dart
// ✅ Correcto
if (question.canAnswer) {
  // Mostrar formulario de respuesta nueva
}

if (question.canEdit) {
  // Permitir editar respuesta propia
}

// ❌ Incorrecto
if (!question.locked) {
  // No es suficiente - podría estar sin poder responder
}
```

## 🔄 Actualización de UI

### Después de enviar respuesta
```dart
// El service devuelve la pregunta actualizada
final updatedQuestion = await service.submitAnswer(...);

// Actualiza la UI localmente
setState(() {
  _currentQuestion = updatedQuestion;
});
```

### Recuperar foco (App en background)
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _loadCurrentQuestion(); // Recarga pregunta semanal
  }
}
```

## 🐛 Debugging

### Logs del cliente
El `AuthenticatedHttpClient` incluye logs:
- 🔵 Solicitudes autenticadas
- 🟢 Respuestas exitosas
- 🟡 Token renovado
- 🔴 Errores

Busca `[AuthenticatedHttpClient]` en la consola.

### Errores comunes

#### 403 Forbidden
- Usuario no pertenece a la pareja
- Intenta responder pregunta no actual
- Intenta editar respuesta ajena

#### 409 Conflict
- Versión de catálogo desactualizada (editar pregunta)
- Recarga y reconcilia cambios manualmente

#### 503 Service Unavailable
- Configuración de usuarios Cognito inválida
- Revisar que haya exactamente 2 usuarios en el User Pool

## 📱 Responsive Design

Las pantallas están optimizadas para:
- Móviles (< 600 dp)
- Tablets (> 600 dp)
- Escritorio

Los Cards y campos adaptan su tamaño con `double.infinity` y `Expanded`.

## 🎯 Próximos Pasos

1. **Integración en navegación**: Agrega ruta a main.dart
2. **Estilo visual**: Personaliza colores según tu theme
3. **Traducción**: Mantén strings en español o exporta a i18n
4. **Notificaciones**: Implementa push cuando pareja responde (no incluido)
5. **Analytics**: Rastrea interacciones (no incluido)

## 📞 Soporte

Para errores de API, revisa:
- `lib/services/weekly_questions_service.dart` - `_handleError()`
- Documentación del backend en la carpeta `lambdas/`
- Logs de CloudWatch en AWS

---

**Última actualización**: 2026-11-19
**Versión**: 1.0.0
