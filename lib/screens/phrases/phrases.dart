// lib/screens/hangman_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/phrase.dart';
import '../../services/phrases_service.dart';
import "dart:math";
// import 'game/hangman_hint_game.dart';
import 'widgets/friendly_action_button.dart';
import 'widgets/owl_helper_widget.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const Color _violeta = Color(0xFF796B9B);
const Color _lavanda = Color(0xFFD8C9E7);
// const Color _celeste = Color(0xFFA9D1DF);
const Color _malva = Color(0xFFB0B6E8);
const Color _rojo = Color(0xFFE57373);
const Color _verde = Color(0xFF81C784);

class PhrasesScreen extends StatefulWidget {
  final PhraseType type;
  const PhrasesScreen({required this.type, super.key});

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
  final _random = new Random();
  // late final HangmanHintGame _hintGame;

  // ── Animaciones ─────────────────────────────────────────────────────────────
  late AnimationController _shakeController;
  late AnimationController _winController;
  late AnimationController _swingController;
  late Animation<double> _winScale;
  late PhraseType _type;
  String? _lastGuessLetter;
  bool? _lastGuessCorrect;
  int _feedbackTick = 0;
  double _manualSwayDeg = 0;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    // _hintGame = HangmanHintGame();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _winScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _winController, curve: Curves.elasticOut),
    );
    _loadPhrase();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _winController.dispose();
    _swingController.dispose();
    super.dispose();
  }

  // ── Lógica ───────────────────────────────────────────────────────────────────
  Future<void> _loadPhrase() async {
    setState(() => _isLoading = true);
    final phrases = await PhrasesService().getPhrasesByType(_type);
    final phrase = phrases[_random.nextInt(phrases.length)];
    setState(() {
      _phrase = phrase;
      _guessed = {};
      _errors = 0;
      _revealed = false;
      _lastGuessLetter = null;
      _lastGuessCorrect = null;
      _feedbackTick = 0;
      _manualSwayDeg = 0;
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

    final isCorrect = _normalizedText.contains(letter);

    setState(() {
      _guessed.add(letter);
      _lastGuessLetter = letter;
      _lastGuessCorrect = isCorrect;
      _feedbackTick++;
      if (!isCorrect) {
        _errors++;
        _shakeController.forward(from: 0);
        // _hintGame.registerWrongGuess();
      } else {
        // _hintGame.registerCorrectGuess();
      }
    });

    if (isCorrect) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.mediumImpact();
    }

    if (_hasWon) _winController.forward(from: 0);

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_lastGuessLetter == letter) {
          setState(() {
            _lastGuessLetter = null;
            _lastGuessCorrect = null;
          });
        }
      }),
    );
  }

  double get _hangSwayDeg {
    final phase = _swingController.value * pi * 2;
    final autoAmp = _hasLost ? 10.0 : (_errors * 1.2).clamp(0.0, 6.0);
    final autoSway = sin(phase) * autoAmp;
    if (_manualSwayDeg.abs() > 0.03) {
      _manualSwayDeg *= 0.93;
    }
    return (autoSway + _manualSwayDeg).clamp(-20.0, 20.0);
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OwlHelperWidget(
              message: _helperMessage,
              celebrate: _hasWon,
              warning: _hasLost,
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildGuessFeedbackPill(),
          ),
          const SizedBox(height: 10),

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
              child: FriendlyActionButton(
                onPressed: _loadPhrase,
                icon: Icons.refresh,
                label: 'Jugar de nuevo',
                backgroundColor: _violeta,
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
      animation: Listenable.merge([_shakeController, _swingController]),
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
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: _hasLost
                            ? (details) {
                                setState(() {
                                  _manualSwayDeg += details.delta.dx * 0.28;
                                  _manualSwayDeg = _manualSwayDeg.clamp(
                                    -20.0,
                                    20.0,
                                  );
                                });
                              }
                            : null,
                        child: CustomPaint(
                          size: const Size(120, 160),
                          painter: _GallowsPainter(
                            errors: _errors,
                            maxErrors: _maxErrors,
                            emoji: _phrase!.emoji,
                            swayDeg: _hangSwayDeg,
                          ),
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
                        if (_hasLost) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Arrastra el personaje para mover la cuerda',
                            style: TextStyle(
                              color: _violeta.withOpacity(0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
            final highlightedNow =
                _lastGuessCorrect == true &&
                _lastGuessLetter == letter &&
                isGuessed;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 22,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _violeta, width: 2)),
              ),
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: highlightedNow ? 1.18 : 1.0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: show
                        ? Text(
                            letter,
                            key: ValueKey('${letter}_$show'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isGuessed ? _violeta : _rojo,
                            ),
                          )
                        : const SizedBox(height: 22),
                  ),
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

    return FriendlyActionButton(
      onPressed: _launchLink,
      icon: icon,
      label: label,
      backgroundColor: bgColor,
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
        final isLatest = _lastGuessLetter == letter;
        final latestCorrect = isLatest && _lastGuessCorrect == true;
        final latestWrong = isLatest && _lastGuessCorrect == false;

        return TweenAnimationBuilder<double>(
          key: ValueKey('key_${letter}_$_feedbackTick'),
          duration: const Duration(milliseconds: 260),
          tween: Tween<double>(begin: isLatest ? 0.85 : 0.94, end: 1),
          curve: isLatest ? Curves.elasticOut : Curves.easeOutBack,
          builder: (_, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 40,
            height: 44,
            decoration: BoxDecoration(
              color: latestCorrect
                  ? _verde.withOpacity(0.42)
                  : latestWrong
                  ? _rojo.withOpacity(0.25)
                  : isCorrect
                  ? _verde.withOpacity(0.3)
                  : isWrong
                  ? Colors.grey.shade200
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: latestCorrect
                    ? _verde
                    : latestWrong
                    ? _rojo
                    : isCorrect
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGuessFeedbackPill() {
    final letter = _lastGuessLetter;
    final isCorrect = _lastGuessCorrect;

    if (letter == null || isCorrect == null || _isGameOver) {
      return const SizedBox(height: 36);
    }

    final Color color = isCorrect ? _verde : _rojo;
    final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final String text = isCorrect
        ? 'Bien: "$letter" esta en la frase'
        : 'Ups: "$letter" no aparece';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: Container(
        key: ValueKey('feedback_${letter}_${isCorrect ? 1 : 0}_$_feedbackTick'),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.6), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _helperMessage {
    if (_hasWon) {
      return 'Excelente. Descubriste la frase. ¿Quieres otra ronda?';
    }
    if (_hasLost) {
      return 'No pasa nada. Mira pistas y vuelve a intentarlo.';
    }
    if (_errors >= 4) {
      return 'Pista: piensa en el titulo y revisa vocales primero.';
    }
    return 'Soy Lumi, tu guia. Empieza con vocales para avanzar rapido.';
  }
}

// ── Pintor de la horca ─────────────────────────────────────────────────────────
class _GallowsPainter extends CustomPainter {
  final int errors;
  final int maxErrors;
  final String emoji;
  final double swayDeg;

  _GallowsPainter({
    required this.errors,
    required this.maxErrors,
    required this.emoji,
    this.swayDeg = 0,
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

    // ── Partes del cuerpo según errores ──────────────────────────────────────
    final bodyPaint = Paint()
      ..color = const Color(0xFF796B9B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = w * 0.7;
    const headR = 18.0;
    const ropeLength = 20.0;
    final swayRad = swayDeg * (pi / 180);
    final anchor = Offset(cx, 10);

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(swayRad);

    // Cuerda
    canvas.drawLine(const Offset(0, 0), const Offset(0, ropeLength), paint);

    final headCenter = const Offset(0, ropeLength + headR);

    if (errors >= 1) {
      // Cabeza (círculo) — el emoji se dibuja aparte
      canvas.drawCircle(headCenter, headR, bodyPaint);

      final textSpan = TextSpan(
        text: emoji,
        style: const TextStyle(fontSize: 24),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          headCenter.dx - textPainter.width / 2,
          headCenter.dy - textPainter.height / 2,
        ),
      );
    }
    if (errors >= 2) {
      // Cuerpo
      canvas.drawLine(
        Offset(0, ropeLength + headR * 2),
        Offset(0, ropeLength + headR * 2 + 40),
        bodyPaint,
      );
    }
    if (errors >= 3) {
      // Brazo izquierdo
      canvas.drawLine(
        Offset(0, ropeLength + headR * 2 + 10),
        Offset(-22, ropeLength + headR * 2 + 30),
        bodyPaint,
      );
    }
    if (errors >= 4) {
      // Brazo derecho
      canvas.drawLine(
        Offset(0, ropeLength + headR * 2 + 10),
        Offset(22, ropeLength + headR * 2 + 30),
        bodyPaint,
      );
    }
    if (errors >= 5) {
      // Pierna izquierda
      canvas.drawLine(
        Offset(0, ropeLength + headR * 2 + 40),
        Offset(-20, h - 20),
        bodyPaint,
      );
    }
    if (errors >= 6) {
      // Pierna derecha
      canvas.drawLine(
        Offset(0, ropeLength + headR * 2 + 40),
        Offset(20, h - 20),
        bodyPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GallowsPainter old) =>
      old.errors != errors || old.swayDeg != swayDeg || old.emoji != emoji;
}
