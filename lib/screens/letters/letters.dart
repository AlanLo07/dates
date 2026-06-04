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

  // ── Animación del sobre (flip 3D) ──────────────────────────────────────────
  late final AnimationController _flipController;
  late final Animation<double> _flipAngle;

  // ── Animación de aparición del contenido ───────────────────────────────────
  late final AnimationController _contentController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  // ── Audio ──────────────────────────────────────────────────────────────────
  AudioPlayer? _audioPlayer;

  // Estados posibles del audio
  _AudioState _audioState = _AudioState.idle;
  String? _audioError; // mensaje de error detallado para debug

  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  // ── Animación de onda ──────────────────────────────────────────────────────
  late final AnimationController _waveController;

  bool get _hasImage => widget.carta.imageUrl.isNotEmpty;
  bool get _hasAudio => widget.carta.audioUrl.isNotEmpty;
  bool get _isPlaying => _audioState == _AudioState.playing;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAngle = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    if (_hasAudio) _initAudio();
  }

  // ── Audio setup — con debug detallado ─────────────────────────────────────
  Future<void> _initAudio() async {
    setState(() => _audioState = _AudioState.loading);

    _audioPlayer = AudioPlayer();

    try {
      debugPrint('[Audio] Iniciando carga: ${widget.carta.audioUrl}');

      // Escuchar duración via stream (más confiable que .duration post-setUrl)
      _audioPlayer!.durationStream.listen((d) {
        if (d != null && mounted) {
          debugPrint('[Audio] Duración recibida: ${d.inSeconds}s');
          setState(() => _total = d);
        }
      });

      _audioPlayer!.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _audioPlayer!.playerStateStream.listen((state) {
        if (!mounted) return;
        debugPrint(
          '[Audio] Estado: playing=${state.playing} '
          'processingState=${state.processingState}',
        );
        setState(() {
          if (state.playing) {
            _audioState = _AudioState.playing;
          } else if (state.processingState == ProcessingState.completed) {
            _audioState = _AudioState.ready;
            _audioPlayer!.seek(Duration.zero);
          } else if (_audioState == _AudioState.playing) {
            _audioState = _AudioState.ready;
          }
        });
      });

      // Errores del player en stream
      _audioPlayer!.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace st) {
          debugPrint('[Audio] playbackEventStream error: $e\n$st');
          if (mounted) {
            setState(() {
              _audioState = _AudioState.error;
              _audioError = _describeAudioError(e);
            });
          }
        },
      );

      await _audioPlayer!.setUrl(
        widget.carta.audioUrl,
        // Preload para detectar errores de red/formato antes de que el usuario pulse play
        preload: true,
      );

      debugPrint('[Audio] setUrl completado sin excepciones');

      if (mounted) setState(() => _audioState = _AudioState.ready);
    } on PlayerException catch (e, st) {
      // Error de just_audio: formato no soportado, URL inaccesible, codec, etc.
      debugPrint(
        '[Audio] PlayerException\n'
        '  code    : ${e.code}\n'
        '  message : ${e.message}\n'
        '  $st',
      );
      if (mounted) {
        setState(() {
          _audioState = _AudioState.error;
          _audioError =
              'PlayerException [${e.code}]: ${e.message ?? "sin detalle"}';
        });
      }
    } on PlayerInterruptedException catch (e, st) {
      debugPrint('[Audio] PlayerInterruptedException: $e\n$st');
      if (mounted) {
        setState(() {
          _audioState = _AudioState.error;
          _audioError = 'Reproducción interrumpida: $e';
        });
      }
    } catch (e, st) {
      // Cualquier otro error (red, permisos, formato desconocido…)
      debugPrint('[Audio] Error genérico (${e.runtimeType}): $e\n$st');
      if (mounted) {
        setState(() {
          _audioState = _AudioState.error;
          _audioError = '${e.runtimeType}: $e';
        });
      }
    }
  }

  /// Convierte un error de audio a un mensaje legible para mostrar en pantalla.
  String _describeAudioError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('404') || s.contains('not found')) {
      return 'Archivo no encontrado (404). Verifica la URL del audio.';
    }
    if (s.contains('403') || s.contains('forbidden')) {
      return 'Acceso denegado (403). Revisa los permisos del bucket S3.';
    }
    if (s.contains('codec') || s.contains('format') || s.contains('mime')) {
      return 'Formato de audio no soportado. Usa MP3 o AAC/M4A.';
    }
    if (s.contains('network') ||
        s.contains('socket') ||
        s.contains('connection')) {
      return 'Error de red. Verifica tu conexión a internet.';
    }
    return e.toString();
  }

  Future<void> _toggleAudio() async {
    if (_audioPlayer == null || _audioState == _AudioState.error) return;
    if (_audioState == _AudioState.loading) return;

    try {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } catch (e, st) {
      debugPrint('[Audio] Error en toggle: $e\n$st');
    }
  }

  Future<void> _seekTo(double value) async {
    if (_total == Duration.zero) return;
    final target = Duration(
      milliseconds: (value * _total.inMilliseconds).round(),
    );
    await _audioPlayer?.seek(target);
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.letterBg,
      // AppBar minimalista — solo flecha y título
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.violeta,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.carta.title,
          style: const TextStyle(
            color: AppColors.violeta,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Fondo con patrón de corazones
          Positioned.fill(child: CustomPaint(painter: _HeartPatternPainter())),

          // Hint de interacción (abajo, fuera de la carta)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  Icon(
                    _isOpened
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.violeta.withOpacity(0.3),
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isOpened ? 'Toca para cerrar' : 'Toca para abrir 💌',
                    style: TextStyle(
                      color: AppColors.violeta.withOpacity(0.45),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sobre / carta centrado
          Center(
            child: GestureDetector(
              onTap: _isOpened ? _close : _open,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isOpened ? _buildOpenCard() : _buildEnvelope(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sobre cerrado ──────────────────────────────────────────────────────────
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
        width: math.min(MediaQuery.of(context).size.width * 0.82, 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.18),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flap del sobre
            ClipPath(
              clipper: _EnvelopeFlapClipper(),
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.pink.shade100, Colors.pink.shade50],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Text('💌', style: TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),

            // Cuerpo del sobre
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: Column(
                children: [
                  // Sello decorativo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.pink.shade200,
                        width: 1.5,
                      ),
                      color: Colors.pink.shade50,
                    ),
                    child: const Center(
                      child: Text('✉️', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.carta.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.violeta,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Fecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: Colors.pink.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.carta.date,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.pink.shade300,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // Badges de contenido extra
                  if (_hasImage || _hasAudio) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_hasImage) _buildContentBadge('📷', 'Foto'),
                        if (_hasImage && _hasAudio) const SizedBox(width: 8),
                        if (_hasAudio) _buildContentBadge('🎧', 'Audio'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Indicador "toca para abrir"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pink.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: Colors.pinkAccent.shade100,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Abrir carta',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.pinkAccent.shade200,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.pink.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Carta abierta ──────────────────────────────────────────────────────────
  Widget _buildOpenCard() {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _contentOpacity,
      child: SlideTransition(
        position: _contentSlide,
        child: Container(
          key: const ValueKey('content'),
          width: math.min(screenW * 0.92, 380),
          constraints: BoxConstraints(maxHeight: screenH * 0.80),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.15),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Fondo
                Positioned.fill(child: _buildCardBackground()),

                // Contenido
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCardHeader(),
                    // Separador degradado
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.pinkAccent,
                            AppColors.malva,
                            AppColors.celeste,
                          ],
                        ),
                      ),
                    ),
                    // Mensaje scrolleable — con indicador de scroll
                    Flexible(
                      child: _ScrollFadeWrapper(
                        hasImage: _hasImage,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                          child: Text(
                            widget.carta.description,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.75,
                              color: _hasImage
                                  ? Colors.white
                                  : const Color(0xFF3D3D3D),
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
                    ),
                    // Audio player
                    if (_hasAudio) _buildAudioPlayer(),
                    // Footer
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

  Widget _buildCardBackground() {
    if (!_hasImage) return Container(color: Colors.white);
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: widget.carta.imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: Colors.white),
          errorWidget: (_, __, ___) => Container(color: Colors.white),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.30),
                Colors.black.withOpacity(0.55),
                Colors.black.withOpacity(0.72),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader() {
    final onImage = _hasImage;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: onImage ? Colors.black.withOpacity(0.22) : Colors.pink.shade50,
      ),
      child: Row(
        children: [
          const Text('💌', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.carta.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: onImage ? Colors.white : AppColors.violeta,
                letterSpacing: 0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Botón cerrar explícito
          GestureDetector(
            onTap: _close,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: onImage
                    ? Colors.white.withOpacity(0.15)
                    : Colors.pink.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: onImage ? Colors.white70 : Colors.pinkAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            Icons.favorite,
            size: 10,
            color: _hasImage ? Colors.white38 : Colors.pink.shade200,
          ),
          const SizedBox(width: 5),
          Text(
            widget.carta.date,
            style: TextStyle(
              fontSize: 11,
              color: _hasImage ? Colors.white54 : Colors.grey.shade400,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Audio Player ───────────────────────────────────────────────────────────
  Widget _buildAudioPlayer() {
    final onImage = _hasImage;
    final bgColor = onImage
        ? Colors.black.withOpacity(0.32)
        : Colors.pink.shade50;
    final borderColor = onImage
        ? Colors.white.withOpacity(0.12)
        : Colors.pink.shade100;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Botón play/pause con ondas
              _buildPlayButton(onImage),
              const SizedBox(width: 12),
              // Info + barra de progreso
              Expanded(child: _buildProgressSection(onImage)),
            ],
          ),

          // ── Panel de error debug (solo visible en error) ───────────────
          if (_audioState == _AudioState.error && _audioError != null)
            _buildErrorPanel(),
        ],
      ),
    );
  }

  Widget _buildPlayButton(bool onImage) {
    final isError = _audioState == _AudioState.error;
    final isLoading = _audioState == _AudioState.loading;

    return GestureDetector(
      onTap: isError || isLoading ? null : _toggleAudio,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ondas animadas
            if (_isPlaying) ...[
              _WaveRing(controller: _waveController, delay: 0.0),
              _WaveRing(controller: _waveController, delay: 0.33),
              _WaveRing(controller: _waveController, delay: 0.66),
            ],
            // Botón central
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red.shade300
                    : isLoading
                    ? Colors.grey.shade300
                    : Colors.pinkAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!isError && !isLoading)
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.40),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                ],
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : isError
                  ? const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(bool onImage) {
    final labelColor = onImage ? Colors.white70 : AppColors.violeta;
    final timeColor = onImage ? Colors.white54 : Colors.grey.shade500;
    final trackBg = onImage
        ? Colors.white.withOpacity(0.18)
        : Colors.pink.shade100;

    final progress = _total.inMilliseconds > 0
        ? _position.inMilliseconds / _total.inMilliseconds
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Etiqueta
        Text(
          _audioState == _AudioState.loading
              ? '⏳ Cargando audio...'
              : _audioState == _AudioState.error
              ? '⚠️ Error de audio'
              : _isPlaying
              ? '♪ Reproduciendo...'
              : '♪ Mensaje de voz',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: labelColor,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 7),
        // Seekbar interactiva
        GestureDetector(
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localX = d.localPosition.dx.clamp(0, box.size.width);
            _seekTo(localX / box.size.width);
          },
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localX = d.localPosition.dx.clamp(0, box.size.width);
            _seekTo(localX / box.size.width);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: trackBg,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.pinkAccent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        // Tiempos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(_position),
              style: TextStyle(fontSize: 10, color: timeColor),
            ),
            Text(
              _formatDuration(_total),
              style: TextStyle(fontSize: 10, color: timeColor),
            ),
          ],
        ),
      ],
    );
  }

  /// Panel de debug — visible solo cuando hay un error de audio.
  /// Muestra el error exacto para que puedas diagnosticar el problema.
  Widget _buildErrorPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report_outlined,
                size: 13,
                color: Colors.red.shade400,
              ),
              const SizedBox(width: 5),
              Text(
                'Debug — Error de audio',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _audioError ?? 'Error desconocido',
            style: TextStyle(
              fontSize: 10,
              color: Colors.red.shade700,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          // Sugerencias automáticas según el error
          ..._suggestionsForError(_audioError ?? '').map(
            (s) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '→ ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _suggestionsForError(String error) {
    final e = error.toLowerCase();
    final suggestions = <String>[];
    if (e.contains('403') || e.contains('forbidden')) {
      suggestions.add(
        'Revisa que el bucket S3 tenga CORS configurado y el objeto sea público o usa URL firmada.',
      );
    }
    if (e.contains('404') || e.contains('not found')) {
      suggestions.add(
        'El archivo no existe en esa URL. Verifica la ruta en DynamoDB/S3.',
      );
    }
    if (e.contains('codec') || e.contains('format') || e.contains('mime')) {
      suggestions.add(
        'just_audio soporta MP3, AAC/M4A y OGG. Convierte el archivo si es WAV u otro formato.',
      );
    }
    if (e.contains('network') || e.contains('socket')) {
      suggestions.add(
        'Verifica conectividad. En simulador, prueba con red real.',
      );
    }
    if (suggestions.isEmpty) {
      suggestions.add(
        'Copia el error de arriba y busca en los issues de just_audio en GitHub.',
      );
    }
    return suggestions;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Estado del audio (enum claro, sin booleans múltiples) ─────────────────────
enum _AudioState { idle, loading, ready, playing, error }

// ── Widget: onda animada ───────────────────────────────────────────────────────
class _WaveRing extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _WaveRing({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final progress = ((controller.value + delay) % 1.0);
        final size = 42.0 + progress * 24.0;
        final opacity = (1.0 - progress) * 0.45;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.pinkAccent.withOpacity(opacity),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}

// ── Wrapper con fade inferior para indicar scroll ─────────────────────────────
class _ScrollFadeWrapper extends StatelessWidget {
  final Widget child;
  final bool hasImage;
  const _ScrollFadeWrapper({required this.child, required this.hasImage});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.white.withOpacity(0.0)],
          stops: const [0.0, 0.88, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}

// ── Clip para el flap del sobre ────────────────────────────────────────────────
class _EnvelopeFlapClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.35);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.35);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_EnvelopeFlapClipper old) => false;
}

// ── Fondo con corazones ────────────────────────────────────────────────────────
class _HeartPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const symbols = ['♥', '✿', '❀', '♡', '✦'];
    final style = TextStyle(
      fontSize: 20,
      color: Colors.pinkAccent.withOpacity(0.06),
    );
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 6; col++) {
        final x = col * (size.width / 5) + (row.isOdd ? 28.0 : 0.0);
        final y = row * 85.0 - 15;
        final symbol = symbols[(row * 3 + col) % symbols.length];
        final tp = TextPainter(
          text: TextSpan(text: symbol, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_HeartPatternPainter old) => false;
}
