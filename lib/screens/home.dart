// lib/screens/home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'plans/input.dart';
import '../utils/animations.dart';
import '../utils/colors.dart';
import 'calendar/calendar.dart';
import 'memories/memories.dart';
import 'phrases/type_phrases.dart';
import 'wedding/wedding.dart';
import 'games/games_menu.dart';
import '../models/song_of_week.dart';
import '../models/phrase.dart';
import '../services/events.dart';
import '../services/phrases_service.dart';

const String _heroImageUrl =
    'https://planes-crud-stack-images-052869941322.s3.us-east-2.amazonaws.com/assets/beso.jpeg';

const _anniversaryDate = (year: 2023, month: 12, day: 18);
final _weddingUnlockDate = DateTime(2026, 12, 18);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ajustes reutilizables para mantener una entrada visual consistente.
  static const Duration _kFadeDuration = Duration(milliseconds: 420);
  static const Duration _kSlideDuration = Duration(milliseconds: 460);
  static const Duration _kListStagger = Duration(milliseconds: 80);

  late Duration _together;
  late Stream<Duration> _counterStream;

  SongOfWeek? _songOfWeek;
  bool _songLoading = true;

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _together = _calcDuration();
    _counterStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => _calcDuration(),
    );
    _loadSong();
  }

  Duration _calcDuration() {
    final start = DateTime(
      _anniversaryDate.year,
      _anniversaryDate.month,
      _anniversaryDate.day,
    );
    return DateTime.now().difference(start);
  }

  // ── Canción de la semana ──────────────────────────────────────────────────

  Future<void> _loadSong() async {
    setState(() => _songLoading = true);
    try {
      final song = await _eventService.getSongOfWeek();
      if (mounted) {
        setState(() {
          _songOfWeek = song;
          _songLoading = false;
        });
      }
      // Si no hay canción esta semana, elegimos una aleatoria automáticamente
      if (song == null) await _setRandomSong(notify: false);
    } catch (_) {
      if (mounted) setState(() => _songLoading = false);
    }
  }

  Future<void> _setRandomSong({bool notify = true}) async {
    try {
      final phrases = await PhrasesService().getPhrasesByType(
        PhraseType.cancion,
      );
      if (phrases.isEmpty) return;
      phrases.shuffle();
      final picked = phrases.first;

      final newSong = SongOfWeek(
        id: '',
        title: picked.title,
        artista: picked.credits,
        link: picked.link,
        setBy: 'random',
        weekKey: SongOfWeek.currentWeekKey(),
      );

      final saved = _songOfWeek?.id.isNotEmpty == true
          ? await _eventService.updateSongOfWeek(
              newSong.copyWith(id: _songOfWeek!.id),
            )
          : await _eventService.setSongOfWeek(newSong);

      if (mounted) {
        setState(() => _songOfWeek = saved);
        if (notify) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎲 Nueva canción: ${saved.title}'),
              backgroundColor: AppColors.violeta,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _mostrarEditorCancion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SongEditorSheet(
        current: _songOfWeek,
        onRandom: () async {
          Navigator.pop(context);
          await _setRandomSong();
        },
        onSave: (title, artista, link) async {
          Navigator.pop(context);
          await _saveSongManually(title, artista, link);
        },
      ),
    );
  }

  Future<void> _saveSongManually(
    String title,
    String artista,
    String link,
  ) async {
    try {
      final newSong = SongOfWeek(
        id: _songOfWeek?.id ?? '',
        title: title,
        artista: artista,
        link: link,
        setBy: 'manual',
        weekKey: SongOfWeek.currentWeekKey(),
      );

      final saved = newSong.id.isNotEmpty
          ? await _eventService.updateSongOfWeek(newSong)
          : await _eventService.setSongOfWeek(newSong);

      if (mounted) setState(() => _songOfWeek = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  Future<void> _launchSong() async {
    final url = _songOfWeek?.link ?? '';
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.lavanda,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(imageUrl: _heroImageUrl),
                _CounterStrip(stream: _counterStream, initial: _together)
                  .animate()
                  .fadeIn(duration: _kFadeDuration)
                  .slideY(begin: 0.06, duration: _kSlideDuration),

              // ── Canción de la semana ──────────────────────────────────
              _SongOfTheWeekStrip(
                song: _songOfWeek,
                isLoading: _songLoading,
                onTap: _launchSong,
                onEdit: _mostrarEditorCancion,
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: _kFadeDuration)
                  .slideY(begin: 0.08, delay: 100.ms, duration: _kSlideDuration),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.violeta.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('💌', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nuestro Lugar Seguro',
                            style: TextStyle(
                              color: AppColors.violeta,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '¿Qué hacemos hoy?',
                            style: TextStyle(
                              color: AppColors.violeta.withOpacity(0.55),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text('🌸', style: TextStyle(fontSize: 28)),
                  ],
                ),
                )
                  .animate()
                  .fadeIn(delay: 160.ms, duration: _kFadeDuration)
                  .slideX(begin: -0.05, delay: 160.ms, duration: _kSlideDuration),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMenuCard(
                      context,
                      index: 0,
                      emoji: '✨',
                      icon: Icons.favorite_rounded,
                      title: 'Generar Cita',
                      subtitle: '¿Qué hacemos hoy? Que la suerte decida',
                      destination: const InputScreen(),
                      gradientColors: const [
                        Color(0xFFB0B6E8),
                        Color(0xFF796B9B),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      index: 1,
                      emoji: '📅',
                      icon: Icons.calendar_month_rounded,
                      title: 'Fechas Importantes',
                      subtitle: 'Nuestros momentos más especiales',
                      destination: const CalendarScreen(),
                      gradientColors: const [
                        Color(0xFFA9D1DF),
                        Color(0xFF6BAED6),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      index: 2,
                      emoji: '💬',
                      icon: Icons.auto_stories_rounded,
                      title: "De mí pa' ti",
                      subtitle: 'Adivina la frase que te dedico',
                      destination: const TypePhrasesScreen(),
                      gradientColors: const [
                        Color(0xFFD8C9E7),
                        Color(0xFF9C8DC4),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      index: 3,
                      emoji: '🗺️',
                      icon: Icons.explore_rounded,
                      title: 'Nuestras Aventuras',
                      subtitle: 'Checklist de todos los lugares que fuimos',
                      destination: ExperienceMenuScreen(),
                      gradientColors: const [
                        Color(0xFFFFCDD2),
                        Color(0xFFE57373),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildMenuCard(
                      context,
                      index: 4,
                      emoji: '🔒',
                      icon: Icons.favorite_border_rounded,
                      title: 'Juegos para dos',
                      subtitle: 'Dado, ruleta y Kamasutra',
                      destination: const GamesMenuScreen(),
                      gradientColors: const [
                        Color(0xFFF48FB1),
                        Color(0xFFAD1457),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (DateTime.now().isAfter(_weddingUnlockDate))
                      _buildMenuCard(
                        context,
                        index: 5,
                        emoji: '💍',
                        icon: Icons.favorite,
                        title: 'Nuestra Boda',
                        subtitle: 'Todo en un solo lugar',
                        destination: const WeddingScreen(),
                        gradientColors: const [
                          Color(0xFFF8BBD0),
                          Color(0xFFE91E63),
                        ],
                      )
                    else
                      _buildLockedWeddingCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets (sin cambios respecto al original) ────────────────────────────

  Widget _buildLockedWeddingCard() {
    final daysLeft = _weddingUnlockDate.difference(DateTime.now()).inDays;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB0B6E8), Color(0xFF796B9B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF796B9B).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Text(
              '💍',
              style: TextStyle(
                fontSize: 64,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nuestra Boda',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        daysLeft > 0
                            ? 'Se desbloquea en ? días'
                            : 'Próximamente...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '🔒 pronto',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required int index,
    required String emoji,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget destination,
    required List<Color> gradientColors,
  }) {
    return _AnimatedCard(
      index: index,
      fadeDuration: _kFadeDuration,
      slideDuration: _kSlideDuration,
      stagger: _kListStagger,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(createRoute(destination)),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -8,
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 64,
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.80),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.65),
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Canción de la semana — strip ──────────────────────────────────────────────
class _SongOfTheWeekStrip extends StatelessWidget {
  final SongOfWeek? song;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _SongOfTheWeekStrip({
    required this.song,
    required this.isLoading,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF158a3e)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading || song == null ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Ícono de nota musical
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🎵', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),

                // Texto
                Expanded(
                  child: isLoading
                      ? _buildSkeleton()
                      : song == null
                      ? _buildEmpty()
                      : _buildSongInfo(song!),
                ),

                const SizedBox(width: 8),

                // Botón editar
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(SongOfWeek s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'CANCIÓN DE LA SEMANA',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.70),
                letterSpacing: 1.2,
              ),
            ),
            if (s.setBy == 'random') ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🎲 aleatoria',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.80),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          s.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (s.artista.isNotEmpty)
          Text(
            s.artista,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.75),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Text(
      'Sin canción esta semana — toca ✏️ para agregar',
      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
    );
  }
}

// ── Bottom sheet editor ───────────────────────────────────────────────────────
class _SongEditorSheet extends StatefulWidget {
  final SongOfWeek? current;
  final VoidCallback onRandom;
  final void Function(String title, String artista, String link) onSave;

  const _SongEditorSheet({
    required this.current,
    required this.onRandom,
    required this.onSave,
  });

  @override
  State<_SongEditorSheet> createState() => _SongEditorSheetState();
}

class _SongEditorSheetState extends State<_SongEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _artistaCtrl;
  late final TextEditingController _linkCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.current?.title ?? '');
    _artistaCtrl = TextEditingController(text: widget.current?.artista ?? '');
    _linkCtrl = TextEditingController(text: widget.current?.link ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _artistaCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe al menos el título')),
      );
      return;
    }
    widget.onSave(title, _artistaCtrl.text.trim(), _linkCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text('🎵', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Canción de la semana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botón aleatorio
            OutlinedButton.icon(
              onPressed: widget.onRandom,
              icon: const Text('🎲', style: TextStyle(fontSize: 16)),
              label: const Text('Elegir una canción aleatoria'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.violeta,
                side: BorderSide(
                  color: AppColors.violeta.withOpacity(0.4),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divisor
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade200)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o pon una manual',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade200)),
              ],
            ),
            const SizedBox(height: 16),

            // Campo título
            _buildField(
              _titleCtrl,
              'Título de la canción',
              'Ej: Espera y Suspira',
            ),
            const SizedBox(height: 12),

            // Campo artista
            _buildField(_artistaCtrl, 'Artista', 'Ej: Los Panchos'),
            const SizedBox(height: 12),

            // Campo link
            _buildField(
              _linkCtrl,
              'Link de Spotify (opcional)',
              'https://open.spotify.com/track/...',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Botón guardar
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Guardar canción'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.violeta, width: 1.5),
        ),
      ),
    );
  }
}

// ── Resto de widgets sin cambios ──────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration fadeDuration;
  final Duration slideDuration;
  final Duration stagger;

  const _AnimatedCard({
    required this.index,
    required this.child,
    required this.fadeDuration,
    required this.slideDuration,
    required this.stagger,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  @override
  Widget build(BuildContext context) {
    final delay = widget.stagger * widget.index;

    // La animación se deja parametrizable para ajustar ritmo por pantalla.
    return widget.child
        .animate()
        .fadeIn(delay: delay, duration: widget.fadeDuration)
        .slideY(begin: 0.10, delay: delay, duration: widget.slideDuration);
  }
}

class _HeroHeader extends StatelessWidget {
  final String imageUrl;
  const _HeroHeader({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.violeta.withOpacity(0.4)),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.violeta.withOpacity(0.4),
              child: const Icon(
                Icons.favorite,
                size: 48,
                color: Colors.white54,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 18,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, Nati 💌',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hoy es un buen día para hacer algo especial',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterStrip extends StatelessWidget {
  final Stream<Duration> stream;
  final Duration initial;
  const _CounterStrip({required this.stream, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lavanda,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: StreamBuilder<Duration>(
        stream: stream,
        initialData: initial,
        builder: (_, snap) {
          final d = snap.data!;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CounterBox(value: d.inDays, label: 'Días'),
              const SizedBox(width: 6),
              _CounterBox(value: d.inHours % 24, label: 'Hrs'),
              const SizedBox(width: 6),
              _CounterBox(value: d.inMinutes % 60, label: 'Min'),
              const SizedBox(width: 6),
              _CounterBox(value: d.inSeconds % 60, label: 'Seg'),
              const SizedBox(width: 10),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'juntos',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    'desde',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    '18 · 12 · 2023',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.violeta,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CounterBox extends StatelessWidget {
  final int value;
  final String label;
  const _CounterBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grisCalido,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ],
      ),
    );
  }
}
