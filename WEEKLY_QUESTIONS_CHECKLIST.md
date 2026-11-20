## ✅ Checklist de Integración y Verificación

Este documento te ayuda a verificar que todo está correctamente integrado.

---

## 📦 Fase 1: Descargar Archivos

- [ ] `lib/models/weekly_question.dart` ✓ Creado
- [ ] `lib/services/weekly_questions_service.dart` ✓ Creado
- [ ] `lib/screens/weekly_questions_screen.dart` ✓ Creado
- [ ] `lib/screens/weekly_questions_detail_screen.dart` ✓ Creado
- [ ] `lib/screens/weekly_questions_create_screen.dart` ✓ Creado
- [ ] `lib/screens/weekly_questions_answer_screen.dart` ✓ Creado
- [ ] `lib/screens/weekly_questions_catalog_screen.dart` ✓ Creado
- [ ] `lib/screens/weekly_questions_history_screen.dart` ✓ Creado
- [ ] `lib/widgets/weekly_question_card.dart` ✓ Creado
- [ ] `test/weekly_questions_model_test.dart` ✓ Creado

---

## 🔧 Fase 2: Verificar Dependencias

Revisa tu `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: 0.20.2                  # ✓ Debe estar
  http: ^1.1.0                  # ✓ Debe estar
  # ... resto de dependencias
```

**Acciones:**
- [ ] Abre `pubspec.yaml`
- [ ] Verifica `intl: 0.20.2`
- [ ] Verifica `http: ^1.1.0`
- [ ] Si falta algo, agrega y ejecuta `flutter pub get`
- [ ] Ejecuta `flutter pub get` de todas formas

---

## 🌍 Fase 3: Configurar Localización

**Archivo:** `lib/main.dart`

**Cambios necesarios:**

```dart
// Agregar imports
import 'package:flutter_localizations/flutter_localizations.dart';

MaterialApp(
  // ... otras propiedades
  
  // Agregar estas líneas
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('es', 'ES'),
    Locale('en', 'US'),
  ],
)
```

**Verificación:**
- [ ] Localizaciones agregadas
- [ ] Locale español ('es', 'ES') configurado
- [ ] No hay errores de compilación

---

## 🛣️ Fase 4: Agregar Rutas

**Archivo:** `lib/main.dart`

**En tu MaterialApp:**

```dart
routes: {
  '/weekly-questions': (_) => const WeeklyQuestionsScreen(),
  // ... tus otras rutas
},
```

**O si usas Navigator 2.0, agrega en tu routing:**

```dart
if (route == '/weekly-questions') {
  return MaterialPageRoute(
    builder: (_) => const WeeklyQuestionsScreen(),
  );
}
```

**Verificación:**
- [ ] Ruta `/weekly-questions` agregada
- [ ] No hay conflicto con otras rutas
- [ ] Import correcto del `WeeklyQuestionsScreen`

---

## 🧭 Fase 5: Agregar Navegación

Elige una de estas opciones:

### Opción A: NavigationBar

```dart
// En tu HomePage o layout principal
navigationBarItems: [
  // ... otros items
  NavigationDestination(
    icon: Icon(Icons.question_answer),
    selectedIcon: Icon(Icons.question_answer),
    label: 'Preguntas',
  ),
],

onDestinationSelected: (index) {
  if (index == 4) { // Ajusta según tu índice
    setState(() => _selectedIndex = index);
  }
},

// En el body, agrega el caso:
case 4:
  return const WeeklyQuestionsScreen();
```

**Verificación:**
- [ ] NavigationDestination agregado
- [ ] Índice correcto en switch
- [ ] Icono visible en la app

### Opción B: Drawer

```dart
Drawer(
  child: ListView(
    children: [
      DrawerHeader(
        // ... tu header
      ),
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
```

**Verificación:**
- [ ] ListTile en el Drawer
- [ ] Navegación funciona
- [ ] Drawer se cierra al navegar

### Opción C: Botón Flotante

```dart
FloatingActionButton(
  onPressed: () => Navigator.pushNamed(context, '/weekly-questions'),
  tooltip: 'Pregunta de la Semana',
  child: Icon(Icons.question_answer),
)
```

**Verificación:**
- [ ] FAB visible
- [ ] Navegación funciona

**Una vez elegida una opción:**
- [ ] Código agregado
- [ ] Import de `WeeklyQuestionsScreen` presente
- [ ] No hay errores de compilación

---

## 🔐 Fase 6: Verificar Autenticación

**Archivo:** `lib/services/auth_service.dart`

Debe tener:
- [ ] `AuthService.instance` disponible (singleton)
- [ ] `user?.sub` accesible (Cognito sub)
- [ ] Método `getValidAccessToken()` que devuelve JWT

**Verificación rápida:**
```dart
// En cualquier pantalla
final authService = AuthService.instance;
print('Usuario: ${authService.user?.sub}');
```

Si esto no imprime nada, el usuario no está autenticado.

---

## 🌐 Fase 7: Verificar ApiConfig

**Archivo:** `lib/services/api_config.dart`

Debe contener:
```dart
class ApiConfig {
  static final ApiConfig instance = ApiConfig._();

  final String baseUrl = 'https://ujq4e9csj9.execute-api.us-east-2.amazonaws.com/';
  // ... otros campos
}
```

**Verificación:**
- [ ] URL correcta (termina en `/`)
- [ ] Accesible desde el navegador (prueba en web)
- [ ] Backend está levantado

---

## 🧪 Fase 8: Pruebas Iniciales

### Compilar sin errores
```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk/ios/web
# (Elige según tu plataforma)
```

**Verificación:**
- [ ] Sin errores de compilación
- [ ] Sin warnings críticos
- [ ] App inicia correctamente

### Pruebas funcionales

**Prueba 1: Acceso a la pantalla**
1. [ ] Abre la app
2. [ ] Navega a "Pregunta de la Semana"
3. [ ] Debería cargar sin error (con spinner o pregunta)

**Prueba 2: Ver pregunta actual**
1. [ ] Si hay pregunta, verás el texto y categoría
2. [ ] Si no hay, verás "No hay preguntas disponibles"
3. [ ] Puedes ver las 3 pestañas (Actual, Catálogo, Historial)

**Prueba 3: Crear pregunta**
1. [ ] Ve a pestaña "Catálogo"
2. [ ] Toca FAB (botón +)
3. [ ] Llena formulario
4. [ ] Toca "Crear Pregunta"
5. [ ] Verás confirmación

**Prueba 4: Responder pregunta**
1. [ ] Ve a pestaña "Actual"
2. [ ] Si puedes responder, haz tap en el área de respuesta
3. [ ] Escribe respuesta
4. [ ] Toca "Guardar Respuesta"
5. [ ] Verás confirmación

**Prueba 5: Ver historial**
1. [ ] Ve a pestaña "Historial"
2. [ ] Deberías ver preguntas (si las hay)
3. [ ] Prueba filtros
4. [ ] Haz tap en una pregunta para ver detalles

---

## 🐛 Fase 9: Debugging

Si algo no funciona, sigue este árbol de decisión:

### Error 401 (Unauthorized)
```
¿Usuario está autenticado?
├─ NO → Ir a login primero
└─ SÍ → Revisar token en AuthService
   └─ ¿Token válido? → Revisar logs AuthenticatedHttpClient
```

### Error 503 (Service Unavailable)
```
¿Backend está levantado?
├─ NO → Iniciar backend
└─ SÍ → ¿URL es correcta?
   └─ Revisar ApiConfig.baseUrl
   └─ Probar URL en navegador
```

### "No hay preguntas disponibles"
```
¿Esto es esperado?
├─ SÍ → Crear preguntas primero (pestaña Catálogo)
└─ NO → ¿Semana sin consultar /current?
   └─ Consultar /current para seleccionar pregunta
```

### Pantalla en blanco
```
¿Hay errores en la consola?
├─ FLUTTER ERRORS → Revisar stack trace
├─ HTTP ERRORS → Revisar logs AuthenticatedHttpClient
└─ NO ERRORS → Revisar initState y build methods
```

**Logs útiles:**
```bash
# Busca estos strings en la consola:
flutter logs | grep -E "\[AuthenticatedHttpClient\]|\[WeeklyQuestionsService\]"
```

---

## 📋 Fase 10: Personalización (Opcional)

- [ ] Cambiar colores en `weekly_question_card.dart`
- [ ] Agregar más categorías
- [ ] Cambiar textos y strings
- [ ] Adaptar tema visual

Referencia: `WEEKLY_QUESTIONS_CODE_SNIPPETS.md`

---

## 📊 Resumen de Integración

| Fase | Estado | Tiempo |
|------|--------|--------|
| 1. Descargar archivos | ⬜ | 2 min |
| 2. Verificar dependencias | ⬜ | 5 min |
| 3. Localización | ⬜ | 2 min |
| 4. Rutas | ⬜ | 2 min |
| 5. Navegación | ⬜ | 5 min |
| 6. Autenticación | ⬜ | 2 min |
| 7. ApiConfig | ⬜ | 1 min |
| 8. Pruebas | ⬜ | 10 min |
| 9. Debugging | ⬜ | según sea necesario |
| 10. Personalización | ⬜ | opcional |

**Tiempo total estimado:** 30-40 minutos

---

## 🎉 ¿Listo?

Cuando todo esté integrado:

✅ App compila sin errores  
✅ Puedes navegar a "Pregunta de la Semana"  
✅ Aparece pregunta o estado vacío  
✅ Puedes crear, responder y ver historial  
✅ Logs en consola muestran operaciones exitosas  

**Próximos pasos:**
- [ ] Leer `WEEKLY_QUESTIONS_INTEGRATION.md` para profundizar
- [ ] Explorar `WEEKLY_QUESTIONS_CODE_SNIPPETS.md` para casos avanzados
- [ ] Personalizar según tu diseño
- [ ] ¡Disfruta la funcionalidad! 🎉

---

**¿Necesitas ayuda?**
- Revisa logs con `flutter logs`
- Busca en `WEEKLY_QUESTIONS_INTEGRATION.md` sección "Debugging"
- Verifica que el backend esté levantado y accesible
- Confirma que estés autenticado en Cognito

¡Éxito! 🚀
