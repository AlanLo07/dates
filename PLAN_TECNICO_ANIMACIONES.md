# Plan tecnico de animaciones

## Objetivo
Construir un sistema de motion coherente para toda la app, priorizando:
- Experiencia divertida y emocional.
- Reutilizacion de widgets para no duplicar codigo.
- Rendimiento estable en Android, iOS y Web.

## Estado actual aplicado en codigo
Ya se implemento una primera capa tecnica en estos archivos:
- lib/utils/animations.dart
- lib/widgets/motion/motion_pressable.dart
- lib/widgets/motion/motion_section_reveal.dart
- lib/widgets/motion/ambient_orbs_background.dart
- lib/screens/home.dart
- lib/screens/home/widgets/home_menu_card.dart
- lib/screens/games/games_menu.dart
- lib/screens/phrases/type_phrases.dart
- lib/screens/wedding/wedding.dart
- lib/screens/wedding/widgets/wedding_option_card.dart
- lib/screens/phrases/widgets/friendly_action_button.dart

## Arquitectura de motion

### 1) Motion tokens globales
Ubicacion: lib/utils/animations.dart

Incluye:
- Duraciones estandar: micro, short, medium, long, route.
- Curvas estandar: entrance, emphasized, exit, spring.
- Variantes de navegacion: slide, fade, sharedAxisX.

Regla: toda animacion nueva debe reutilizar estos tokens antes de crear constantes locales.

### 2) Componentes reutilizables

#### MotionPressable
Ubicacion: lib/widgets/motion/motion_pressable.dart

Para:
- Efecto press en botones y cards.
- Hover para web/desktop.
- Haptic feedback en mobile.

#### MotionSectionReveal
Ubicacion: lib/widgets/motion/motion_section_reveal.dart

Para:
- Entradas escalonadas sin repetir animaciones manuales.

#### AmbientOrbsBackground
Ubicacion: lib/widgets/motion/ambient_orbs_background.dart

Para:
- Fondo vivo sutil, con identidad visual.

## Fases de implementacion

### Fase 1: Consistencia base (completada parcialmente)
- Integrar MotionPressable en tarjetas y botones de alto trafico.
- Unificar rutas a sharedAxisX para modulos emocionales.
- Añadir fondos ambientales en Home, Juegos, Frases y Boda.

### Fase 2: Feedback por interaccion (siguiente)
- Home:
  - Animar seccion Cancion de la semana cuando cambia.
- Juegos:
  - Idle animation por tarjeta (dado, ruleta, kamasutra).
- Frases:
  - Extender sistema de aciertos/errores con rachas.
- Boda:
  - Tarjetas completadas con estado visual persistente.

### Fase 3: Hitos y celebraciones
- Confetti minimalista al completar objetivos.
- Micro sonificacion opcional (si se decide habilitar audio UX).
- Badges animados de progreso por modulo.

### Fase 4: Pulido multiplataforma
- Ajustar intensidades en Web (menos blur y sombras).
- Reducir animaciones en dispositivos de gama baja.
- Alinear haptics por tipo de accion.

## Dependencias
No se requiere instalar paquetes adicionales para lo ya implementado.

Paquetes opcionales para la siguiente fase (agregados en pubspec.yaml):
- animations: para patrones Material motion avanzados.
- sensors_plus: para efectos de parallax por inclinacion del dispositivo.

## Checklist de pruebas

### UI/UX manual
- Navegacion entre pantallas mantiene una narrativa visual coherente.
- Todas las cards presionables responden con press/hover/haptic.
- Fondos ambientales no tapan contenido ni afectan legibilidad.

### Rendimiento
- Scroll estable sin saltos visibles.
- No hay jank notable en animaciones de entrada.
- Sin drop de frames durante transiciones de ruta.

### Accesibilidad
- Contraste de texto conservado.
- Elementos tocables con area suficiente.
- Animaciones no bloquean interacciones.

## Propuesta de siguiente iteracion
1. Aplicar MotionPressable en modulo Planes y Calendario.
2. Crear un widget MotionFeedbackBanner reutilizable para acierto/error/aviso.
3. Activar modo de animacion reducida segun preferencia del sistema.
