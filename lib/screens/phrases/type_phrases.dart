import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../utils/animations.dart';
import '../../utils/colors.dart';
import '../../models/phrase.dart';
import '../../services/phrases_service.dart';
import 'phrases.dart';

class TypePhrasesScreen extends StatefulWidget {
  const TypePhrasesScreen({super.key});

  @override
  State<TypePhrasesScreen> createState() => _TypePhrasesScreenState();
}

class _TypePhrasesScreenState extends State<TypePhrasesScreen> {
  // Parámetros reutilizables para aparición escalonada del grid.
  static const Duration _kCardFade = Duration(milliseconds: 360);
  static const Duration _kCardSlide = Duration(milliseconds: 420);
  static const Duration _kCardStagger = Duration(milliseconds: 70);

  List<LovePhrase>? _items;
  bool _isLoading = true;
  String? _error;

  // ── Configuración de Categorías (Mantenible y Escalable) ─────────────────
  static const List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Películas',
      'icono': Icons.movie_filter,
      'tipo': 'pelicula',
      'emoji': '🎬',
      'color': Color(0xFFFFB74D),
    },
    {
      'nombre': 'Canciones',
      'icono': Icons.music_note,
      'tipo': 'cancion',
      'emoji': '🎧',
      'color': Color(0xFFF06292),
    },
    {
      'nombre': 'Libros',
      'icono': Icons.auto_stories,
      'tipo': 'libro',
      'emoji': '📖',
      'color': Color(0xFF81C784),
    },
    {
      'nombre': 'Series',
      'icono': Icons.live_tv,
      'tipo': 'serie',
      'emoji': '📺',
      'color': Color(0xFF7986CB),
    },
    {
      'nombre': 'Pareja',
      'icono': Icons.favorite,
      'tipo': 'pareja',
      'emoji': '👩‍❤️‍👨',
      'color': Color(0xFFE57373),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<LovePhrase> data = await PhrasesService().getPhrases();
      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "No pudimos cargar tus recuerdos. Intenta de nuevo.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Nuestro Legado',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.violeta),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.violeta,
        ),
      );
    }

    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _loadData);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95, // Un poco más alto para dar aire al texto
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
        final count =
            _items
                ?.where(
                  (i) => PhraseTypeX.fromPhraseType(i.type) == cat['tipo'],
                )
                .length ??
            0;

        return CategoryCard(
          nombre: cat['nombre'],
          emoji: cat['emoji'],
          color: cat['color'],
          count: count,
          onTap: () => Navigator.push(
            context,
            createRoute(
              PhrasesScreen(
                type: PhraseTypeX.fromString(cat['tipo'] as String),
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(
              delay: _kCardStagger * index,
              duration: _kCardFade,
            )
            .slideY(
              begin: 0.10,
              delay: _kCardStagger * index,
              duration: _kCardSlide,
            );
      },
    );
  }
}

// ── Widgets de Apoyo (Clean Code) ──────────────────────────────────────────

class CategoryCard extends StatelessWidget {
  final String nombre;
  final String emoji;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.nombre,
    required this.emoji,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 12),
            Text(
              nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.violeta,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count elementos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.violeta),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
