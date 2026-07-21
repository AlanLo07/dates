// lib/screens/calendar.dart
//
// CAMBIOS DE RENDIMIENTO:
// • markerBuilder ya no llama _getCartaForDay 3 veces por día:
//   ahora usa los eventos ya resueltos que pasa TableCalendar.
// • _getEventsForDay retorna una lista tipada con un record para
//   evitar downcasts repetidos.
// • Colores centralizados en AppColors.
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/colors.dart';
import '../../models/recuerdos.dart';
import '../../models/carta.dart';
import '../../models/fecha.dart';
import '../../models/cita.dart';
import '../../services/events.dart';
import '../../services/cita_service.dart';
import '../../services/upload_service.dart';
import '../../utils/cita_search.dart';
import 'counter.dart';
import '../letters/letters.dart';

// ── Widget helper reutilizable ────────────────────────────────────────────────
class _EventImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const _EventImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = imageUrl.isEmpty
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, _) => SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, _, _) => _fallback(),
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _fallback() => SizedBox(
    width: width,
    height: height,
    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
  );
}

// ── Modelo interno para los marcadores del día ────────────────────────────────
// Evita downcasts repetidos en markerBuilder y onDaySelected.
class _DayData {
  final List<Recuerdo> recuerdos;
  final CartaSorpresa? carta;
  final EventoImportante? evento;

  const _DayData({this.recuerdos = const [], this.carta, this.evento});

  bool get isEmpty => recuerdos.isEmpty && carta == null && evento == null;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Duraciones centralizadas para ajustar el ritmo visual del calendario.
  static const Duration _kEnterDuration = Duration(milliseconds: 420);
  static const Duration _kSlideDuration = Duration(milliseconds: 460);

  DateTime _focusedDay = DateTime.now();
  bool _mostrarCartas = true;
  bool _mostrarCitas = true;
  bool _mostrarRecuerdos = true;

  List<Recuerdo> _recuerdos = [];
  List<CartaSorpresa> _cartas = [];
  List<EventoImportante> _eventos = [];
  bool _isLoading = true;
  String? _error;

  final EventService _service = EventService();
  late final ConfettiController _calendarConfettiController;
  int _counterPulseTick = 0;

  @override
  void initState() {
    super.initState();
    _calendarConfettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _loadData();
  }

  @override
  void dispose() {
    _calendarConfettiController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getCalendarData();
      setState(() {
        _recuerdos = data.recuerdos;
        _cartas = data.cartas;
        _eventos = data.eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers de fecha ───────────────────────────────────────────────────────

  String _toApiDateKey(DateTime day) {
    final d = day.day.toString().padLeft(2, '0');
    final m = day.month.toString().padLeft(2, '0');
    final y = day.year.toString();
    return '$d-$m-$y';
  }

  String _toMonthDayKey(DateTime day) {
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$m-$d';
  }

  String _monthDayFromApiDate(String apiDate) {
    final p = apiDate.split('-');
    if (p.length != 3) return '';
    return '${p[1]}-${p[0]}';
  }

  // ── Obtener datos de un día ────────────────────────────────────────────────
  // Este método es la fuente única de verdad para un día dado.
  // Tanto eventLoader como markerBuilder y onDaySelected lo usan.

  _DayData _getDayData(DateTime day) {
    final recuerdos = _mostrarRecuerdos
        ? _recuerdos
              .where((r) => _monthDayFromApiDate(r.date) == _toMonthDayKey(day))
              .toList()
        : <Recuerdo>[];

    CartaSorpresa? carta;
    if (_mostrarCartas) {
      final key = _toApiDateKey(day);
      try {
        carta = _cartas.firstWhere((c) => c.date == key);
      } catch (_) {}
    }

    EventoImportante? evento;
    if (_mostrarCitas) {
      final key = _toApiDateKey(day);
      try {
        evento = _eventos.firstWhere((e) => e.date == key);
      } catch (_) {}
    }

    return _DayData(recuerdos: recuerdos, carta: carta, evento: evento);
  }

  // eventLoader para TableCalendar — devuelve lista de objetos para los dots
  List<Object> _getEventsForDay(DateTime day) {
    final d = _getDayData(day);
    return [
      ...d.recuerdos,
      if (d.carta != null) d.carta!,
      if (d.evento != null) d.evento!,
    ];
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterChip(
            label: '💌 Cartas',
            value: _mostrarCartas,
            onChanged: (v) => setState(() => _mostrarCartas = v),
            activeColor: Colors.pinkAccent,
          ),
          _buildFilterChip(
            label: '📍 Citas',
            value: _mostrarCitas,
            onChanged: (v) => setState(() => _mostrarCitas = v),
            activeColor: AppColors.celeste,
          ),
          _buildFilterChip(
            label: '🎞 Recuerdos',
            value: _mostrarRecuerdos,
            onChanged: (v) => setState(() => _mostrarRecuerdos = v),
            activeColor: AppColors.violeta,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? activeColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: value ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Imagen helpers ─────────────────────────────────────────────────────────

  Widget _buildThumbnail(String imagePath) {
    const double size = 50;
    if (imagePath.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.lavanda,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.photo, size: 20, color: AppColors.violeta),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: _EventImage(
        imageUrl: imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.lavanda,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 48,
          color: AppColors.violeta,
        ),
      );
    }
    return _EventImage(
      imageUrl: imagePath,
      width: 300,
      height: 300,
      borderRadius: BorderRadius.circular(15),
    );
  }

  // ── IconData desde string ──────────────────────────────────────────────────

  static const Map<String, IconData> _iconMap = {
    'backpack_outlined': Icons.backpack_outlined,
    'queue_music': Icons.queue_music,
    'cake': Icons.cake,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'flight': Icons.flight,
    'celebration': Icons.celebration,
    'restaurant': Icons.restaurant,
    'music_note': Icons.music_note,
    'beach_access': Icons.beach_access,
    'local_activity': Icons.local_activity,
    'emoji_events': Icons.emoji_events,
    'hiking': Icons.hiking,
    'theater_comedy': Icons.theater_comedy,
    'directions_car': Icons.directions_car,
  };

  IconData _iconFromString(String name) => _iconMap[name] ?? Icons.event_note;

  // ── Diálogos ───────────────────────────────────────────────────────────────

  void _showRecuerdoDialog(Recuerdo recuerdo) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        opaque: false,
        pageBuilder: (ctx, animation, _) => Center(
          child: ScaleTransition(
            scale: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: AppColors.surface,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'recuerdo-${recuerdo.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildImageWidget(recuerdo.imagePath),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      recuerdo.title,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: AppColors.violeta,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recuerdo.description,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: AppColors.celeste),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventoDialog(EventoImportante evento) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        opaque: false,
        pageBuilder: (ctx, animation, _) => Center(
          child: ScaleTransition(
            scale: animation,
            child: _EventoDialog(
              evento: evento,
              iconFromString: _iconFromString,
              onDelete: (id) async {
                await _service.deleteEvento(id);
                setState(() => _eventos.removeWhere((e) => e.id == id));
              },
              onEdit: (actualizado) async {
                final guardado = await _service.updateEvento(actualizado);
                if (!mounted) return;
                setState(() {
                  final index = _eventos.indexWhere((e) => e.id == guardado.id);
                  if (index >= 0) {
                    _eventos[index] = guardado;
                  }
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Lógica de carta ────────────────────────────────────────────────────────

  Future<void> _verificarCarta(DateTime day, CartaSorpresa carta) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDay = DateTime(day.year, day.month, day.day);

    if (localDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 ¡Aún no es tiempo! Espera a la fecha.'),
        ),
      );
      return;
    }

    if (carta.abierta) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LetterScreen(carta: carta)));
      return;
    }

    try {
      final cartaAbierta = await _service.abrirCarta(carta.id);
      setState(() {
        final idx = _cartas.indexWhere((c) => c.id == carta.id);
        if (idx >= 0) _cartas[idx] = cartaAbierta;
      });
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LetterScreen(carta: cartaAbierta)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LetterScreen(carta: carta)));
    }
  }

  // ── Agendar desde día vacío ────────────────────────────────────────────────

  void _mostrarAgendarDesdeCalendario(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgendarDesdeCalendarioSheet(
        fechaPreseleccionada: day,
        onAgendado: (e) {
          setState(() {
            _eventos.add(e);
            _counterPulseTick++;
          });
          HapticFeedback.mediumImpact();
          _calendarConfettiController.play();
        },
        onAgendadoCarta: (c) => setState(() => _cartas.add(c)),
        service: _service,
        formatearFecha: _toApiDateKey,
      ),
    );
  }

  void _mostrarFormularioNuevoRecuerdo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CrearRecuerdoSheet(
        fechaInicial: DateTime.now(),
        service: _service,
        formatearFecha: _toApiDateKey,
        onCreado: (recuerdo) {
          setState(() {
            _recuerdos = [..._recuerdos, recuerdo];
            _focusedDay = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Recuerdo "${recuerdo.title}" creado'),
              backgroundColor: AppColors.violeta,
            ),
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  DateTime _date(int year, int month, int day) =>
      DateTime.utc(year, month, day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Fechas Importantes',
          style: TextStyle(color: AppColors.violeta),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.violeta),
                )
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error al cargar datos',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildFilterBar()
                        .animate()
                        .fadeIn(duration: _kEnterDuration)
                        .slideY(begin: -0.04, duration: _kSlideDuration),
                    const SizedBox(height: 8),
                    if (_eventos.isNotEmpty)
                      TweenAnimationBuilder<double>(
                        key: ValueKey('counter_pulse_$_counterPulseTick'),
                        duration: const Duration(milliseconds: 420),
                        tween: Tween<double>(begin: 0.92, end: 1),
                        curve: Curves.elasticOut,
                        builder: (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: ProximaCitaCounter(eventos: _eventos)
                            .animate()
                            .fadeIn(delay: 90.ms, duration: _kEnterDuration)
                            .slideY(
                              begin: 0.05,
                              delay: 90.ms,
                              duration: _kSlideDuration,
                            ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          TableCalendar(
                                firstDay: _date(DateTime.now().year - 1, 1, 1),
                                lastDay: _date(DateTime.now().year + 1, 12, 31),
                                focusedDay: _focusedDay,
                                calendarFormat: CalendarFormat.month,
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: TextStyle(
                                    color: AppColors.violeta,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    color: AppColors.violeta,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    color: AppColors.violeta,
                                  ),
                                ),
                                daysOfWeekStyle: const DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(
                                    color: AppColors.violeta,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  weekendStyle: TextStyle(
                                    color: AppColors.violeta,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                eventLoader: _getEventsForDay,
                                calendarBuilders: CalendarBuilders(
                                  defaultBuilder: (ctx, day, _) => Container(
                                    margin: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      day.day.toString(),
                                      style: const TextStyle(
                                        color: AppColors.violeta,
                                      ),
                                    ),
                                  ),
                                  selectedBuilder: (ctx, day, focusedDay) =>
                                      TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0.95,
                                          end: 1.0,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 280,
                                        ),
                                        curve: Curves.elasticOut,
                                        builder: (_, scale, __) =>
                                            Transform.scale(
                                              scale: scale,
                                              child: Container(
                                                margin: const EdgeInsets.all(4),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      AppColors.violeta
                                                          .withOpacity(0.3),
                                                      AppColors.violeta
                                                          .withOpacity(0.15),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color: AppColors.violeta,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.violeta
                                                          .withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  day.day.toString(),
                                                  style: const TextStyle(
                                                    color: AppColors.violeta,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ),
                                  todayBuilder: (ctx, day, _) => Container(
                                    margin: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.violeta.withOpacity(
                                          0.5,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      day.day.toString(),
                                      style: const TextStyle(
                                        color: AppColors.violeta,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // ── markerBuilder ahora usa _DayData directamente ──────
                                  // No hay triple lookup por día.
                                  markerBuilder: (ctx, day, events) {
                                    if (events.isEmpty) return null;

                                    // Determinamos el tipo del primer evento
                                    final first = events.first;

                                    if (first is Recuerdo &&
                                        _mostrarRecuerdos) {
                                      if (first.imagePath.isNotEmpty) {
                                        return Positioned(
                                          bottom: 1,
                                          child: Hero(
                                            tag: 'recuerdo-${first.id}',
                                            child: _buildThumbnail(
                                              first.imagePath,
                                            ),
                                          ),
                                        );
                                      }
                                      return Positioned(
                                        bottom: 1,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.pinkAccent.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.favorite,
                                            size: 16,
                                            color: Colors.pinkAccent,
                                          ),
                                        ),
                                      );
                                    }

                                    if (first is CartaSorpresa &&
                                        _mostrarCartas) {
                                      final now = DateTime.now();
                                      final today = DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                      );
                                      final localDay = DateTime(
                                        day.year,
                                        day.month,
                                        day.day,
                                      );
                                      final bloqueada =
                                          localDay.isAfter(today) ||
                                          !first.abierta;
                                      return Positioned(
                                        bottom: 1,
                                        child: Icon(
                                          bloqueada
                                              ? Icons.lock
                                              : Icons.lock_open,
                                          color: bloqueada
                                              ? AppColors.locked
                                              : AppColors.unlocked,
                                          size: 16,
                                        ),
                                      );
                                    }

                                    if (first is EventoImportante &&
                                        _mostrarCitas) {
                                      return Positioned(
                                        bottom: 1,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: AppColors.violeta.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Icon(
                                            _iconFromString(first.icon),
                                            size: 16,
                                            color: AppColors.violeta,
                                          ),
                                        ),
                                      );
                                    }

                                    return null;
                                  },
                                ),
                                onDaySelected: (selectedDay, focusedDay) async {
                                  setState(() => _focusedDay = focusedDay);

                                  // Una sola llamada — sin triple lookup
                                  final data = _getDayData(selectedDay);

                                  if (data.carta != null && _mostrarCartas) {
                                    await _verificarCarta(
                                      selectedDay,
                                      data.carta!,
                                    );
                                    return;
                                  }
                                  if (data.recuerdos.isNotEmpty &&
                                      _mostrarRecuerdos) {
                                    _showRecuerdoDialog(data.recuerdos.first);
                                    return;
                                  }
                                  if (data.evento != null && _mostrarCitas) {
                                    _showEventoDialog(data.evento!);
                                    return;
                                  }

                                  _mostrarAgendarDesdeCalendario(selectedDay);
                                },
                                selectedDayPredicate: (day) =>
                                    isSameDay(day, _focusedDay),
                              )
                              .animate()
                              .fadeIn(delay: 140.ms, duration: _kEnterDuration)
                              .slideY(
                                begin: 0.08,
                                delay: 140.ms,
                                duration: _kSlideDuration,
                              ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _mostrarFormularioNuevoRecuerdo,
                          icon: const Icon(Icons.movie_creation_outlined),
                          label: const Text('Crear recuerdo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.violeta,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _calendarConfettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 22,
                gravity: 0.28,
                colors: const [
                  Color(0xFFA9D1DF),
                  Color(0xFFB0B6E8),
                  Color(0xFF81C784),
                  Color(0xFFE57373),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog de EventoImportante
// ─────────────────────────────────────────────────────────────────────────────
class _EventoDialog extends StatefulWidget {
  final EventoImportante evento;
  final IconData Function(String) iconFromString;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(EventoImportante evento) onEdit;

  const _EventoDialog({
    required this.evento,
    required this.iconFromString,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_EventoDialog> createState() => _EventoDialogState();
}

class _EventoDialogState extends State<_EventoDialog> {
  bool _isDeleting = false;

  bool get _tieneDetalles {
    final presupuesto = widget.evento.presupuesto;
    return widget.evento.documentos.isNotEmpty ||
        widget.evento.itinerario.actividades.isNotEmpty ||
        presupuesto.conceptos.isNotEmpty ||
        presupuesto.gastado > 0 ||
        presupuesto.limite > 0;
  }

  void _mostrarDetalles() {
    showDialog<void>(
      context: context,
      builder: (_) => _EventoDetallesDialog(evento: widget.evento),
    );
  }

  Future<void> _editarDetalle() async {
    final result = await showModalBottomSheet<EventoImportante>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarEventoSheet(
        evento: widget.evento,
        onGuardar: (actualizado) async {
          await widget.onEdit(actualizado);
        },
      ),
    );

    if (result == null || !mounted) return;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmarEliminar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar cita?',
          style: TextStyle(color: AppColors.violeta),
        ),
        content: Text(
          'Se eliminará "${widget.evento.title}" del calendario.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.celeste),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isDeleting = true);
    try {
      await widget.onDelete(widget.evento.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.lavanda,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.iconFromString(widget.evento.icon),
              size: 64,
              color: AppColors.violeta,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.evento.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.violeta,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.evento.description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.evento.date,
            style: const TextStyle(
              color: AppColors.celeste,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: _editarDetalle,
          icon: const Icon(
            Icons.edit_outlined,
            color: AppColors.violeta,
            size: 18,
          ),
          label: const Text(
            'Editar',
            style: TextStyle(color: AppColors.violeta),
          ),
        ),
        TextButton.icon(
          onPressed: _mostrarDetalles,
          icon: Icon(
            _tieneDetalles ? Icons.visibility_outlined : Icons.info_outline,
            color: AppColors.celeste,
            size: 18,
          ),
          label: Text(
            _tieneDetalles ? 'Ver detalles' : 'Sin detalles',
            style: const TextStyle(color: AppColors.celeste),
          ),
        ),
        _isDeleting
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.redAccent,
                  ),
                ),
              )
            : TextButton.icon(
                onPressed: _confirmarEliminar,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: AppColors.celeste),
          ),
        ),
      ],
    );
  }
}

class _EditarEventoSheet extends StatefulWidget {
  final EventoImportante evento;
  final Future<void> Function(EventoImportante evento) onGuardar;

  const _EditarEventoSheet({required this.evento, required this.onGuardar});

  @override
  State<_EditarEventoSheet> createState() => _EditarEventoSheetState();
}

class _EditarEventoSheetState extends State<_EditarEventoSheet> {
  late DateTime _fechaSeleccionada;

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _presupuestoGastadoCtrl = TextEditingController();
  final _presupuestoLimiteCtrl = TextEditingController();
  final List<TextEditingController> _itinerarioFechaCtrls = [];
  final List<TextEditingController> _itinerarioTiempoCtrls = [];
  final List<TextEditingController> _itinerarioActividadCtrls = [];
  final List<TextEditingController> _conceptoNombreCtrls = [];
  final List<TextEditingController> _conceptoMontoCtrls = [];
  final List<TextEditingController> _documentoCtrls = [];

  bool _isSaving = false;
  bool _mostrarDetallesOpcionales = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = _parseFecha(widget.evento.date);
    _tituloController.text = widget.evento.title;
    _descripcionController.text = widget.evento.description;
    _presupuestoGastadoCtrl.text = widget.evento.presupuesto.gastado.toString();
    _presupuestoLimiteCtrl.text = widget.evento.presupuesto.limite.toString();

    for (final actividad in widget.evento.itinerario.actividades) {
      _itinerarioFechaCtrls.add(TextEditingController(text: actividad.fecha));
      _itinerarioTiempoCtrls.add(TextEditingController(text: actividad.tiempo));
      _itinerarioActividadCtrls.add(
        TextEditingController(text: actividad.actividad),
      );
    }

    for (final concepto in widget.evento.presupuesto.conceptos) {
      _conceptoNombreCtrls.add(TextEditingController(text: concepto.concepto));
      _conceptoMontoCtrls.add(
        TextEditingController(text: concepto.monto.toString()),
      );
    }

    for (final documento in widget.evento.documentos) {
      _documentoCtrls.add(TextEditingController(text: documento));
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _presupuestoGastadoCtrl.dispose();
    _presupuestoLimiteCtrl.dispose();
    for (final c in _itinerarioFechaCtrls) c.dispose();
    for (final c in _itinerarioTiempoCtrls) c.dispose();
    for (final c in _itinerarioActividadCtrls) c.dispose();
    for (final c in _conceptoNombreCtrls) c.dispose();
    for (final c in _conceptoMontoCtrls) c.dispose();
    for (final c in _documentoCtrls) c.dispose();
    super.dispose();
  }

  DateTime _parseFecha(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    final day = int.tryParse(parts[0]) ?? DateTime.now().day;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final year = int.tryParse(parts[2]) ?? DateTime.now().year;
    return DateTime(year, month, day);
  }

  String _formatFecha(DateTime day) {
    final d = day.day.toString().padLeft(2, '0');
    final m = day.month.toString().padLeft(2, '0');
    final y = day.year.toString();
    return '$d-$m-$y';
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.violeta,
            onPrimary: Colors.white,
            onSurface: AppColors.violeta,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  void _agregarItinerario() {
    setState(() {
      _itinerarioFechaCtrls.add(TextEditingController());
      _itinerarioTiempoCtrls.add(TextEditingController());
      _itinerarioActividadCtrls.add(TextEditingController());
    });
  }

  void _eliminarItinerario(int index) {
    setState(() {
      _itinerarioFechaCtrls.removeAt(index).dispose();
      _itinerarioTiempoCtrls.removeAt(index).dispose();
      _itinerarioActividadCtrls.removeAt(index).dispose();
    });
  }

  void _agregarConcepto() {
    setState(() {
      _conceptoNombreCtrls.add(TextEditingController());
      _conceptoMontoCtrls.add(TextEditingController());
    });
  }

  void _eliminarConcepto(int index) {
    setState(() {
      _conceptoNombreCtrls.removeAt(index).dispose();
      _conceptoMontoCtrls.removeAt(index).dispose();
    });
  }

  void _agregarDocumento() {
    setState(() => _documentoCtrls.add(TextEditingController()));
  }

  void _eliminarDocumento(int index) {
    setState(() => _documentoCtrls.removeAt(index).dispose());
  }

  double _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  ItinerarioEvento _buildItinerarioFromForm() {
    final actividades = <ActividadItinerario>[];
    for (var i = 0; i < _itinerarioActividadCtrls.length; i++) {
      final actividad = _itinerarioActividadCtrls[i].text.trim();
      final fecha = _itinerarioFechaCtrls[i].text.trim();
      final tiempo = _itinerarioTiempoCtrls[i].text.trim();
      if (actividad.isEmpty && fecha.isEmpty && tiempo.isEmpty) continue;
      actividades.add(
        ActividadItinerario(fecha: fecha, tiempo: tiempo, actividad: actividad),
      );
    }
    return ItinerarioEvento(actividades: actividades);
  }

  PresupuestoEvento _buildPresupuestoFromForm() {
    final conceptos = <ConceptoGasto>[];
    for (var i = 0; i < _conceptoNombreCtrls.length; i++) {
      final concepto = _conceptoNombreCtrls[i].text.trim();
      final monto = _parseDouble(_conceptoMontoCtrls[i].text);
      if (concepto.isEmpty && monto == 0) continue;
      conceptos.add(ConceptoGasto(concepto: concepto, monto: monto));
    }
    return PresupuestoEvento(
      gastado: _parseDouble(_presupuestoGastadoCtrl.text),
      limite: _parseDouble(_presupuestoLimiteCtrl.text),
      conceptos: conceptos,
    );
  }

  List<String> _buildDocumentosFromForm() {
    return _documentoCtrls
        .map((c) => c.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  Future<void> _guardar() async {
    if (_tituloController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un título')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final actualizado = widget.evento.copyWith(
        title: _tituloController.text.trim(),
        description: _descripcionController.text.trim(),
        date: _formatFecha(_fechaSeleccionada),
        itinerario: _buildItinerarioFromForm(),
        presupuesto: _buildPresupuestoFromForm(),
        documentos: _buildDocumentosFromForm(),
      );
      await widget.onGuardar(actualizado);
      if (!mounted) return;
      Navigator.of(context).pop(actualizado);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      maxLines: maxLines,
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

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.violeta, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFEDE9F5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.violeta,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _formatFecha(_fechaSeleccionada),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.violeta,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.violeta,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.violeta,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required VoidCallback onAdd,
    required String label,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }

  Widget _buildDetallesOpcionalesCita() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.violeta, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detalles opcionales',
                  style: TextStyle(
                    color: AppColors.violeta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(
                  () =>
                      _mostrarDetallesOpcionales = !_mostrarDetallesOpcionales,
                ),
                child: Text(_mostrarDetallesOpcionales ? 'Ocultar' : 'Agregar'),
              ),
            ],
          ),
          if (_mostrarDetallesOpcionales) ...[
            const SizedBox(height: 6),
            _buildSectionLabel('Itinerario'),
            if (_itinerarioActividadCtrls.isEmpty)
              _buildEmptyState(
                onAdd: _agregarItinerario,
                label: 'Agregar actividad',
              )
            else ...[
              for (var i = 0; i < _itinerarioActividadCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _itinerarioFechaCtrls[i],
                                'Fecha',
                                'dd-MM-yyyy',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTextField(
                                _itinerarioTiempoCtrls[i],
                                'Tiempo',
                                '18:30',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _itinerarioActividadCtrls[i],
                          'Actividad',
                          'Ej: Cena en terraza',
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Eliminar actividad',
                            onPressed: () => _eliminarItinerario(i),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarItinerario,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar actividad'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildSectionLabel('Presupuesto'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _presupuestoGastadoCtrl,
                    'Gastado',
                    '0.00',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    _presupuestoLimiteCtrl,
                    'Límite',
                    '0.00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_conceptoNombreCtrls.isEmpty)
              _buildEmptyState(
                onAdd: _agregarConcepto,
                label: 'Agregar concepto de gasto',
              )
            else ...[
              for (var i = 0; i < _conceptoNombreCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _conceptoNombreCtrls[i],
                          'Concepto',
                          'Ej: Transporte',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          _conceptoMontoCtrls[i],
                          'Monto',
                          '0.00',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar concepto',
                        onPressed: () => _eliminarConcepto(i),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarConcepto,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar concepto'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildSectionLabel('Documentos (links)'),
            if (_documentoCtrls.isEmpty)
              _buildEmptyState(onAdd: _agregarDocumento, label: 'Agregar link')
            else ...[
              for (var i = 0; i < _documentoCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _documentoCtrls[i],
                          'Link',
                          'https://...',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar link',
                        onPressed: () => _eliminarDocumento(i),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarDocumento,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar link'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const Row(
              children: [
                Icon(
                  Icons.backpack_outlined,
                  color: AppColors.violeta,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'Editar cita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(_tituloController, 'Título', 'Ej: Cena romántica'),
            const SizedBox(height: 12),
            _buildTextField(
              _descripcionController,
              'Descripción (opcional)',
              'Ej: Reservación en el restaurante favorito',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildDetallesOpcionalesCita(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _guardar,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
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
}

class _EventoDetallesDialog extends StatelessWidget {
  final EventoImportante evento;

  const _EventoDetallesDialog({required this.evento});

  @override
  Widget build(BuildContext context) {
    final presupuesto = evento.presupuesto;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      title: const Text(
        'Detalles de la cita',
        style: TextStyle(color: AppColors.violeta),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                evento.title,
                style: const TextStyle(
                  color: AppColors.violeta,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _detailsSectionTitle('Itinerario'),
              if (evento.itinerario.actividades.isEmpty)
                _emptyLabel('Sin actividades registradas')
              else
                ...evento.itinerario.actividades.map(
                  (actividad) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actividad.actividad,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.violeta,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${actividad.fecha} • ${actividad.tiempo}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _detailsSectionTitle('Presupuesto'),
              _budgetLine('Gastado', presupuesto.gastado),
              _budgetLine('Límite', presupuesto.limite),
              const SizedBox(height: 6),
              if (presupuesto.conceptos.isEmpty)
                _emptyLabel('Sin conceptos de gasto')
              else
                ...presupuesto.conceptos.map(
                  (gasto) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            gasto.concepto,
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                        Text(
                          gasto.monto.toStringAsFixed(2),
                          style: const TextStyle(
                            color: AppColors.violeta,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _detailsSectionTitle('Documentos'),
              if (evento.documentos.isEmpty)
                _emptyLabel('Sin documentos')
              else
                ...evento.documentos.map(
                  (doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.link,
                            size: 16,
                            color: AppColors.celeste,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cerrar',
            style: TextStyle(color: AppColors.celeste),
          ),
        ),
      ],
    );
  }

  Widget _detailsSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.violeta,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  Widget _budgetLine(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.violeta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet: agendar cita desde calendario
// ─────────────────────────────────────────────────────────────────────────────
class _AgendarDesdeCalendarioSheet extends StatefulWidget {
  final DateTime fechaPreseleccionada;
  final void Function(EventoImportante) onAgendado;
  final void Function(CartaSorpresa) onAgendadoCarta;
  final EventService service;
  final String Function(DateTime) formatearFecha;

  const _AgendarDesdeCalendarioSheet({
    required this.fechaPreseleccionada,
    required this.onAgendado,
    required this.onAgendadoCarta,
    required this.service,
    required this.formatearFecha,
  });

  @override
  State<_AgendarDesdeCalendarioSheet> createState() =>
      _AgendarDesdeCalendarioSheetState();
}

class _AgendarDesdeCalendarioSheetState
    extends State<_AgendarDesdeCalendarioSheet> {
  late DateTime _fechaSeleccionada;

  List<Cita> _citas = [];
  bool _loadingCitas = true;
  String? _errorCitas;
  String typeDate = 'Carta';

  static final Cita _kNuevaCita = Cita(
    nombre: '__nueva__',
    descripcion: '',
    categoria: '',
    presupuesto: '',
    tiempo: 0,
    link: '',
  );
  Cita? _citaSeleccionada;

  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final UploadService _uploadService = UploadService();
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isUploadingAudio = false;
  String? _imageUrl;
  String? _audioUrl;
  String? _imageError;
  String? _audioError;

  bool _mostrarDetallesOpcionales = false;
  final _presupuestoGastadoCtrl = TextEditingController();
  final _presupuestoLimiteCtrl = TextEditingController();
  final List<TextEditingController> _itinerarioFechaCtrls = [];
  final List<TextEditingController> _itinerarioTiempoCtrls = [];
  final List<TextEditingController> _itinerarioActividadCtrls = [];
  final List<TextEditingController> _conceptoNombreCtrls = [];
  final List<TextEditingController> _conceptoMontoCtrls = [];
  final List<TextEditingController> _documentoCtrls = [];

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.fechaPreseleccionada;
    _fetchCitas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _presupuestoGastadoCtrl.dispose();
    _presupuestoLimiteCtrl.dispose();

    for (final c in _itinerarioFechaCtrls) {
      c.dispose();
    }
    for (final c in _itinerarioTiempoCtrls) {
      c.dispose();
    }
    for (final c in _itinerarioActividadCtrls) {
      c.dispose();
    }
    for (final c in _conceptoNombreCtrls) {
      c.dispose();
    }
    for (final c in _conceptoMontoCtrls) {
      c.dispose();
    }
    for (final c in _documentoCtrls) {
      c.dispose();
    }

    super.dispose();
  }

  void _agregarItinerario() {
    setState(() {
      _itinerarioFechaCtrls.add(TextEditingController());
      _itinerarioTiempoCtrls.add(TextEditingController());
      _itinerarioActividadCtrls.add(TextEditingController());
    });
  }

  void _eliminarItinerario(int index) {
    setState(() {
      _itinerarioFechaCtrls.removeAt(index).dispose();
      _itinerarioTiempoCtrls.removeAt(index).dispose();
      _itinerarioActividadCtrls.removeAt(index).dispose();
    });
  }

  void _agregarConcepto() {
    setState(() {
      _conceptoNombreCtrls.add(TextEditingController());
      _conceptoMontoCtrls.add(TextEditingController());
    });
  }

  void _eliminarConcepto(int index) {
    setState(() {
      _conceptoNombreCtrls.removeAt(index).dispose();
      _conceptoMontoCtrls.removeAt(index).dispose();
    });
  }

  void _agregarDocumento() {
    setState(() {
      _documentoCtrls.add(TextEditingController());
    });
  }

  void _eliminarDocumento(int index) {
    setState(() {
      _documentoCtrls.removeAt(index).dispose();
    });
  }

  double _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  ItinerarioEvento _buildItinerarioFromForm() {
    final actividades = <ActividadItinerario>[];
    for (var i = 0; i < _itinerarioActividadCtrls.length; i++) {
      final actividad = _itinerarioActividadCtrls[i].text.trim();
      final fecha = _itinerarioFechaCtrls[i].text.trim();
      final tiempo = _itinerarioTiempoCtrls[i].text.trim();
      if (actividad.isEmpty && fecha.isEmpty && tiempo.isEmpty) continue;

      actividades.add(
        ActividadItinerario(fecha: fecha, tiempo: tiempo, actividad: actividad),
      );
    }
    return ItinerarioEvento(actividades: actividades);
  }

  PresupuestoEvento _buildPresupuestoFromForm() {
    final conceptos = <ConceptoGasto>[];
    for (var i = 0; i < _conceptoNombreCtrls.length; i++) {
      final concepto = _conceptoNombreCtrls[i].text.trim();
      final monto = _parseDouble(_conceptoMontoCtrls[i].text);
      if (concepto.isEmpty && monto == 0) continue;
      conceptos.add(ConceptoGasto(concepto: concepto, monto: monto));
    }

    return PresupuestoEvento(
      gastado: _parseDouble(_presupuestoGastadoCtrl.text),
      limite: _parseDouble(_presupuestoLimiteCtrl.text),
      conceptos: conceptos,
    );
  }

  List<String> _buildDocumentosFromForm() {
    return _documentoCtrls
        .map((c) => c.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  // Reutiliza el cache de ApiService — sin llamada extra a la red
  Future<void> _fetchCitas() async {
    setState(() {
      _loadingCitas = true;
      _errorCitas = null;
    });
    try {
      final citas = await ApiService().getCitas();
      setState(() {
        _citas = citas;
        _loadingCitas = false;
      });
    } catch (e) {
      setState(() {
        _errorCitas = e.toString();
        _loadingCitas = false;
      });
    }
  }

  bool get _esNuevaCita => _citaSeleccionada == _kNuevaCita;

  String get _tituloFinal => _esNuevaCita && typeDate == 'Cita'
      ? _tituloController.text.trim()
      : (_citaSeleccionada?.nombre ?? '');
  String get _descripcionFinal => _esNuevaCita && typeDate == 'Cita'
      ? _descripcionController.text.trim()
      : (_citaSeleccionada?.descripcion ?? '');
  String get _tituloCartaFinal =>
      typeDate == 'Carta' ? _tituloController.text.trim() : '';
  String get _descripcionCartaFinal =>
      typeDate == 'Carta' ? _descripcionController.text.trim() : '';

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.violeta,
            onPrimary: Colors.white,
            onSurface: AppColors.violeta,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  void _abrirSelectorCitas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CitaSelectorSheet(
        citas: _citas,
        citaSeleccionada: _esNuevaCita ? null : _citaSeleccionada,
        onSeleccionada: (c) => setState(() => _citaSeleccionada = c),
        onNuevaCita: () => setState(() => _citaSeleccionada = _kNuevaCita),
      ),
    );
  }

  Future<void> _agendar() async {
    if (_citaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una cita o elige "Nueva cita"'),
        ),
      );
      return;
    }
    if (_esNuevaCita && _tituloFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un título')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final itinerario = _buildItinerarioFromForm();
      final presupuesto = _buildPresupuestoFromForm();
      final documentos = _buildDocumentosFromForm();

      final nuevoEvento = await widget.service.createEvento(
        EventoImportante(
          id: '',
          title: _tituloFinal,
          description: _descripcionFinal,
          date: widget.formatearFecha(_fechaSeleccionada),
          icon: 'backpack_outlined',
          itinerario: itinerario,
          presupuesto: presupuesto,
          documentos: documentos,
        ),
      );
      if (mounted) {
        widget.onAgendado(nuevoEvento);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Cita agendada para el ${widget.formatearFecha(_fechaSeleccionada)}!',
            ),
            backgroundColor: AppColors.violeta,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agendar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarImagenCarta() async {
    setState(() {
      _isUploadingImage = true;
      _imageError = null;
      _imageUrl = null;
    });

    try {
      final publicUrl = await _uploadService.pickAndUpload();
      if (!mounted) return;
      setState(() {
        _imageUrl = publicUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _imageError = e.toString();
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _seleccionarAudioCarta() async {
    setState(() {
      _isUploadingAudio = true;
      _audioError = null;
      _audioUrl = null;
    });

    try {
      final publicUrl = await _uploadService.pickAndUploadAudio();
      if (!mounted) return;
      setState(() {
        _audioUrl = publicUrl;
        _isUploadingAudio = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _audioError = e.toString();
        _isUploadingAudio = false;
      });
    }
  }

  void _quitarImagenCarta() {
    setState(() {
      _imageUrl = null;
      _imageError = null;
    });
  }

  void _quitarAudioCarta() {
    setState(() {
      _audioUrl = null;
      _audioError = null;
    });
  }

  Future<void> _crearCarta() async {
    if (_tituloCartaFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un título')),
      );
      return;
    }
    if (_isUploadingImage || _isUploadingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Espera a que termine de subir el archivo'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nuevaCarta = await widget.service.createCarta(
        CartaSorpresa(
          id: '',
          title: _tituloCartaFinal,
          description: _descripcionCartaFinal,
          date: widget.formatearFecha(_fechaSeleccionada),
          imageUrl: _imageUrl ?? '',
          audioUrl: _audioUrl ?? '',
          abierta: false,
        ),
      );
      if (mounted) {
        widget.onAgendadoCarta(nuevaCarta);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Carta creada para el ${widget.formatearFecha(_fechaSeleccionada)}!',
            ),
            backgroundColor: AppColors.violeta,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear carta: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            const Row(
              children: [
                Icon(
                  Icons.backpack_outlined,
                  color: AppColors.violeta,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  'Agendar Cita o crear carta',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selector de tipo
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Cita',
                    icon: Icons.backpack_outlined,
                    isSelected: typeDate == 'Cita',
                    onTap: () => setState(() => typeDate = 'Cita'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Carta',
                    icon: Icons.card_giftcard_outlined,
                    isSelected: typeDate == 'Carta',
                    onTap: () => setState(() => typeDate = 'Carta'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (typeDate == 'Cita') ...[
              _buildSelectorCita(),
              const SizedBox(height: 16),
              if (_esNuevaCita) ...[
                _buildTextField(
                  _tituloController,
                  'Título',
                  'Ej: Cena romántica',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _descripcionController,
                  'Descripción (opcional)',
                  'Ej: Reservación en el restaurante favorito',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildDetallesOpcionalesCita(),
              const SizedBox(height: 24),
              _buildConfirmButton('Confirmar Cita', _agendar),
            ],

            if (typeDate == 'Carta') ...[
              _buildTextField(_tituloController, 'Título', 'Te amo'),
              const SizedBox(height: 12),
              _buildTextField(
                _descripcionController,
                'Mensaje',
                'Escribe aquí tu carta...',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildCartaMediaPicker(
                label: 'Foto de la carta',
                emptyText: 'Agregar foto',
                readyText: 'Foto cargada',
                errorText: _imageError,
                isUploading: _isUploadingImage,
                hasFile: _imageUrl != null,
                icon: Icons.add_photo_alternate_outlined,
                readyIcon: Icons.image_outlined,
                onPick: _seleccionarImagenCarta,
                onRemove: _quitarImagenCarta,
              ),
              const SizedBox(height: 12),
              _buildCartaMediaPicker(
                label: 'Audio de la carta',
                emptyText: 'Agregar audio',
                readyText: 'Audio cargado',
                errorText: _audioError,
                isUploading: _isUploadingAudio,
                hasFile: _audioUrl != null,
                icon: Icons.audio_file_outlined,
                readyIcon: Icons.library_music_outlined,
                onPick: _seleccionarAudioCarta,
                onRemove: _quitarAudioCarta,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildConfirmButton('Confirmar Carta', _crearCarta),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCartaMediaPicker({
    required String label,
    required String emptyText,
    required String readyText,
    required String? errorText,
    required bool isUploading,
    required bool hasFile,
    required IconData icon,
    required IconData readyIcon,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final Color borderColor = errorText != null
        ? Colors.redAccent.shade100
        : hasFile
        ? AppColors.violeta
        : Colors.grey.shade300;
    final Color bgColor = errorText != null
        ? Colors.red.shade50
        : hasFile
        ? const Color(0xFFEDE9F5)
        : Colors.grey.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.violeta,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _selectorContainer(
          borderColor: borderColor,
          bgColor: bgColor,
          child: Row(
            children: [
              if (isUploading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.violeta,
                  ),
                )
              else
                Icon(
                  hasFile ? readyIcon : icon,
                  color: hasFile ? AppColors.violeta : Colors.grey,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUploading
                      ? 'Subiendo...'
                      : errorText != null
                      ? 'Error al subir'
                      : hasFile
                      ? readyText
                      : emptyText,
                  style: TextStyle(
                    fontSize: 15,
                    color: errorText != null
                        ? Colors.redAccent
                        : hasFile
                        ? AppColors.violeta
                        : Colors.grey,
                    fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasFile && !isUploading)
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                )
              else
                TextButton(
                  onPressed: isUploading ? null : onPick,
                  child: Text(errorText != null ? 'Reintentar' : 'Elegir'),
                ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violeta.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.violeta : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.violeta : Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.violeta : Colors.grey.shade500,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      maxLines: maxLines,
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

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.violeta, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFEDE9F5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.violeta,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              widget.formatearFecha(_fechaSeleccionada),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.violeta,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.violeta,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check_circle_outline),
      label: Text(_isLoading ? 'Guardando...' : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDetallesOpcionalesCita() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.violeta, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Detalles opcionales',
                  style: TextStyle(
                    color: AppColors.violeta,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(
                  () =>
                      _mostrarDetallesOpcionales = !_mostrarDetallesOpcionales,
                ),
                child: Text(_mostrarDetallesOpcionales ? 'Ocultar' : 'Agregar'),
              ),
            ],
          ),
          if (_mostrarDetallesOpcionales) ...[
            const SizedBox(height: 6),
            _buildSectionLabel('Itinerario'),
            if (_itinerarioActividadCtrls.isEmpty)
              _buildEmptyState(
                onAdd: _agregarItinerario,
                label: 'Agregar actividad',
              )
            else ...[
              for (var i = 0; i < _itinerarioActividadCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _itinerarioFechaCtrls[i],
                                'Fecha',
                                'dd-MM-yyyy',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTextField(
                                _itinerarioTiempoCtrls[i],
                                'Tiempo',
                                '18:30',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          _itinerarioActividadCtrls[i],
                          'Actividad',
                          'Ej: Cena en terraza',
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            tooltip: 'Eliminar actividad',
                            onPressed: () => _eliminarItinerario(i),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarItinerario,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar actividad'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildSectionLabel('Presupuesto'),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _presupuestoGastadoCtrl,
                    'Gastado',
                    '0.00',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    _presupuestoLimiteCtrl,
                    'Límite',
                    '0.00',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_conceptoNombreCtrls.isEmpty)
              _buildEmptyState(
                onAdd: _agregarConcepto,
                label: 'Agregar concepto de gasto',
              )
            else ...[
              for (var i = 0; i < _conceptoNombreCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _conceptoNombreCtrls[i],
                          'Concepto',
                          'Ej: Transporte',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          _conceptoMontoCtrls[i],
                          'Monto',
                          '0.00',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar concepto',
                        onPressed: () => _eliminarConcepto(i),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarConcepto,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar concepto'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildSectionLabel('Documentos (links)'),
            if (_documentoCtrls.isEmpty)
              _buildEmptyState(onAdd: _agregarDocumento, label: 'Agregar link')
            else ...[
              for (var i = 0; i < _documentoCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _documentoCtrls[i],
                          'Link',
                          'https://...',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Eliminar link',
                        onPressed: () => _eliminarDocumento(i),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _agregarDocumento,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar link'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.violeta,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required VoidCallback onAdd,
    required String label,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }

  Widget _buildSelectorCita() {
    if (_loadingCitas) {
      return _selectorContainer(
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.violeta,
              ),
            ),
            SizedBox(width: 12),
            Text('Cargando citas...', style: TextStyle(color: Colors.grey)),
          ],
        ),
        borderColor: Colors.grey.shade300,
        bgColor: Colors.grey.shade50,
      );
    }

    if (_errorCitas != null) {
      return GestureDetector(
        onTap: _fetchCitas,
        child: _selectorContainer(
          child: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text(
                'Error al cargar. Toca para reintentar.',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
          borderColor: Colors.redAccent.shade100,
          bgColor: Colors.red.shade50,
        ),
      );
    }

    final tieneCita = _citaSeleccionada != null;
    final label = !tieneCita
        ? 'Selecciona una cita'
        : _esNuevaCita
        ? '✏️  Nueva cita'
        : _citaSeleccionada!.nombre;

    return GestureDetector(
      onTap: _abrirSelectorCitas,
      child: _selectorContainer(
        child: Row(
          children: [
            Icon(
              Icons.backpack_outlined,
              color: tieneCita ? AppColors.violeta : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: tieneCita ? AppColors.violeta : Colors.grey,
                  fontWeight: tieneCita ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        borderColor: tieneCita ? AppColors.violeta : Colors.grey.shade300,
        bgColor: tieneCita ? const Color(0xFFEDE9F5) : Colors.grey.shade50,
      ),
    );
  }

  Widget _selectorContainer({
    required Widget child,
    required Color borderColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: bgColor,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet selector de citas
// ─────────────────────────────────────────────────────────────────────────────
class _CitaSelectorSheet extends StatefulWidget {
  final List<Cita> citas;
  final Cita? citaSeleccionada;
  final void Function(Cita) onSeleccionada;
  final VoidCallback onNuevaCita;

  const _CitaSelectorSheet({
    required this.citas,
    required this.citaSeleccionada,
    required this.onSeleccionada,
    required this.onNuevaCita,
  });

  @override
  State<_CitaSelectorSheet> createState() => _CitaSelectorSheetState();
}

class _CitaSelectorSheetState extends State<_CitaSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CitaQuickFilters _quickFilters = const CitaQuickFilters();

  List<Cita> get _filteredCitas {
    final citas = widget.citas.where(
      (cita) =>
          matchesCitaFilters(cita, query: _searchQuery, filters: _quickFilters),
    );

    return sortCitasBySearchRelevance(citas, _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCitas = _filteredCitas;
    final resultsKey = [
      _searchQuery,
      _quickFilters.categoria ?? '',
      _quickFilters.presupuesto ?? '',
      _quickFilters.typeLocation ?? '',
      ...filteredCitas.map((cita) => cita.nombre),
    ].join('|');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.backpack_outlined, color: AppColors.violeta),
                SizedBox(width: 8),
                Text(
                  'Elige una cita',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CitaSearchField(
                  controller: _searchController,
                  hintText: 'Busca por nombre, categoría, presupuesto o lugar',
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                CitaQuickFilterChips(
                  citas: widget.citas,
                  filters: _quickFilters,
                  query: _searchQuery,
                  onChanged: (filters) =>
                      setState(() => _quickFilters = filters),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: AppColors.violeta),
            ),
            title: const Text(
              'Nueva cita',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.violeta,
              ),
            ),
            subtitle: const Text('Escribe el título y descripción manualmente'),
            onTap: () {
              Navigator.of(context).pop();
              widget.onNuevaCita();
            },
          ),
          const Divider(height: 1),
          Flexible(
            child: CitaResultsSwitcher(
              transitionKey: resultsKey,
              child: filteredCitas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No hay citas que coincidan con tu búsqueda',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredCitas.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (ctx, i) {
                        final cita = filteredCitas[i];
                        final isSelected =
                            widget.citaSeleccionada?.nombre == cita.nombre;
                        final summary = citaSearchSummary(cita);
                        final showDescription = shouldShowCitaDescription(
                          cita,
                          _searchQuery,
                        );
                        final descriptionPrimaryMatch =
                            isDescriptionPrimaryMatch(cita, _searchQuery);
                        final titleStyle = TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.violeta
                              : Colors.black87,
                        );
                        final descriptionStyle = TextStyle(
                          color: Colors.grey.shade600,
                        );
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.violeta
                                  : const Color(0xFFEDE9F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.backpack_outlined,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.violeta,
                              size: 20,
                            ),
                          ),
                          title: CitaHighlightedText(
                            cita.nombre,
                            query: _searchQuery,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                            highlightStyle: titleStyle.copyWith(
                              fontWeight: FontWeight.w800,
                              backgroundColor: AppColors.malva.withValues(
                                alpha: 0.32,
                              ),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (descriptionPrimaryMatch) ...[
                                const SizedBox(height: 2),
                                const CitaDescriptionMatchBadge(),
                                const SizedBox(height: 4),
                              ],
                              if (summary.isNotEmpty)
                                CitaHighlightedText(
                                  summary,
                                  query: _searchQuery,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (showDescription) ...[
                                if (summary.isNotEmpty)
                                  const SizedBox(height: 2),
                                CitaHighlightedText(
                                  cita.descripcion,
                                  query: _searchQuery,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: descriptionStyle,
                                  highlightStyle: descriptionStyle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    backgroundColor: AppColors.celeste
                                        .withOpacity(0.38),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.violeta,
                                )
                              : null,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSeleccionada(cita);
                          },
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet: crear recuerdo
// ─────────────────────────────────────────────────────────────────────────────
class _CrearRecuerdoSheet extends StatefulWidget {
  final DateTime fechaInicial;
  final EventService service;
  final String Function(DateTime) formatearFecha;
  final void Function(Recuerdo) onCreado;

  const _CrearRecuerdoSheet({
    required this.fechaInicial,
    required this.service,
    required this.formatearFecha,
    required this.onCreado,
  });

  @override
  State<_CrearRecuerdoSheet> createState() => _CrearRecuerdoSheetState();
}

class _CrearRecuerdoSheetState extends State<_CrearRecuerdoSheet> {
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final UploadService _uploadService = UploadService();

  late DateTime _fechaSeleccionada;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _imageUrl;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.fechaInicial;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.violeta,
            onPrimary: Colors.white,
            onSurface: AppColors.violeta,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  Future<void> _seleccionarImagenRecuerdo() async {
    setState(() {
      _isUploadingImage = true;
      _imageError = null;
    });

    try {
      final publicUrl = await _uploadService.pickAndUpload();
      if (!mounted) return;
      setState(() {
        _imageUrl = publicUrl;
        _isUploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _imageError = e.toString();
        _isUploadingImage = false;
      });
    }
  }

  void _quitarImagenRecuerdo() {
    setState(() {
      _imageUrl = null;
      _imageError = null;
    });
  }

  Future<void> _crearRecuerdo() async {
    final titulo = _tituloController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es obligatorio')));
      return;
    }

    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Espera a que termine de subir la imagen'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final nuevoRecuerdo = await widget.service.createRecuerdo(
        Recuerdo(
          id: '',
          title: titulo,
          description: descripcion,
          date: widget.formatearFecha(_fechaSeleccionada),
          imagePath: _imageUrl ?? '',
        ),
      );

      if (!mounted) return;
      widget.onCreado(nuevoRecuerdo);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear recuerdo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const Row(
              children: [
                Icon(
                  Icons.movie_creation_outlined,
                  color: AppColors.violeta,
                  size: 26,
                ),
                SizedBox(width: 10),
                Text(
                  'Crear recuerdo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _tituloController,
              label: 'Título *',
              hint: 'Ej: Nuestro primer viaje juntos',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descripcionController,
              label: 'Descripción (opcional)',
              hint: 'Cuenta qué pasó en este momento especial',
              maxLines: 3,
            ),
            const SizedBox(height: 14),
            _buildDatePicker(),
            const SizedBox(height: 14),
            _buildImagePicker(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _crearRecuerdo,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar recuerdo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      maxLines: maxLines,
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

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.violeta, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFEDE9F5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.violeta,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              widget.formatearFecha(_fechaSeleccionada),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.violeta,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.edit_calendar_outlined,
              color: AppColors.violeta,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasImage = _imageUrl != null;
    final borderColor = _imageError != null
        ? Colors.redAccent.shade100
        : hasImage
        ? AppColors.violeta
        : Colors.grey.shade300;
    final bgColor = _imageError != null
        ? Colors.red.shade50
        : hasImage
        ? const Color(0xFFEDE9F5)
        : Colors.grey.shade50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Imagen (opcional)',
          style: TextStyle(
            color: AppColors.violeta,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
          ),
          child: Row(
            children: [
              if (_isUploadingImage)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.violeta,
                  ),
                )
              else
                Icon(
                  hasImage
                      ? Icons.image_outlined
                      : Icons.add_photo_alternate_outlined,
                  color: hasImage ? AppColors.violeta : Colors.grey,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isUploadingImage
                      ? 'Subiendo...'
                      : _imageError != null
                      ? 'Error al subir'
                      : hasImage
                      ? 'Imagen cargada'
                      : 'Agregar imagen',
                  style: TextStyle(
                    fontSize: 15,
                    color: _imageError != null
                        ? Colors.redAccent
                        : hasImage
                        ? AppColors.violeta
                        : Colors.grey,
                    fontWeight: hasImage ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasImage && !_isUploadingImage)
                IconButton(
                  tooltip: 'Quitar',
                  onPressed: _quitarImagenRecuerdo,
                  icon: const Icon(Icons.close, size: 18),
                  color: Colors.grey,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                )
              else
                TextButton(
                  onPressed: _isUploadingImage
                      ? null
                      : _seleccionarImagenRecuerdo,
                  child: Text(_imageError != null ? 'Reintentar' : 'Elegir'),
                ),
            ],
          ),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: 4),
          Text(
            _imageError!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
