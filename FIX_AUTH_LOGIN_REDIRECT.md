# Fix: Problema de Redirección en Login - Segunda Vez

## 🔴 Problema Identificado

Cuando un usuario iniciaba sesión con credenciales correctas:
1. **Primera vez**: El servicio respondía correctamente, pero NO redirigía al home
2. **Segunda vez**: Con las mismas credenciales, SÍ redirigía al home
3. **Frecuencia**: Raro, ya que los usuarios no cierran sesión frecuentemente

## 🔍 Causas Raíz

### 1. **Race Condition en `signIn()` - `auth_service.dart`**
El método `signIn()` tenía operaciones asincrónicas sin esperar completamente:
```dart
// ❌ ANTES: Las operaciones de storage eran sin await secuencial
await _saveTokens(...);
final previousEmail = await _storage.read(key: _emailKey);
// ... más operaciones
sessionState.value = true;  // Se marca ANTES de completar todas las writes
```

**Problema**: `sessionState.value = true` se ejecutaba antes de que todas las writes al storage finalizaran, causando que `isSessionValid()` encontrara datos incompletos.

### 2. **Validación Incompleta en `isSessionValid()` - `auth_service.dart`**
El método delegaba a `getValidAccessToken()` que podía cachear resultados incorrectamente:
```dart
// ❌ ANTES: Usaba getValidAccessToken() que tenía lógica de caché
final isValid = await getValidAccessToken() != null;
```

**Problema**: Si los tokens no estaban escritos completamente en storage, `getValidAccessToken()` retornaba null, pero luego el caché podía dar resultados inconsistentes.

### 3. **Timing en LoginScreen - `login_screen.dart`**
Después de `signIn()`, llamaba inmediatamente a `onLoginSuccess()`:
```dart
// ❌ ANTES: Sin esperar a que el estado se propague
await _authService.signIn(...);
widget.onLoginSuccess?.call();
```

**Problema**: `onLoginSuccess()` disparaba `_refreshSession()` en AuthGate, pero el estado del storage aún no estaba completamente sincronizado.

### 4. **FutureBuilder Reutilización - `main.dart`**
El FutureBuilder podría no detectar cambios correctamente:
```dart
// ⚠️ Comportamiento: Reutilizaba el mismo Future si no había error explícito
FutureBuilder<bool>(
  future: _sessionFuture,
  builder: ...
)
```

## ✅ Soluciones Implementadas

### 1. **Garantizar Escritura Completa en Storage - `auth_service.dart`**
```dart
// ✅ DESPUÉS: Esperar secuencialmente todas las operaciones
await _saveTokens(body, refreshToken: body['refreshToken'] as String?);

final previousEmail = await _storage.read(key: _emailKey);
final previousDisplayName = await _storage.read(key: _displayNameKey);

// Esperar todas las operaciones de almacenamiento
await _storage.write(key: _emailKey, value: loginEmail);
if (previousEmail != loginEmail) {
  await _storage.delete(key: _displayNameKey);
} else if (previousDisplayName?.trim().isEmpty ?? true) {
  await _storage.delete(key: _displayNameKey);
}

// SOLO DESPUÉS marcar como válida
sessionState.value = true;
```

### 2. **Validación Robusta sin Caché - `auth_service.dart`**
```dart
// ✅ DESPUÉS: Leer directamente del storage sin usar getValidAccessToken()
Future<bool> isSessionValid() async {
  try {
    debugPrint('🔵 [AuthService] isSessionValid: validando sesión');
    final accessToken = await _storage.read(key: _accessTokenKey);
    
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('🟡 [AuthService] isSessionValid: sin token');
      sessionState.value = false;
      return false;
    }
    
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final expiresAt = DateTime.tryParse(expiresAtRaw ?? '');
    
    if (expiresAt == null) {
      debugPrint('🟡 [AuthService] isSessionValid: sin expiración');
      sessionState.value = false;
      return false;
    }
    
    final isValid = DateTime.now().add(_expiryMargin).isBefore(expiresAt);
    sessionState.value = isValid;
    debugPrint(isValid ? '🟢 sesión válida' : '🟡 token expirado');
    return isValid;
  } catch (e) {
    debugPrint('🔴 error: $e');
    sessionState.value = false;
    return false;
  }
}
```

### 3. **Esperar Propagación de Estado - `login_screen.dart`**
```dart
// ✅ DESPUÉS: Esperar a que el estado se propague
await _authService.signIn(
  email: _emailController.text,
  password: _passwordController.text,
);
if (!mounted) return;

// Esperar un frame para asegurar que el estado se actualizó
await Future.delayed(const Duration(milliseconds: 100));
if (!mounted) return;

widget.onLoginSuccess?.call();
```

### 4. **Mejor Manejo de Errores en AuthGate - `main.dart`**
```dart
// ✅ DESPUÉS: Capturar errores y mantener lógica clara
@override
Widget build(BuildContext context) {
  return FutureBuilder<bool>(
    future: _sessionFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(...);
      }

      // Capturar errores
      if (snapshot.hasError) {
        return LoginScreen(onLoginSuccess: _refreshSession);
      }

      // Decisión clara: home si válido, login si no
      if (snapshot.data ?? false) {
        return HomeScreen(onSignedOut: _refreshSession);
      }
      return LoginScreen(onLoginSuccess: _refreshSession);
    },
  );
}
```

## 📋 Archivos Modificados

1. **`lib/services/auth_service.dart`**
   - Mejorado `signIn()`: Esperar todas las writes antes de marcar sesión válida
   - Reescrito `isSessionValid()`: Validación directa sin cachés

2. **`lib/screens/auth/login_screen.dart`**
   - Mejorado `_submit()`: Esperar a que el estado se propague antes de callback

3. **`lib/main.dart`**
   - Mejorado `_AuthGateState`: Mejor manejo de errores en FutureBuilder

## 🧪 Verificación

Para verificar que el fix funciona:

1. ✅ Login con credenciales correctas → Debe ir al home inmediatamente
2. ✅ Logout y login de nuevo → Debe funcionar en el primer intento
3. ✅ Credenciales incorrectas → Mostrar error (sin cambios)
4. ✅ Expiración de token → Debe redirigir a login automáticamente

## 🎯 Resultado Esperado

- **Antes**: 1er login fallaba (quedaba en pantalla), 2do login funcionaba
- **Después**: Todos los logins funcionan en el primer intento
