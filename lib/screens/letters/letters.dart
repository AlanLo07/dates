// lib/screens/letters/letters.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/carta.dart';
import '../../utils/colors.dart';

class LetterScreen extends StatefulWidget {
  final CartaSorpresa carta;
  const LetterScreen({super.key, required this.carta});

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen>
    with TickerProviderStateMixin {
  bool _isOpened = false;

  // ── Animación del sobre (flip 3D) ─────────────────────────────────────────
  late final AnimationController _flipController;
  late final Animation<double> _flipAngle;

  // ── Animación de aparición del contenido ──────────────────────────────────
  late final AnimationController _contentController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  // ── Audio ─────────────────────────────────────────────────────────────────
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _audioReady = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  // ── Animación de onda del audio ───────────────────────────────────────────
  late final AnimationController _waveController;

  bool get _hasImage => widget.carta.imageUrl.isNotEmpty;
  bool get _hasAudio => widget.carta.audioUrl.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAngle = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    if (_hasAudio) _initAudio();
  }

  // ── Audio setup ───────────────────────────────────────────────────────────
  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer!.setUrl(widget.carta.audioUrl);
      final duration = _audioPlayer!.duration;
      if (mounted) {
        setState(() {
          _total = duration ?? Duration.zero;
          _audioReady = true;
        });
      }

      _audioPlayer!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
          // Cuando termina, regresa al inicio
          if (state.processingState == ProcessingState.completed) {
            _audioPlayer!.seek(Duration.zero);
            _audioPlayer!.pause();
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _audioReady = false);
    }
  }

  Future<void> _toggleAudio() async {
    if (_audioPlayer == null || !_audioReady) return;
    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play();
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _contentController.dispose();
    _waveController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_isOpened) return;
    setState(() => _isOpened = true);
    await _flipController.forward();
    await _contentController.forward();
  }

  Future<void> _close() async {
    if (!_isOpened) return;
    await _audioPlayer?.pause();
    await _contentController.reverse();
    await _flipController.reverse();
    if (mounted) setState(() => _isOpened = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.letterBg,
      appBar: AppBar(
        backgroundColor: AppColors.letterBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.violeta),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.carta.title,
          style: const TextStyle(
            color: AppColors.violeta,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Center(
            child: GestureDetector(
              onTap: _isOpened ? _close : _open,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isOpened ? _buildOpenCard() : _buildEnvelope(),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _isOpened ? 'Toca para cerrar' : 'Toca para abrir 💌',
                style: TextStyle(
                  color: AppColors.violeta.withOpacity(0.5),
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fondo decorativo ──────────────────────────────────────────────────────
  Widget _buildBackground() {
    return CustomPaint(painter: _HeartPatternPainter());
  }

  // ── Sobre cerrado ─────────────────────────────────────────────────────────
  Widget _buildEnvelope() {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (ctx, child) {
        final angle = _flipAngle.value;
        if (angle > math.pi / 2) return const SizedBox.shrink();
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: child,
        );
      },
      child: Container(
        key: const ValueKey('envelope'),
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipPath(
              clipper: _EnvelopeFlapClipper(),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 48,
                    color: Colors.pinkAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.carta.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.violeta,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  // Indicadores de contenido extra
                  if (_hasImage || _hasAudio) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_hasImage)
                          _buildContentBadge(Icons.photo_outlined, 'Foto'),
                        if (_hasImage && _hasAudio) const SizedBox(width: 6),
                        if (_hasAudio)
                          _buildContentBadge(Icons.music_note_rounded, 'Audio'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.pinkAccent),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.pinkAccent),
          ),
        ],
      ),
    );
  }

  // ── Carta abierta ─────────────────────────────────────────────────────────
  Widget _buildOpenCard() {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentSlide,
        child: Container(
          key: const ValueKey('content'),
          width: 340,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.2),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // ── Fondo: foto semi-transparente o blanco ────────────────
                Positioned.fill(child: _buildCardBackground()),

                // ── Contenido sobre el fondo ──────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera
                    _buildCardHeader(),
                    // Separador degradado
                    Container(
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent,
                            AppColors.malva,
                            AppColors.celeste,
                          ],
                        ),
                      ),
                    ),
                    // Mensaje scrolleable
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Text(
                          widget.carta.description,
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: _hasImage
                                ? Colors.white
                                : const Color(0xFF444444),
                            shadows: _hasImage
                                ? [
                                    const Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                    // ── Audio player (si hay audio) ───────────────────────
                    if (_hasAudio) _buildAudioPlayer(),
                    // Footer con fecha
                    _buildCardFooter(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Fondo de la carta ─────────────────────────────────────────────────────
  Widget _buildCardBackground() {
    if (!_hasImage) {
      return Container(color: Colors.white);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto de fondo
        CachedNetworkImage(
          imageUrl: widget.carta.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.white),
          errorWidget: (_, __, ___) => Container(color: Colors.white),
        ),
        // Overlay oscuro para que el texto sea legible
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.60),
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Cabecera de la carta ──────────────────────────────────────────────────
  Widget _buildCardHeader() {
    final textColor = _hasImage ? Colors.white : AppColors.violeta;
    final bgColor = _hasImage
        ? Colors.black.withOpacity(0.25)
        : Colors.pink.shade50;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(color: bgColor),
      child: Row(
        children: [
          const Text('💌', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.carta.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer de la carta ────────────────────────────────────────────────────
  Widget _buildCardFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            widget.carta.date,
            style: TextStyle(
              fontSize: 12,
              color: _hasImage ? Colors.white60 : Colors.grey.shade400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Audio Player ──────────────────────────────────────────────────────────
  Widget _buildAudioPlayer() {
    final bool onImage = _hasImage;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: onImage ? Colors.black.withOpacity(0.35) : Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onImage
              ? Colors.white.withOpacity(0.15)
              : Colors.pink.shade100,
        ),
      ),
      child: Row(
        children: [
          // Botón circular play/pause con animación de onda
          GestureDetector(
            onTap: _toggleAudio,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ondas animadas (solo cuando reproduce)
                  if (_isPlaying) ...[
                    _WaveRing(
                      controller: _waveController,
                      delay: 0.0,
                      color: Colors.pinkAccent,
                    ),
                    _WaveRing(
                      controller: _waveController,
                      delay: 0.33,
                      color: Colors.pinkAccent,
                    ),
                    _WaveRing(
                      controller: _waveController,
                      delay: 0.66,
                      color: Colors.pinkAccent,
                    ),
                  ],
                  // Botón central
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _audioReady
                          ? Colors.pinkAccent
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: !_audioReady
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Barra de progreso + tiempos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Etiqueta
                Text(
                  _isPlaying ? '♪ Reproduciendo...' : '♪ Mensaje de voz',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: onImage ? Colors.white70 : AppColors.violeta,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _total.inMilliseconds > 0
                        ? _position.inMilliseconds / _total.inMilliseconds
                        : 0,
                    minHeight: 4,
                    backgroundColor: onImage
                        ? Colors.white.withOpacity(0.2)
                        : Colors.pink.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.pinkAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Tiempos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 10,
                        color: onImage ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      _formatDuration(_total),
                      style: TextStyle(
                        fontSize: 10,
                        color: onImage ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Widget de onda animada ────────────────────────────────────────────────────
class _WaveRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Color color;

  const _WaveRing({
    required this.controller,
    required this.delay,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        // Offset cíclico con delay
        final progress = ((controller.value + delay) % 1.0);
        final size = 40.0 + progress * 26.0; // crece de 40 a 66
        final opacity = (1.0 - progress) * 0.5; // se desvanece

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(opacity), width: 1.5),
          ),
        );
      },
    );
  }
}

// ── Clip para el flap del sobre ───────────────────────────────────────────────
class _EnvelopeFlapClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.4);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.4);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_EnvelopeFlapClipper old) => false;
}

// ── Fondo con corazones decorativos ──────────────────────────────────────────
class _HeartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pink.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    const emojis = ['♥', '✿', '❀', '♡'];
    final textStyle = TextStyle(
      fontSize: 24,
      color: Colors.pinkAccent.withOpacity(0.08),
    );

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 5; col++) {
        final x = col * (size.width / 4) + (row.isOdd ? 30.0 : 0.0);
        final y = row * 90.0 - 20;
        final emoji = emojis[(row + col) % emojis.length];
        final span = TextSpan(text: emoji, style: textStyle);
        final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
          ..layout();
        tp.paint(canvas, Offset(x, y));
      }
    }
    canvas.drawRect(Rect.zero, paint);
  }

  @override
  bool shouldRepaint(_HeartPatternPainter old) => false;
}
