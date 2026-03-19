import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:intl/intl.dart';

import '../models/recuerdos.dart';
import '../models/carta.dart';
import '../models/fecha.dart';
import '../services/events.dart';
import 'counter.dart';
import 'letters.dart';

const Color violetaProfundo = Color(0xFF796B9B);
const Color lavandaPalida = Color(0xFFD8C9E7);
const Color azulCelestePastel = Color(0xFFA9D1DF);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

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

  // ── Helpers de fecha ──────────────────────────────────────────────────────

  // Convierte un DateTime del calendario a "dd-MM-yyyy" de forma segura,
  // normalizando primero a local para evitar offset UTC.
  String _toApiDateKey(DateTime day) {
    final local = DateTime(day.year, day.month, day.day);
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    return '$dd-$mm-$yyyy';
  }

  // Para recuerdos: compara solo mes-día (aniversarios recurrentes cada año).
  // Formato "MM-DD".
  String _toMonthDayKey(DateTime day) {
    final local = DateTime(day.year, day.month, day.day);
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$mm-$dd';
  }

  // Extrae "MM-DD" de una fecha "dd-MM-yyyy" de la API.
  String _monthDayFromApiDate(String apiDate) {
    // apiDate = "28-11-2023" → partes[0]=28, partes[1]=11
    final partes = apiDate.split('-');
    if (partes.length != 3) return '';
    return '${partes[1]}-${partes[0]}'; // MM-DD
  }

  // ── Getters por día ───────────────────────────────────────────────────────

  List<Recuerdo> _getRecuerdosForDay(DateTime day) {
    final key = _toMonthDayKey(day); // "MM-DD"
    return _recuerdos.where((r) {
      return _monthDayFromApiDate(r.date) == key;
    }).toList();
  }

  CartaSorpresa? _getCartaForDay(DateTime day) {
    final key = _toApiDateKey(day); // "dd-MM-yyyy" exacta
    try {
      return _cartas.firstWhere((c) => c.date == key);
    } catch (_) {
      return null;
    }
  }

  EventoImportante? _getEventoForDay(DateTime day) {
    final key = _toApiDateKey(day); // "dd-MM-yyyy" exacta
    try {
      return _eventos.firstWhere((e) => e.date == key);
    } catch (_) {
      return null;
    }
  }

  List<Object> _getEventsForDay(DateTime day) {
    return [
      ..._getRecuerdosForDay(day),
      if (_getCartaForDay(day) != null) _getCartaForDay(day)!,
      if (_getEventoForDay(day) != null) _getEventoForDay(day)!,
    ];
  }

  // ── Widgets de imagen seguros ─────────────────────────────────────────────

  Widget _buildImageWidget(
    String imagePath, {
    double width = 300,
    double height = 300,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imagePath.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: lavandaPalida,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.image_not_supported,
          size: 48,
          color: violetaProfundo,
        ),
      );
    }
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: lavandaPalida,
          child: const Icon(
            Icons.broken_image,
            size: 48,
            color: violetaProfundo,
          ),
        ),
      );
    }
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: lavandaPalida,
        child: const Icon(Icons.broken_image, size: 48, color: violetaProfundo),
      ),
    );
  }

  Widget _buildThumbnail(String imagePath) {
    const double size = 50;
    if (imagePath.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: lavandaPalida,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.photo, size: 20, color: violetaProfundo),
      );
    }
    if (imagePath.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(width: size, height: size, color: lavandaPalida),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(width: size, height: size, color: lavandaPalida),
      ),
    );
  }

  // ── IconData desde string ─────────────────────────────────────────────────

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

  // ── Diálogo de recuerdo ───────────────────────────────────────────────────

  void _showRecuerdoDialog(Recuerdo recuerdo) {
    final heroTag = 'recuerdo-${recuerdo.id}';
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        opaque: false,
        pageBuilder: (context, animation, _) => Center(
          child: ScaleTransition(
            scale: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: heroTag,
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
                        color: violetaProfundo,
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
                    style: TextStyle(color: azulCelestePastel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Diálogo de evento ─────────────────────────────────────────────────────

  void _showEventoDialog(EventoImportante evento) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        opaque: false,
        pageBuilder: (context, animation, _) => Center(
          child: ScaleTransition(
            scale: animation,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: lavandaPalida,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _iconFromString(evento.icon),
                      size: 64,
                      color: violetaProfundo,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    evento.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: violetaProfundo,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    evento.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evento.date,
                    style: const TextStyle(
                      color: azulCelestePastel,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: azulCelestePastel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lógica de carta ───────────────────────────────────────────────────────

  Future<void> _verificarCarta(DateTime day) async {
    final carta = _getCartaForDay(day);
    if (carta == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDay = DateTime(day.year, day.month, day.day);

    // Carta bloqueada: la fecha aún no llega
    if (localDay.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 ¡Aún no es tiempo! Espera a la fecha."),
        ),
      );
      return;
    }

    // Carta disponible: respetar campo abierta
    if (carta.abierta) {
      // Ya fue abierta antes → ir directo sin llamar a la API de nuevo
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LetterScreen(carta: carta)));
      return;
    }

    // Primera vez que se abre → llamar al PATCH
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
      // CORS en web / error de red → abrir localmente de todas formas
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LetterScreen(carta: carta)));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  DateTime _date(int year, int month, int day) =>
      DateTime.utc(year, month, day);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lavandaPalida,
      appBar: AppBar(
        title: const Text(
          'Fechas Importantes',
          style: TextStyle(color: violetaProfundo),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: violetaProfundo),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                const SizedBox(height: 20),
                if (_eventos.isNotEmpty) ProximaCitaCounter(eventos: _eventos),
                const SizedBox(height: 20),
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
                        color: violetaProfundo,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: violetaProfundo,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: violetaProfundo,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: violetaProfundo,
                        fontWeight: FontWeight.bold,
                      ),
                      weekendStyle: TextStyle(
                        color: violetaProfundo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    eventLoader: _getEventsForDay,
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) => Container(
                        margin: const EdgeInsets.all(4.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          day.day.toString(),
                          style: const TextStyle(color: violetaProfundo),
                        ),
                      ),
                      markerBuilder: (context, day, events) {
                        final recuerdos = _getRecuerdosForDay(day);
                        final carta = _getCartaForDay(day);
                        final evento = _getEventoForDay(day);

                        // 1. Recuerdo — miniatura
                        if (recuerdos.isNotEmpty) {
                          final r = recuerdos.first;
                          if (r.imagePath.isNotEmpty) {
                            return Positioned(
                              bottom: 1,
                              child: Hero(
                                tag: 'recuerdo-${r.id}',
                                child: _buildThumbnail(r.imagePath),
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

                        // 2. Carta — candado (respeta campo abierta)
                        if (carta != null) {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final localDay = DateTime(
                            day.year,
                            day.month,
                            day.day,
                          );
                          // Bloqueada si la fecha aún no llega O si abierta == false
                          final bloqueada =
                              localDay.isAfter(today) || !carta.abierta;
                          return Positioned(
                            bottom: 1,
                            child: Icon(
                              bloqueada ? Icons.lock : Icons.lock_open,
                              color: bloqueada
                                  ? Colors.grey
                                  : Colors.pinkAccent,
                              size: 16,
                            ),
                          );
                        }

                        // 3. Evento — ícono
                        if (evento != null) {
                          return Positioned(
                            bottom: 1,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: violetaProfundo.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                _iconFromString(evento.icon),
                                size: 16,
                                color: violetaProfundo,
                              ),
                            ),
                          );
                        }

                        return null;
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) async {
                      setState(() => _focusedDay = focusedDay);

                      final carta = _getCartaForDay(selectedDay);
                      final recuerdos = _getRecuerdosForDay(selectedDay);
                      final evento = _getEventoForDay(selectedDay);

                      // Prioridad: carta > recuerdo > evento
                      if (carta != null) {
                        await _verificarCarta(selectedDay);
                        return;
                      }
                      if (recuerdos.isNotEmpty) {
                        _showRecuerdoDialog(recuerdos.first);
                        return;
                      }
                      if (evento != null) {
                        _showEventoDialog(evento);
                      }
                    },
                    selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
                  ),
                ),
              ],
            ),
    );
  }
}
