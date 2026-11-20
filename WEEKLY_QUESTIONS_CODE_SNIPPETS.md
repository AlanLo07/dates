## Code Snippets - Pregunta de la Semana

Ejemplos de código para diferentes casos de uso.

---

## 📝 Crear Pregunta

```dart
// Usando el servicio directamente
final service = WeeklyQuestionsService.instance;

try {
  final question = await service.createCatalogQuestion(
    text: '¿Cuál es tu sueño más grande?',
    category: 'profundas',
  );
  
  print('Pregunta creada: ${question.id}');
  print('Versión: ${question.version}');
} on ApiException catch (e) {
  if (e.statusCode == 400) {
    print('Validación fallida: ${e.message}');
  } else {
    print('Error: ${e.message}');
  }
}
```

---

## 💬 Responder Pregunta

```dart
// En WeeklyQuestionsAnswerScreen
final service = WeeklyQuestionsService.instance;
final questionId = widget.question.id;
final answerText = _answerController.text;

try {
  final updatedQuestion = await service.submitAnswer(
    questionId: questionId,
    text: answerText,
  );
  
  print('Respuesta guardada');
  print('Status: ${updatedQuestion.status}'); // partial o completed
  
  // Actualizar UI
  setState(() {
    _currentQuestion = updatedQuestion;
  });
} on ApiException catch (e) {
  if (e.isForbidden) {
    print('No puedes responder esta pregunta ahora');
  } else if (e.isConflict) {
    print('Alguien cambió algo, intenta de nuevo');
  }
}
```

---

## 🔄 Obtener Pregunta Actual

```dart
final service = WeeklyQuestionsService.instance;
final authService = AuthService.instance;

try {
  final response = await service.getCurrentQuestion();
  
  print('Semana: ${response.weekKey}');
  print('Zona: ${response.timeZone}');
  print('Usuarios: ${response.users.length}');
  
  if (response.question == null) {
    print('No hay preguntas disponibles esta semana');
    print('Mensaje: ${response.message}');
    return;
  }
  
  final question = response.question!;
  print('Pregunta: ${question.text}');
  print('Puedo responder: ${question.canAnswer}');
  print('Puedo editar: ${question.canEdit}');
  
  // Obtener respuesta de la pareja
  final userSub = authService.user?.sub;
  final partnerSub = response.users
      .firstWhere((u) => u.sub != userSub)
      .sub;
  
  final myAnswer = question.answers[userSub];
  final partnerAnswer = question.answers[partnerSub];
  
  if (myAnswer != null) {
    print('Mi respuesta: ${myAnswer.text}');
    print('¿Fue editada? ${myAnswer.isEdited()}');
  }
  
  if (partnerAnswer != null) {
    print('Respuesta de pareja: ${partnerAnswer.text}');
  } else {
    print('Pareja aún no responde');
  }
} catch (e) {
  print('Error: $e');
}
```

---

## 📚 Listar Catálogo Completo

```dart
final service = WeeklyQuestionsService.instance;
final questions = <CatalogQuestion>[];
String? nextToken;
bool hasMore = true;

while (hasMore) {
  try {
    final response = await service.getCatalog(
      nextToken: nextToken,
    );
    
    questions.addAll(response.items);
    nextToken = response.nextToken;
    hasMore = nextToken != null;
    
    print('Cargadas ${questions.length} preguntas...');
  } catch (e) {
    print('Error: $e');
    break;
  }
}

print('Total de preguntas: ${questions.length}');
```

---

## 🔍 Listar Preguntas por Estado

```dart
final service = WeeklyQuestionsService.instance;

// Solo preguntas completadas
var completed = await service.getQuestions(status: 'completed');
print('Completadas: ${completed.items.length}');

// Preguntas donde yo aún no respondí
var pendingMe = await service.getQuestions(pendingFor: 'me');
print('Pendientes por mí: ${pendingMe.items.length}');

// Preguntas donde mi pareja no respondió
var pendingPartner = await service.getQuestions(pendingFor: 'partner');
print('Pendientes por pareja: ${pendingPartner.items.length}');

// Por categoría
var romantic = await service.getQuestions(category: 'romanticas');
print('Románticas: ${romantic.items.length}');

// Combinado
var deepUnAnswered = await service.getQuestions(
  category: 'profundas',
  status: 'pending',
);
print('Preguntas profundas sin respuestas: ${deepUnAnswered.items.length}');
```

---

## 📊 Obtener Estadísticas

```dart
final service = WeeklyQuestionsService.instance;

try {
  final allQuestions = await service.getQuestions(limit: 100);
  
  int completed = 0;
  int partial = 0;
  int pending = 0;
  Map<String, int> categoryCounts = {};
  
  for (final q in allQuestions.items) {
    switch (q.status) {
      case 'completed':
        completed++;
      case 'partial':
        partial++;
      case 'pending':
        pending++;
    }
    
    final category = q.category;
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
  }
  
  print('=== ESTADÍSTICAS ===');
  print('Completadas: $completed');
  print('Parciales: $partial');
  print('Pendientes: $pending');
  print('Total: ${completed + partial + pending}');
  print('\nPor categoría:');
  categoryCounts.forEach((cat, count) {
    print('  $cat: $count');
  });
} catch (e) {
  print('Error: $e');
}
```

---

## 🎨 Personalizar Colores por Categoría

```dart
// En lib/widgets/weekly_question_card.dart

Color _getCategoryColor() {
  switch (question.category.toLowerCase()) {
    case 'divertidas':
      return Colors.amber[300]!;
    case 'profundas':
      return Colors.indigo[400]!;
    case 'romanticas':
      return Colors.pink[300]!;
    case 'absurdas':
      return Colors.blue[400]!;
    case 'atrevidas':
      return Colors.red[400]!;
    case 'personales':
      return Colors.purple[400]!;
    default:
      return Colors.grey[400]!;
  }
}

// También personalizar en los chips de filtro
FilterChip(
  label: Text(category),
  backgroundColor: _getCategoryColor(),
  selected: _selectedCategory == category,
  onSelected: (_) {
    setState(() => _selectedCategory = category);
  },
)
```

---

## ♻️ Manejar Errores Específicos

```dart
try {
  final question = await service.createCatalogQuestion(
    text: 'Pregunta?',
    category: 'nueva',
  );
} on ApiException catch (e) {
  if (e.statusCode == 400) {
    // Validación: texto muy largo, categoría inválida, etc
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Por favor, verifica tus datos: ${e.message}')),
    );
  } else if (e.statusCode == 401) {
    // No autenticado - ir a login
    Navigator.pushNamed(context, '/login');
  } else if (e.statusCode == 403) {
    // Forbidden - no tiene permisos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tienes permiso para hacer esto')),
    );
  } else if (e.statusCode == 409) {
    // Conflicto - datos desactualizados
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alguien hizo cambios, intenta de nuevo')),
    );
    // Refrescar datos
    _loadCurrentQuestion();
  } else if (e.statusCode == 503) {
    // Servicio no disponible - AWS problem
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servicio temporalmente no disponible')),
    );
  }
} catch (e) {
  // Error no controlado
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error inesperado: $e')),
  );
}
```

---

## 🔄 Refrescar Automáticamente

```dart
// En cualquier pantalla que use WeeklyQuestionsService

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _loadData();
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

@override
Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
  if (state == AppLifecycleState.resumed) {
    // App volvió del background
    print('App reasumida, refrescando datos...');
    await _loadData();
  }
}

Future<void> _loadData() async {
  try {
    final response = await WeeklyQuestionsService.instance.getCurrentQuestion();
    setState(() {
      _response = response;
    });
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

---

## 🎯 Ejemplo Completo: Componente Widget

```dart
import 'package:flutter/material.dart';
import 'package:dates/models/weekly_question.dart';
import 'package:dates/services/weekly_questions_service.dart';

class QuestionOfTheWeekWidget extends StatefulWidget {
  const QuestionOfTheWeekWidget({super.key});

  @override
  State<QuestionOfTheWeekWidget> createState() => _QuestionOfTheWeekWidgetState();
}

class _QuestionOfTheWeekWidgetState extends State<QuestionOfTheWeekWidget> {
  final _service = WeeklyQuestionsService.instance;
  WeeklyQuestion? _question;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _isLoading = true);
      final response = await _service.getCurrentQuestion();
      setState(() {
        _question = response.question;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $_error'),
        ),
      );
    }

    if (_question == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin preguntas esta semana'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(label: Text(_question!.category)),
            const SizedBox(height: 12),
            Text(
              _question!.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estado: ${_question!.status}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Navegar a pantalla de respuesta
              },
              child: const Text('Responder'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🧪 Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dates/services/weekly_questions_service.dart';

void main() {
  test('WeeklyQuestionsService es singleton', () {
    final service1 = WeeklyQuestionsService.instance;
    final service2 = WeeklyQuestionsService.instance;
    expect(service1, service2);
  });

  // Nota: Para tests de integración con API, 
  // necesitarás mockear las respuestas HTTP
}
```

---

Estos snippets cubren los casos de uso más comunes. Adapta según tus necesidades. ¡Éxito! 🚀
