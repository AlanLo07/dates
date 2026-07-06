import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/phrase.dart';
import '../models/song_of_week.dart';
import '../services/events.dart';
import '../services/phrases_service.dart';
import '../utils/colors.dart';
import '../widgets/motion/ambient_orbs_background.dart';
import 'calendar/calendar.dart';
import 'games/games_menu.dart';
import 'home/widgets/home_counter_strip.dart';
import 'home/widgets/home_hero_header.dart';
import 'home/widgets/home_locked_wedding_card.dart';
import 'home/widgets/home_menu_card.dart';
import 'home/widgets/home_section_header.dart';
import 'home/widgets/home_song_of_the_week_strip.dart';
import 'home/widgets/song_editor_sheet.dart';
import 'memories/memories.dart';
import 'phrases/type_phrases.dart';
import 'plans/input.dart';
import 'wedding/wedding.dart';

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
      if (song == null) {
        await _setRandomSong(notify: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _songLoading = false);
      }
    }
  }

  Future<void> _setRandomSong({bool notify = true}) async {
    try {
      final phrases = await PhrasesService().getPhrasesByType(PhraseType.cancion);
      if (phrases.isEmpty) {
        return;
      }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _mostrarEditorCancion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongEditorSheet(
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

  Future<void> _saveSongManually(String title, String artista, String link) async {
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

      if (mounted) {
        setState(() => _songOfWeek = saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _launchSong() async {
    final url = _songOfWeek?.link ?? '';
    if (url.isEmpty) {
      return;
    }
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

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
      body: AmbientOrbsBackground(
        colors: const [Color(0xFFD8C9E7), Color(0xFFA9D1DF), Color(0xFFF8BBD0)],
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHeroHeader(imageUrl: _heroImageUrl),
              HomeCounterStrip(stream: _counterStream, initial: _together)
                  .animate()
                  .fadeIn(duration: _kFadeDuration)
                  .slideY(begin: 0.06, duration: _kSlideDuration),
              HomeSongOfTheWeekStrip(
                song: _songOfWeek,
                isLoading: _songLoading,
                onTap: _launchSong,
                onEdit: _mostrarEditorCancion,
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: _kFadeDuration)
                  .slideY(begin: 0.08, delay: 100.ms, duration: _kSlideDuration),
              const SizedBox(height: 12),
              const HomeSectionHeader()
                  .animate()
                  .fadeIn(delay: 160.ms, duration: _kFadeDuration)
                  .slideX(begin: -0.05, delay: 160.ms, duration: _kSlideDuration),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HomeMenuCard(
                      index: 0,
                      emoji: '✨',
                      icon: Icons.favorite_rounded,
                      title: 'Generar Cita',
                      subtitle: '¿Qué hacemos hoy? Que la suerte decida',
                      destination: const InputScreen(),
                      gradientColors: const [Color(0xFFB0B6E8), Color(0xFF796B9B)],
                      fadeDuration: _kFadeDuration,
                      slideDuration: _kSlideDuration,
                      stagger: _kListStagger,
                    ),
                    const SizedBox(height: 14),
                    HomeMenuCard(
                      index: 1,
                      emoji: '📅',
                      icon: Icons.calendar_month_rounded,
                      title: 'Fechas Importantes',
                      subtitle: 'Nuestros momentos más especiales',
                      destination: const CalendarScreen(),
                      gradientColors: const [Color(0xFFA9D1DF), Color(0xFF6BAED6)],
                      fadeDuration: _kFadeDuration,
                      slideDuration: _kSlideDuration,
                      stagger: _kListStagger,
                    ),
                    const SizedBox(height: 14),
                    HomeMenuCard(
                      index: 2,
                      emoji: '💬',
                      icon: Icons.auto_stories_rounded,
                      title: "De mí pa' ti",
                      subtitle: 'Adivina la frase que te dedico',
                      destination: const TypePhrasesScreen(),
                      gradientColors: const [Color(0xFFD8C9E7), Color(0xFF9C8DC4)],
                      fadeDuration: _kFadeDuration,
                      slideDuration: _kSlideDuration,
                      stagger: _kListStagger,
                    ),
                    const SizedBox(height: 14),
                    HomeMenuCard(
                      index: 3,
                      emoji: '🗺️',
                      icon: Icons.explore_rounded,
                      title: 'Nuestras Aventuras',
                      subtitle: 'Checklist de todos los lugares que fuimos',
                      destination: ExperienceMenuScreen(),
                      gradientColors: const [Color(0xFFFFCDD2), Color(0xFFE57373)],
                      fadeDuration: _kFadeDuration,
                      slideDuration: _kSlideDuration,
                      stagger: _kListStagger,
                    ),
                    const SizedBox(height: 14),
                    HomeMenuCard(
                      index: 4,
                      emoji: '🔒',
                      icon: Icons.favorite_border_rounded,
                      title: 'Juegos para dos',
                      subtitle: 'Dado, ruleta y Kamasutra',
                      destination: const GamesMenuScreen(),
                      gradientColors: const [Color(0xFFF48FB1), Color(0xFFAD1457)],
                      fadeDuration: _kFadeDuration,
                      slideDuration: _kSlideDuration,
                      stagger: _kListStagger,
                    ),
                    const SizedBox(height: 14),
                    if (DateTime.now().isAfter(_weddingUnlockDate))
                      HomeMenuCard(
                        index: 5,
                        emoji: '💍',
                        icon: Icons.favorite,
                        title: 'Nuestra Boda',
                        subtitle: 'Todo en un solo lugar',
                        destination: const WeddingScreen(),
                        gradientColors: const [Color(0xFFF8BBD0), Color(0xFFE91E63)],
                        fadeDuration: _kFadeDuration,
                        slideDuration: _kSlideDuration,
                        stagger: _kListStagger,
                      )
                    else
                      HomeLockedWeddingCard(
                        daysLeft: _weddingUnlockDate.difference(DateTime.now()).inDays,
                      ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
