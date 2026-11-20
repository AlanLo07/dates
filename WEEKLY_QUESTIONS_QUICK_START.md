# Guía Rápida de Integración - Pregunta de la Semana

## Paso 1: Importar en main.dart

```dart
import 'screens/weekly_questions_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dates App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      home: const HomePage(),
      routes: {
        '/weekly-questions': (_) => const WeeklyQuestionsScreen(),
      },
    );
  }
}
```

## Paso 2: Agregar navegación

En tu archivo de home o navbar:

```dart
// Opción A: NavigationBar
navigationBarItems: [
  // ... otros items
  NavigationDestination(
    icon: Icon(Icons.question_answer),
    label: 'Preguntas',
  ),
],

onDestinationSelected: (index) {
  if (index == 4) { // Ajusta el índice según tus items
    Navigator.pushNamed(context, '/weekly-questions');
  }
},

// Opción B: Drawer
Drawer(
  child: ListView(
    children: [
      // ... header
      ListTile(
        leading: Icon(Icons.question_answer),
        title: Text('Pregunta de la Semana'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/weekly-questions');
        },
      ),
    ],
  ),
)

// Opción C: FAB o botón directo
FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/weekly-questions'),
  child: Icon(Icons.question_answer),
)
```

## Paso 3: Verificar dependencias en pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  intl: 0.20.2
  http: ^1.1.0
  # ... resto de dependencias
```

Luego ejecuta:
```bash
flutter pub get
```

## Paso 4: Verificar ApiConfig

Archivo: `lib/services/api_config.dart`

Debe contener la URL base correcta:
```dart
const String baseUrl = 'https://ujq4e9csj9.execute-api.us-east-2.amazonaws.com/';
```

## Paso 5: Ejecutar la app

```bash
flutter run
```

Luego navega a "Pregunta de la Semana" desde tu app.

## 🎯 Funcionalidades Inmediatas

Una vez integrado, tendrás:

✅ **Pestaña Actual** - Pregunta de esta semana con respuestas
✅ **Pestaña Catálogo** - Crear preguntas y filtrar por categoría
✅ **Pestaña Historial** - Ver preguntas anteriores respondidas
✅ **Responder** - Sistema de respuestas y edición
✅ **Sincronización** - Se actualiza al recuperar foco

## 📝 Personalización Básica

### Cambiar colores

En `lib/widgets/weekly_question_card.dart`:

```dart
Color _getCategoryColor() {
  switch (question.category.toLowerCase()) {
    case 'divertidas':
      return Colors.amber[300]; // Cambiar color
    case 'profundas':
      return Colors.indigo[400]; // Cambiar color
    // ...
  }
}
```

### Cambiar iconos

En `lib/screens/weekly_questions_history_screen.dart`:

```dart
String _getStatusLabel() {
  switch (_filterStatus) {
    case 'completed':
      return '🎉 Completadas'; // Cambiar emoji
    // ...
  }
}
```

### Cambiar textos

Busca cualquier `Text()` en las pantallas y personaliza.

## 🧪 Verificar que funciona

1. Abre la app
2. Navega a "Pregunta de la Semana"
3. Deberías ver una de estas pantallas:
   - ✅ Pregunta actual con formulario de respuesta
   - ✅ Estado "No hay preguntas disponibles"

4. Si ves un error:
   - Verifica que AuthService esté autenticando
   - Revisa logs en la consola (busca `[AuthenticatedHttpClient]`)
   - Confirma que el backend esté accesible

## 🔗 Referencias

- [Documentación completa](./WEEKLY_QUESTIONS_INTEGRATION.md)
- [Modelos de datos](./lib/models/weekly_question.dart)
- [Servicio de API](./lib/services/weekly_questions_service.dart)
- [Pantalla principal](./lib/screens/weekly_questions_screen.dart)

## ❓ Problemas comunes

**Problema**: "Error 401 Unauthorized"
**Solución**: Verifica que AuthService esté autenticado antes de navegar

**Problema**: "No hay preguntas disponibles"
**Solución**: Crea preguntas en el catálogo primero (pestaña Catálogo)

**Problema**: "Error al cargar"
**Solución**: Revisa que el WiFi/internet funcione y que el backend esté levantado

## ✅ Checklist de integración

- [ ] Archivo `weekly_question.dart` en `lib/models/`
- [ ] Archivo `weekly_questions_service.dart` en `lib/services/`
- [ ] Pantalla principal en `lib/screens/`
- [ ] Widget card en `lib/widgets/`
- [ ] Rutas agregadas en `main.dart`
- [ ] Navegación (navbar/drawer/botón) configurada
- [ ] Dependencias en `pubspec.yaml`
- [ ] `flutter pub get` ejecutado
- [ ] App compilada sin errores
- [ ] Probada desde el inicio de sesión

---

**¡Listo!** La funcionalidad de Pregunta de la Semana está integrada. 🎉
