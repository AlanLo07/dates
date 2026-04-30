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
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/colors.dart';
import '../models/recuerdos.dart';
import '../models/carta.dart';
import '../models/fecha.dart';
import '../models/cita.dart';
import '../services/events.dart';
import '../services/cita_service.dart';
import 'counter.dart';
import 'letters.dart';

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
            placeholder: (_, __) => SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) => _fallback(),
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
          color: value ? activeColor.withOpacity(0.15) : Colors.transparent,
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
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.violeta,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recuerdo.description,
                      textAlign: TextAlign.center,
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
        onAgendado: (e) => setState(() => _eventos.add(e)),
        onAgendadoCarta: (c) => setState(() => _cartas.add(c)),
        service: _service,
        formatearFecha: _toApiDateKey,
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.violeta),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                _buildFilterBar(),
                const SizedBox(height: 8),
                if (_eventos.isNotEmpty) ProximaCitaCounter(eventos: _eventos),
                const SizedBox(height: 8),
                Expanded(
                  child: TableCalendar(
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
                          style: const TextStyle(color: AppColors.violeta),
                        ),
                      ),
                      // ── markerBuilder ahora usa _DayData directamente ──────
                      // No hay triple lookup por día.
                      markerBuilder: (ctx, day, events) {
                        if (events.isEmpty) return null;

                        // Determinamos el tipo del primer evento
                        final first = events.first;

                        if (first is Recuerdo && _mostrarRecuerdos) {
                          if (first.imagePath.isNotEmpty) {
                            return Positioned(
                              bottom: 1,
                              child: Hero(
                                tag: 'recuerdo-${first.id}',
                                child: _buildThumbnail(first.imagePath),
                              ),
                            );
                          }
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                size: 16,
                                color: Colors.pinkAccent,
                              ),
                            ),
                          );
                        }

                        if (first is CartaSorpresa && _mostrarCartas) {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final localDay = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          final bloqueada =
                              localDay.isAfter(today) || !first.abierta;
                          return Positioned(
                            bottom: 1,
                            child: Icon(
                              bloqueada ? Icons.lock : Icons.lock_open,
                              color: bloqueada
                                  ? AppColors.locked
                                  : AppColors.unlocked,
                              size: 16,
                            ),
                          );
                        }

                        if (first is EventoImportante && _mostrarCitas) {
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.violeta.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
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
                        await _verificarCarta(selectedDay, data.carta!);
                        return;
                      }
                      if (data.recuerdos.isNotEmpty && _mostrarRecuerdos) {
                        _showRecuerdoDialog(data.recuerdos.first);
                        return;
                      }
                      if (data.evento != null && _mostrarCitas) {
                        _showEventoDialog(data.evento!);
                        return;
                      }

                      _mostrarAgendarDesdeCalendario(selectedDay);
                    },
                    selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
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

  const _EventoDialog({
    required this.evento,
    required this.iconFromString,
    required this.onDelete,
  });

  @override
  State<_EventoDialog> createState() => _EventoDialogState();
}

class _EventoDialogState extends State<_EventoDialog> {
  bool _isDeleting = false;

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
  bool _isLoading = false;

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
    super.dispose();
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
      final nuevoEvento = await widget.service.createEvento(
        EventoImportante(
          id: '',
          title: _tituloFinal,
          description: _descripcionFinal,
          date: widget.formatearFecha(_fechaSeleccionada),
          icon: 'backpack_outlined',
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

  Future<void> _crearCarta() async {
    if (_tituloCartaFinal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un título')),
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
              _buildDatePicker(),
              const SizedBox(height: 24),
              _buildConfirmButton('Confirmar Carta', _crearCarta),
            ],
          ],
        ),
      ),
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
              ? AppColors.violeta.withOpacity(0.1)
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
class _CitaSelectorSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              onNuevaCita();
            },
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: citas.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (ctx, i) {
                final cita = citas[i];
                final isSelected = citaSeleccionada?.nombre == cita.nombre;
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
                      color: isSelected ? Colors.white : AppColors.violeta,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    cita.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.violeta : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    cita.descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.violeta)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSeleccionada(cita);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
