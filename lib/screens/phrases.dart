// lib/screens/hangman_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/phrase.dart';
import '../services/phrases_service.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const Color _violeta = Color(0xFF796B9B);
const Color _lavanda = Color(0xFFD8C9E7);
// const Color _celeste = Color(0xFFA9D1DF);
const Color _malva = Color(0xFFB0B6E8);
const Color _rojo = Color(0xFFE57373);
const Color _verde = Color(0xFF81C784);

class PhrasesScreen extends StatefulWidget {
  const PhrasesScreen({super.key});

  @override
  State<PhrasesScreen> createState() => _PhrasesScreenState();
}

class _PhrasesScreenState extends State<PhrasesScreen>
    with TickerProviderStateMixin {
  // ── Estado del juego ────────────────────────────────────────────────────────
  LovePhrase? _phrase;
  bool _isLoading = true;
  Set<String> _guessed = {};
  int _errors = 0;
  static const int _maxErrors = 6;
  bool _revealed = false; // Si mostramos la respuesta al perder

  // ── Animaciones ─────────────────────────────────────────────────────────────
  late AnimationController _shakeController;
  late AnimationController _winController;
  late Animation<double> _winScale;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _winScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _winController, curve: Curves.elasticOut),
    );
    _loadPhrase();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _winController.dispose();
    super.dispose();
  }

  // ── Lógica ───────────────────────────────────────────────────────────────────
  Future<void> _loadPhrase() async {
    setState(() => _isLoading = true);
    final phrase = await PhrasesService().getRandomPhrase();
    setState(() {
      _phrase = phrase;
      _guessed = {};
      _errors = 0;
      _revealed = false;
      _isLoading = false;
    });
  }

  Future<void> _launchLink() async {
    final url = _phrase?.link ?? '';
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  void _guess(String letter) {
    if (_isGameOver || _guessed.contains(letter)) return;

    setState(() {
      _guessed.add(letter);
      if (!_normalizedText.contains(letter)) {
        _errors++;
        _shakeController.forward(from: 0);
      }
    });

    if (_hasWon) _winController.forward(from: 0);
  }

  // Texto normalizado: solo letras A-Z + espacios, sin tildes
  String get _normalizedText {
    if (_phrase == null) return '';
    return _phrase!.text
        .toUpperCase()
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ñ', 'N');
  }

  // Letras únicas de la frase (excluyendo espacios)
  Set<String> get _phraseLetters =>
      _normalizedText.split('').where((c) => c != ' ').toSet();

  bool get _hasWon =>
      _phraseLetters.isNotEmpty &&
      _phraseLetters.every((l) => _guessed.contains(l));

  bool get _hasLost => _errors >= _maxErrors;

  bool get _isGameOver => _hasWon || _hasLost;

  // ── Keyboard ─────────────────────────────────────────────────────────────────
  static const List<String> _keyboard = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lavanda,
      appBar: AppBar(
        title: const Text(
          '🎯 Adivina la Frase',
          style: TextStyle(color: _violeta, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _violeta),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _violeta),
            tooltip: 'Nueva frase',
            onPressed: _loadPhrase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _violeta))
          : _buildGame(),
    );
  }

  Widget _buildGame() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── Tipo de frase (chip) ────────────────────────────────────────────
          _buildTypeChip(),
          const SizedBox(height: 16),

          // ── Figura del ahorcado ─────────────────────────────────────────────
          _buildHangmanFigure(),
          const SizedBox(height: 16),

          // ── Letras de la frase ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPhraseDisplay(),
          ),
          const SizedBox(height: 20),

          // ── Estado del juego ────────────────────────────────────────────────
          if (_isGameOver) _buildGameOverBanner(),

          // ── Teclado ─────────────────────────────────────────────────────────
          if (!_isGameOver)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: _buildKeyboard(),
            ),

          if (_isGameOver)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              child: ElevatedButton.icon(
                onPressed: _loadPhrase,
                icon: const Icon(Icons.refresh),
                label: const Text('Jugar de nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _violeta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Chip de tipo ─────────────────────────────────────────────────────────────
  Widget _buildTypeChip() {
    return Chip(
      avatar: Text(_phrase!.type.emoji, style: const TextStyle(fontSize: 16)),
      label: Text(
        _phrase!.type.label,
        style: const TextStyle(
          color: _violeta,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: _malva, width: 1.5),
    );
  }

  // ── Figura del ahorcado ───────────────────────────────────────────────────────
  Widget _buildHangmanFigure() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shake = _shakeController.value;
        final offset = shake < 0.25
            ? shake * 12
            : shake < 0.5
            ? (0.5 - shake) * -12
            : shake < 0.75
            ? (shake - 0.5) * 12
            : (1.0 - shake) * -12;
        return Transform.translate(offset: Offset(offset * 3, 0), child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _violeta.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Horca con emoji superpuesto
                SizedBox(
                  width: 120,
                  height: 160,
                  child: Stack(
                    children: [
                      CustomPaint(
                        size: const Size(120, 160),
                        painter: _GallowsPainter(
                          errors: _errors,
                          maxErrors: _maxErrors,
                        ),
                      ),
                      // Emoji encima de la cabeza (cuando hay >= 1 error)
                      if (_errors >= 1)
                        Positioned(
                          // cx = 120 * 0.7 = 84 → centro, headTop+headR = 48
                          left: 84 - 14, // cx - radio_emoji
                          top: 30, // headTop
                          child: Text(
                            _phrase!.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                    ],
                  ),
                ),
                // Panel de info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Errores restantes
                        Row(
                          children: List.generate(_maxErrors, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                i < _errors
                                    ? Icons.favorite_border
                                    : Icons.favorite,
                                color: i < _errors
                                    ? Colors.grey.shade300
                                    : _rojo,
                                size: 20,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Errores: $_errors / $_maxErrors',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Letras incorrectas
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _guessed
                              .where((l) => !_phraseLetters.contains(l))
                              .map(
                                (l) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _rojo.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l,
                                    style: TextStyle(
                                      color: _rojo.withOpacity(0.8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Display de la frase ───────────────────────────────────────────────────────
  Widget _buildPhraseDisplay() {
    final words = _normalizedText.split(' ');
    final revealAll = _hasLost && _revealed;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: words.map((word) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: word.split('').map((letter) {
            final isGuessed = _guessed.contains(letter);
            final show = isGuessed || revealAll;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 22,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _violeta, width: 2)),
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: show
                      ? Text(
                          letter,
                          key: ValueKey(letter),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isGuessed ? _violeta : _rojo,
                          ),
                        )
                      : const SizedBox(height: 22),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // ── Banner de fin de juego ────────────────────────────────────────────────────
  Widget _buildGameOverBanner() {
    if (_hasWon) {
      return ScaleTransition(
        scale: _winScale,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _verde.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _verde, width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                '${_phrase!.emoji} ¡Ganaste!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _violeta,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _phrase!.type == PhraseType.pelicula
                    ? '🎬 ${_phrase!.title}'
                    : '🎵 ${_phrase!.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _violeta,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Minuto: ${_phrase!.minute}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Text(
                _phrase!.credits,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (_phrase!.link.isNotEmpty) ...[
                const SizedBox(height: 14),
                _buildLinkButton(),
              ],
            ],
          ),
        ),
      );
    }

    // Perdió
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _rojo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _rojo.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            children: [
              Text(
                '${_phrase!.emoji} ¡Se acabó!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (!_revealed)
                TextButton(
                  onPressed: () {
                    setState(() => _revealed = true);
                  },
                  child: const Text(
                    '👁 Ver respuesta',
                    style: TextStyle(color: _violeta),
                  ),
                ),
              if (_revealed) ...[
                Text(
                  _phrase!.type == PhraseType.pelicula
                      ? '🎬 ${_phrase!.title}'
                      : '🎵 ${_phrase!.title}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _violeta,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Minuto: ${_phrase!.minute}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  _phrase!.credits,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                if (_phrase!.link.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildLinkButton(),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Botón de link (Spotify / Netflix) ────────────────────────────────────────
  Widget _buildLinkButton() {
    final isSpotify = _phrase!.link.contains('spotify');
    final isNetflix = _phrase!.link.contains('netflix');

    final Color bgColor;
    final String label;
    final IconData icon;

    if (isNetflix) {
      bgColor = const Color(0xFFE50914);
      label = 'Ver en Netflix';
      icon = Icons.play_circle_filled;
    } else if (isSpotify) {
      bgColor = const Color(0xFF1DB954);
      label = 'Escuchar en Spotify';
      icon = Icons.headphones;
    } else if (_phrase!.type == PhraseType.serie) {
      bgColor = const Color(0xFF0F79AF);
      label = 'Ver la serie';
      icon = Icons.tv;
    } else if (_phrase!.type == PhraseType.libro) {
      bgColor = const Color(0xFF795548);
      label = 'Ver el libro';
      icon = Icons.book;
    } else {
      bgColor = _violeta;
      label = 'Abrir enlace';
      icon = Icons.open_in_new;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _launchLink,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // ── Teclado ────────────────────────────────────────────────────────────────────
  Widget _buildKeyboard() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: _keyboard.map((letter) {
        final isGuessed = _guessed.contains(letter);
        final isCorrect = isGuessed && _phraseLetters.contains(letter);
        final isWrong = isGuessed && !_phraseLetters.contains(letter);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: isCorrect
                ? _verde.withOpacity(0.3)
                : isWrong
                ? Colors.grey.shade200
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCorrect
                  ? _verde
                  : isWrong
                  ? Colors.grey.shade300
                  : _malva,
              width: 1.5,
            ),
            boxShadow: isGuessed
                ? []
                : [
                    BoxShadow(
                      color: _violeta.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: isGuessed ? null : () => _guess(letter),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isWrong ? Colors.grey.shade400 : _violeta,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Pintor de la horca ─────────────────────────────────────────────────────────
class _GallowsPainter extends CustomPainter {
  final int errors;
  final int maxErrors;
  final String emoji;

  _GallowsPainter({
    required this.errors,
    required this.maxErrors,
    this.emoji = '😊',
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF796B9B)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // ── Estructura de la horca (siempre visible) ──────────────────────────────
    // Base
    canvas.drawLine(Offset(10, h - 5), Offset(w - 10, h - 5), paint);
    // Palo vertical
    canvas.drawLine(Offset(w / 4, h - 5), Offset(w / 4, 10), paint);
    // Palo horizontal
    canvas.drawLine(Offset(w / 4, 10), Offset(w * 0.7, 10), paint);
    // Cuerda
    canvas.drawLine(Offset(w * 0.7, 10), Offset(w * 0.7, 30), paint);

    // ── Partes del cuerpo según errores ──────────────────────────────────────
    final bodyPaint = Paint()
      ..color = const Color(0xFF796B9B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = w * 0.7; // centro X
    const headR = 18.0;
    const headTop = 30.0;

    if (errors >= 1) {
      // Cabeza (círculo) — el emoji se dibuja aparte
      canvas.drawCircle(Offset(cx, headTop + headR), headR, bodyPaint);
    }
    if (errors >= 2) {
      // Cuerpo
      canvas.drawLine(
        Offset(cx, headTop + headR * 2),
        Offset(cx, headTop + headR * 2 + 40),
        bodyPaint,
      );
    }
    if (errors >= 3) {
      // Brazo izquierdo
      canvas.drawLine(
        Offset(cx, headTop + headR * 2 + 10),
        Offset(cx - 22, headTop + headR * 2 + 30),
        bodyPaint,
      );
    }
    if (errors >= 4) {
      // Brazo derecho
      canvas.drawLine(
        Offset(cx, headTop + headR * 2 + 10),
        Offset(cx + 22, headTop + headR * 2 + 30),
        bodyPaint,
      );
    }
    if (errors >= 5) {
      // Pierna izquierda
      canvas.drawLine(
        Offset(cx, headTop + headR * 2 + 40),
        Offset(cx - 20, h - 10),
        bodyPaint,
      );
    }
    if (errors >= 6) {
      // Pierna derecha
      canvas.drawLine(
        Offset(cx, headTop + headR * 2 + 40),
        Offset(cx + 20, h - 10),
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GallowsPainter old) => old.errors != errors;
}
