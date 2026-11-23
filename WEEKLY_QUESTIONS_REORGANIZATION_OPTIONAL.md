# Reorganización Opcional: Weekly Questions en Subcarpeta

Este documento describe los pasos para reorganizar los archivos de weekly_questions en una subcarpeta dedicada, manteniendo mejor estructura de proyecto.

---

## 🎯 Objetivo

Mover archivos de:
```
lib/screens/
├── weekly_questions_screen.dart
├── weekly_questions_detail_screen.dart
├── weekly_questions_create_screen.dart
├── weekly_questions_answer_screen.dart
├── weekly_questions_catalog_screen.dart
└── weekly_questions_history_screen.dart
```

A:
```
lib/screens/weekly_questions/
├── weekly_questions_screen.dart
├── screens/question_detail_screen.dart
├── screens/question_create_screen.dart
├── screens/question_answer_screen.dart
├── screens/question_catalog_screen.dart
├── screens/question_history_screen.dart
├── index.dart  (opcional - barrel export)
└── README.md
```

---

## 📋 Pasos para Reorganizar

### 1. Crear la Carpeta
```bash
mkdir lib/screens/weekly_questions
```

### 2. Renombrar y Mover Archivos
Los archivos se pueden renombrar para mejor legibilidad:

| Nombre Actual | Nombre Nuevo (opcional) |
|---|---|
| `weekly_questions_screen.dart` | `weekly_questions_screen.dart` (mantener como principal) |
| `weekly_questions_detail_screen.dart` | `screens/question_detail_screen.dart` |
| `weekly_questions_create_screen.dart` | `screens/question_create_screen.dart` |
| `weekly_questions_answer_screen.dart` | `screens/question_answer_screen.dart` |
| `weekly_questions_catalog_screen.dart` | `screens/question_catalog_screen.dart` |
| `weekly_questions_history_screen.dart` | `screens/question_history_screen.dart` |

O, simplemente mover sin renombrar (más simple):
- `weekly_questions_screen.dart` → `lib/screens/weekly_questions/weekly_questions_screen.dart`
- `weekly_questions_detail_screen.dart` → `lib/screens/weekly_questions/weekly_questions_detail_screen.dart`
- etc.

### 3. Actualizar Imports en cada Archivo

#### En `weekly_questions_screen.dart`
```dart
// ANTES:
import 'weekly_questions_detail_screen.dart';
import 'weekly_questions_create_screen.dart';
import 'weekly_questions_answer_screen.dart';
import 'weekly_questions_catalog_screen.dart';
import 'weekly_questions_history_screen.dart';

// DESPUÉS (si se mantienen nombres):
import 'weekly_questions_detail_screen.dart';
import 'weekly_questions_create_screen.dart';
import 'weekly_questions_answer_screen.dart';
import 'weekly_questions_catalog_screen.dart';
import 'weekly_questions_history_screen.dart';

// O si se renombran:
import 'screens/question_detail_screen.dart';
import 'screens/question_create_screen.dart';
import 'screens/question_answer_screen.dart';
import 'screens/question_catalog_screen.dart';
import 'screens/question_history_screen.dart';
```

#### En `home_weekly_questions_card.dart`
```dart
// ANTES:
import '../../weekly_questions_screen.dart';

// DESPUÉS:
import '../../weekly_questions/weekly_questions_screen.dart';
```

### 4. Verificar Otros Imports en el Proyecto
Buscar cualquier otro import a estos archivos:
```bash
grep -r "weekly_questions_screen" lib/
grep -r "weekly_questions_detail" lib/
# ... etc
```

Actualizar cualquier import encontrado.

---

## 📦 Crear Barrel Export (Opcional)

Crear `lib/screens/weekly_questions/index.dart`:

```dart
export 'weekly_questions_screen.dart';
export 'weekly_questions_detail_screen.dart';
export 'weekly_questions_create_screen.dart';
export 'weekly_questions_answer_screen.dart';
export 'weekly_questions_catalog_screen.dart';
export 'weekly_questions_history_screen.dart';
```

Esto permite importar de forma más limpia:
```dart
// En lugar de:
import '../../weekly_questions/weekly_questions_screen.dart';

// Usar:
import '../../weekly_questions/index.dart' as wq;
// y acceder como: wq.WeeklyQuestionsScreen()

// O:
import '../../weekly_questions/index.dart';
// si se usan los nombres directamente
```

---

## 🔄 Cambios en home_weekly_questions_card.dart

```dart
// OPCIÓN 1: Import directo (si se mantienen nombres actuales)
import '../../weekly_questions/weekly_questions_screen.dart';

// OPCIÓN 2: Usar barrel export
import '../../weekly_questions/index.dart';

// En la función:
void _navigateToFullScreen(BuildContext context) {
  Navigator.of(context).push(
    createRoute(
      const WeeklyQuestionsScreen(), 
      motion: AppRouteMotion.sharedAxisX
    ),
  );
}
```

---

## 🧪 Verificación Post-Reorganización

1. **Compilar sin errores**:
   ```bash
   flutter pub get
   flutter analyze
   ```

2. **Verificar navegación**:
   - Desde Home, hacer tap en el card
   - Debe navegar a WeeklyQuestionsScreen
   - Todos los tabs deben funcionar

3. **Verificar imports en los archivos**:
   - Cada pantalla debe importar correctamente sus dependencias
   - WeeklyQuestionsScreen debe poder navegar a las sub-pantallas

4. **Tests**:
   ```bash
   flutter test test/weekly_questions_model_test.dart
   ```

---

## 📝 Notas Importantes

### ⚠️ Circular Imports
Si al reorganizar aparecen circular imports:
1. Verificar que los imports sean relativos correctos (`../`, `../../`, etc.)
2. Asegurar que `home_weekly_questions_card.dart` NO importe nada de las pantallas secundarias
3. Solo `WeeklyQuestionsScreen` debe importar las sub-pantallas

### 💡 Naming Convention
Mantener coherente:
- Si la carpeta es `weekly_questions/`, los archivos pueden ser:
  - `weekly_questions_screen.dart` (pantalla principal)
  - `question_detail_screen.dart` (sub-pantalla)
  - `question_create_screen.dart` (sub-pantalla)
  - etc.

O mantener todos con el prefijo `weekly_questions_` para consistencia.

---

## ✅ Checklist de Reorganización

- [ ] Crear carpeta `lib/screens/weekly_questions/`
- [ ] Mover archivos a la nueva carpeta
- [ ] Actualizar imports en cada archivo (6 pantallas)
- [ ] Actualizar import en `home_weekly_questions_card.dart`
- [ ] Buscar otros imports en el proyecto
- [ ] Crear `index.dart` (opcional)
- [ ] Ejecutar `flutter pub get`
- [ ] Ejecutar `flutter analyze`
- [ ] Compilar y probar navegación
- [ ] Ejecutar tests

---

## 🎯 Resultado Esperado

Una estructura más limpia y organizada:
```
lib/screens/
├── auth/
├── calendar/
├── challenges/
├── checklist/
├── coupons/
├── finances/
├── games/
├── home/
│   └── widgets/
│       └── home_weekly_questions_card.dart
├── letters/
├── memories/
├── phrases/
├── plans/
├── project_class/
├── spotify/
├── wedding/
├── weekly_questions/              ✨ NUEVA CARPETA
│   ├── weekly_questions_screen.dart
│   ├── weekly_questions_detail_screen.dart
│   ├── weekly_questions_create_screen.dart
│   ├── weekly_questions_answer_screen.dart
│   ├── weekly_questions_catalog_screen.dart
│   ├── weekly_questions_history_screen.dart
│   ├── index.dart (opcional)
│   └── README.md (opcional)
└── home.dart
```

---

## 🚀 Cuando Hacer Esta Reorganización

Recomendaciones:
- **Inmediato**: Si la app es pequeña y está en desarrollo temprano
- **Después**: Si la app ya es compleja y otros cambios están en progreso
- **No es Crítico**: La funcionalidad funciona igual sin reorganizar

Esta reorganización es **puramente organizacional** y **no afecta funcionalidad**.
