# Clase: Dart y Flutter explicados con el proyecto "dates"

Esta es una clase práctica que usa **únicamente código real de este repositorio** para enseñar los conceptos de Dart y Flutter. Cada sección explica un concepto y lo muestra con un fragmento tomado directamente del proyecto.

---

## 1. ¿Qué es el proyecto "dates"?

`dates` es una app de pareja hecha en **Flutter** (multiplataforma: Android, iOS, Web, Windows, Linux, macOS — se ve en las carpetas `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`). Sus funcionalidades principales (ver `lib/screens/`) son:

- **Calendario de citas** (`screens/calendar/`) y planes/aventuras (`screens/plans/`).
- **Checklists** genéricas (`screens/checklist/`) y de boda (`screens/wedding/`).
- **Finanzas de pareja** (`screens/finances/`).
- **Spotify** integrado (buscar canciones, reproducir, "canción de la semana") (`screens/spotify/`).
- **Frases de amor / juegos / recuerdos** (`screens/phrases/`, `screens/games/`, `screens/memories/`).
- **Login/registro** con verificación (`screens/auth/`).

El backend **no está en este repo**: la app es un **cliente HTTP** que consume una API REST en **AWS**. Esto se ve en `lib/services/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl =
      'https://ujq4e9csj9.execute-api.us-east-2.amazonaws.com/';

  static const String citasPath = '/planes';
  static const String spotifyPath = '/spotify';
  static const String checklistsPath = '/checklists';
  static const String loginPath = '/auth/login';
  // ...
}
```

El dominio `execute-api...amazonaws.com` es la firma típica de **API Gateway**, que en arquitecturas serverless de AWS normalmente dispara funciones **Lambda** (backend en Python/Node no incluido aquí). Las imágenes (por ejemplo la del héroe en `home.dart`) se sirven desde **S3**:

```dart
const String _heroImageUrl =
    'https://planes-crud-stack-images-052869941322.s3.us-east-2.amazonaws.com/assets/beso.jpeg';
```

Es decir: **Flutter = frontend/cliente**, **AWS (API Gateway + Lambda + S3, probablemente Cognito para auth) = backend**. La app nunca habla directo con una base de datos; siempre pasa por esta API HTTP.

### Estructura de carpetas de `lib/`

```
lib/
  main.dart          -> punto de entrada, arma el MaterialApp y el "AuthGate"
  models/            -> clases de datos (fromJson/toJson)
  services/          -> clientes HTTP hacia la API (uno por recurso)
  screens/           -> pantallas (widgets "página")
  widgets/           -> widgets reutilizables (piezas de UI)
  utils/             -> helpers (colores, animaciones, búsquedas)
  data/              -> contenido estático embebido en la app
```

Este es el patrón clásico: **Model → Service → Screen/Widget**, muy parecido a MVC/MVVM pero simplificado.

---

## 2. Dart: el lenguaje detrás de Flutter

Flutter usa el lenguaje **Dart**. Veamos los conceptos clave con ejemplos reales.

### 2.1 Null-safety (`?`, `!`, `??`)

Dart obliga a declarar si una variable puede ser `null`. En `lib/services/auth_service.dart`:

```dart
class AuthUserInfo {
  final String sub;
  final String email;
  final String name;
  // sin "?" => estos campos NUNCA pueden ser null
}
```

Y en `home.dart`:

```dart
SongOfWeek? _songOfWeek;   // el "?" dice: esto puede ser null
String? _displayName;
```

El operador `??` ("si es null, usa esto") aparece constantemente al parsear JSON, por ejemplo en `checklists_service.dart`:

```dart
final boards = (data['items'] as List<dynamic>? ?? [])
    .map((item) => ChecklistBoard.fromJson(Map<String, dynamic>.from(item as Map)))
    .toList();
```

`data['items']` podría no venir en la respuesta; si es `null`, se usa una lista vacía `[]` en su lugar.

### 2.2 Clases inmutables con `final` + constructores `const`

Los **modelos** (`lib/models/`) casi siempre son clases con campos `final` (no se pueden reasignar tras crear el objeto):

```dart
// lib/models/fecha.dart
class ItemChecklist {
  final String nombre;
  final bool incluido;

  const ItemChecklist({
    required this.nombre,
    this.incluido = false,
  });
```

- `final` → inmutable, se asigna una sola vez.
- `required` → parámetro nombrado obligatorio.
- `this.incluido = false` → valor por defecto.
- `const` en el constructor → si todos los campos son constantes, Dart puede crear el objeto en tiempo de compilación (más eficiente).

### 2.3 `factory` constructors para parsear JSON

Todos los modelos que vienen de la API en AWS usan un patrón `fromJson` / `toJson` para convertir entre el `Map<String, dynamic>` que llega por HTTP y objetos Dart tipados:

```dart
factory ItemChecklist.fromJson(Map<String, dynamic> json) {
  return ItemChecklist(
    nombre: (json['nombre'] ?? '').toString(),
    incluido: json['incluido'] == true,
  );
}

Map<String, dynamic> toJson() {
  return {'nombre': nombre, 'incluido': incluido};
}
```

`factory` se usa porque no siempre construye una instancia "nueva" directa: a veces decide, valida o transforma datos antes de llamar al constructor real. En este proyecto, **el patrón se repite en cada modelo** (`ChecklistBoard`, `SpotifyTrack`, `AuthUserInfo`, etc.), así que aprenderlo una vez sirve para leer todo `lib/models/`.

### 2.4 Async/await y `Future`

Cualquier llamada de red es asíncrona. En `checklists_service.dart`:

```dart
Future<List<ChecklistBoard>> getChecklists() async {
  final response = await _client.get(_uri(''), headers: _headers);
  final data = _decode(response);
  final boards = (data['items'] as List<dynamic>? ?? [])
      .map((item) => ChecklistBoard.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
  return boards;
}
```

- `Future<T>` = "una promesa de un valor `T` que llegará en el futuro" (aquí, una lista de tableros).
- `async` marca la función como asíncrona.
- `await` pausa la ejecución de esa función (no del hilo completo) hasta que la petición HTTP responda.

Quien llama a `getChecklists()` también debe usar `await` o `.then(...)`.

### 2.5 `Stream` para valores que cambian en el tiempo

En `home.dart`, el contador de "tiempo juntos" se actualiza cada segundo usando un `Stream`:

```dart
late Stream<Duration> _counterStream;

_counterStream = Stream.periodic(
  const Duration(seconds: 1),
  (_) => _calcDuration(),
);
```

A diferencia de `Future` (un solo valor futuro), `Stream` emite **múltiples valores a lo largo del tiempo** — ideal para un reloj o contador en vivo.

### 2.6 Excepciones personalizadas

El proyecto define excepciones propias para diferenciar errores de red de errores de lógica. Ejemplo en `checklists_service.dart`:

```dart
class ChecklistApiException implements Exception {
  ChecklistApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;

  @override
  String toString() => 'ChecklistApiException($statusCode): $message';
}
```

Esto permite capturar específicamente errores de la API de checklists (`try { ... } on ChecklistApiException catch (e) { ... }`) distinto de otros errores.

---

## 3. Flutter: widgets, estado y navegación

### 3.1 Todo es un widget

Flutter construye la UI componiendo widgets. Hay dos tipos base:

- **`StatelessWidget`**: no cambia con el tiempo (o su cambio depende solo de props externas). Ejemplo, `MyApp` en `main.dart`:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Citas',
      // ...
      home: const AuthGate(),
    );
  }
}
```

- **`StatefulWidget`**: tiene un objeto `State` asociado que puede cambiar y "redibujar" la UI. Ejemplo, `HomeScreen`:

```dart
class HomeScreen extends StatefulWidget {
  final VoidCallback? onSignedOut;
  const HomeScreen({super.key, this.onSignedOut});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SongOfWeek? _songOfWeek;
  bool _songLoading = true;
  // ...

  @override
  void initState() {
    super.initState();
    _loadSong();
    _loadWeeklyPhrases();
    _loadDisplayName();
  }
```

`initState()` corre **una sola vez**, cuando el widget se crea — es el lugar típico para disparar llamadas HTTP iniciales.

### 3.2 `setState` = "algo cambió, redibuja"

Cuando un dato cargado de la API llega, hay que avisarle a Flutter que redibuje. En `home.dart`:

```dart
Future<void> _loadDisplayName() async {
  final cachedName = await _authService.getDisplayName();
  if (mounted) setState(() => _displayName = cachedName);

  final me = await _authService.getMe();
  if (mounted && me != null && me.name.isNotEmpty) {
    setState(() => _displayName = me.name);
  }
}
```

`mounted` se revisa antes de `setState` porque el widget pudo haberse destruido (usuario navegó a otra pantalla) mientras la petición HTTP seguía en curso — llamar `setState` sobre un widget destruido lanza un error.

### 3.3 `FutureBuilder` / control de sesión con `AuthGate`

`main.dart` decide qué pantalla mostrar (login vs. home) usando un `Future<bool>` que valida la sesión guardada:

```dart
class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService.instance;
  late Future<bool> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = _authService.isSessionValid();
    _authService.sessionState.addListener(_onSessionChanged);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data ?? false) {
          return HomeScreen(onSignedOut: _refreshSession);
        }
        return LoginScreen(onLoginSuccess: _refreshSession);
      },
    );
  }
}
```

`FutureBuilder` reconstruye su UI automáticamente según el estado del `Future`: cargando → `CircularProgressIndicator`; resuelto → la pantalla que corresponda. Esto evita manejar `setState` manualmente para este caso.

### 3.4 `ValueNotifier` como estado global simple

`AuthService.sessionState` (usado arriba con `addListener`) es un patrón típico para **estado compartido entre widgets** sin librerías externas: un `ValueNotifier<bool>` que cualquier widget puede escuchar para reaccionar a login/logout.

### 3.5 Tema y `MaterialApp`

El estilo visual (colores, tipografía) se centraliza una sola vez en `main.dart`:

```dart
const Color lavandaPalida = Color(0xFFD8C9E7);
const Color malvaSuave = Color(0xFFB0B6E8);
const Color azulCelestePastel = Color(0xFFA9D1DF);
const Color violetaProfundo = Color(0xFF796B9B);

theme: ThemeData(
  primaryColor: malvaSuave,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.blue,
    accentColor: azulCelestePastel,
    backgroundColor: lavandaPalida,
  ).copyWith(surface: lavandaPalida, onSurface: violetaProfundo),
  useMaterial3: true,
),
```

Cualquier widget puede acceder a estos colores del tema con `Theme.of(context).colorScheme`, en vez de repetir códigos de color por toda la app.

### 3.6 Internacionalización (i18n)

El proyecto está fijado a español con soporte de `intl`:

```dart
await initializeDateFormatting('es_ES');
// ...
locale: const Locale('es', 'ES'),
supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

Esto habilita formatos de fecha/hora en español (relevante porque toda la app gira en torno a un calendario de citas).

---

## 4. Networking: cómo la app habla con AWS

### 4.1 Un `Service` por recurso

Cada dominio de negocio tiene su propio archivo en `lib/services/` que encapsula las llamadas HTTP a un path de `ApiConfig`. Patrón general (visto en `ChecklistsService`, y también en `spotify_service.dart`, `finances_service.dart`, etc.):

```dart
class ChecklistsService {
  final String _baseUrl = ApiConfig.baseUrl + ApiConfig.checklistsPath;
  final http.Client _client = http.Client();

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded = response.body.isEmpty ? {} : jsonDecode(response.body);
    final data = Map<String, dynamic>.from(decoded as Map);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChecklistApiException(
        data['error']?.toString() ?? 'Error en Checklists API',
        response.statusCode,
      );
    }
    return data;
  }
```

Ventajas de este patrón:
1. Las **screens nunca arman URLs a mano** — solo llaman métodos del servicio (`getChecklists()`, `createChecklist()`...).
2. El **manejo de errores HTTP está centralizado** en `_decode`, no repetido en cada pantalla.
3. Si cambia el path del backend en AWS, solo se toca `ApiConfig`.

### 4.2 Cliente HTTP autenticado

`checklists_service.dart` no importa `package:http` directo, sino un wrapper propio:

```dart
import 'authenticated_http_client.dart' as http;
```

Esto sugiere que `lib/services/authenticated_http_client.dart` intercepta cada request para **inyectar el token de sesión** (guardado por `AuthService` con `flutter_secure_storage`) antes de llegar a AWS, y probablemente refresca el token si expiró. Así ningún servicio necesita manejar el header `Authorization` manualmente.

### 4.3 Logs con semáforos (convención del proyecto)

Los servicios usan `debugPrint` con emojis como semáforo visual de severidad, por ejemplo en `getChecklists()`:

```dart
debugPrint('🔵 [ChecklistsService] getChecklists: GET iniciado');
final response = await _client.get(_uri(''), headers: _headers);
debugPrint('⚪️ [ChecklistsService] getChecklists: respuesta HTTP ${response.statusCode}');
final data = _decode(response);
// ...
debugPrint('🟢 [ChecklistsService] getChecklists: parseados ${boards.length} tableros');
```

Convención: 🔵 acción relevante iniciada, ⚪️ info no crítica (ej. status code crudo), 🟢 éxito, 🔴 error/excepción. Ayuda a leer los logs de consola rápidamente por color/urgencia sin abrir un debugger.

---

## 5. Compilación condicional (una plataforma vs. otra)

El proyecto corre en Web y en apps nativas, pero algunas librerías (como el SDK de reproducción de Spotify) **solo existen en la Web**. La solución en Dart es tener dos implementaciones y un archivo "switch":

```dart
// spotify_web_player.dart
export 'spotify_web_player_stub.dart'
    if (dart.library.js_util) 'spotify_web_player_web.dart';
```

- En Web, el compilador encuentra `dart.library.js_util` disponible y usa la implementación real (`_web.dart`, con interoperabilidad JS hacia `Spotify.Player`).
- En móvil/desktop, esa librería no existe, así que usa el `_stub.dart` (una versión "vacía" que reporta `isSupported = false`).

Así el resto de la app (`SpotifyPlayerBar`) puede llamar siempre a la misma API sin `if (kIsWeb)` repetido por todos lados.

---

## 6. Resumen mental (para repasar)

| Concepto Dart/Flutter | Dónde se usa en el proyecto |
|---|---|
| `StatelessWidget` | `MyApp` en `main.dart` |
| `StatefulWidget` + `State` | `HomeScreen`/`_HomeScreenState` |
| `initState()` | Disparar cargas iniciales (canción, frases, nombre) |
| `setState()` | Refrescar UI tras `await` de una llamada HTTP |
| `Future<T>` / `async`/`await` | Todos los métodos de `services/*.dart` |
| `Stream` | Contador de "tiempo juntos" en `home.dart` |
| `FutureBuilder` | `AuthGate` para decidir Login vs Home |
| `ValueNotifier` | `AuthService.sessionState` |
| `factory` + `fromJson`/`toJson` | Todos los modelos en `lib/models/` |
| Excepciones personalizadas | `ChecklistApiException`, `AuthException`, etc. |
| Compilación condicional | `spotify_web_player.dart` (web vs. stub) |
| Cliente HTTP centralizado | `authenticated_http_client.dart` + `ApiConfig` |
| Backend en AWS | `ApiConfig.baseUrl` (API Gateway) + S3 para imágenes |

---

## 7. Mini-ejercicio para practicar

1. Abre [lib/services/finances_service.dart](lib/services/finances_service.dart) y compara su estructura con `ChecklistsService`: ¿repite el mismo patrón `_uri`, `_decode`, `debugPrint` con semáforos?
2. Elige un modelo en `lib/models/` que no se haya mostrado aquí y encuentra su `factory .fromJson`. Identifica qué pasa si un campo del JSON viene `null`.
3. Busca otra pantalla `StatefulWidget` (por ejemplo en `lib/screens/calendar/`) e identifica: ¿qué carga en `initState()`? ¿dónde llama `setState`?

Con estos tres pasos, se cubre el ciclo completo del proyecto: **modelo → servicio (AWS) → pantalla con estado**.
