// lib/screens/calendar_screen.dart
import 'package:dates/models/recuerdos.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/date.dart';
import '../data/dates.dart';
import '../models/fecha.dart';
import 'counter.dart';
import '../models/carta.dart';
import 'package:intl/intl.dart';
import 'letters.dart';

// Colores de tu paleta
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

  // 1. Función para obtener los eventos de un día
  List<DateEvent> _getEventsForDay(DateTime day) {
    // Formateamos el día seleccionado para comparar (dd-mm-yyyy)
    // Nota: Usamos 2023 porque tus recuerdos actuales están en ese año
    String selectedDate = DateFormat("dd-MM-yyyy").format(day);

    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    final dayMonthKey = '$dayOfMonth-$month';

    // 2. Filtramos los recuerdos comparando solo los primeros 5 caracteres (dd-mm)
    // o extrayendo el día y mes de su propiedad .date
    List<DateEvent> recuerdosDelDia = kImportantDates.where((r) {
      // r.date tiene formato "dd-mm-yyyy", tomamos solo "dd-mm"
      return r.date.startsWith(dayMonthKey);
    }).toList();
    // 2. Buscamos en Cartas
    List<DateEvent> cartasDelDia = misCartas
        .where((c) => c.date == selectedDate)
        .toList();

    // 3. Buscamos en Eventos Importantes
    List<DateEvent> citasDelDia = misEventos
        .where((e) => e.date == selectedDate)
        .toList();

    // Retornamos la unión de todas las listas
    return [...recuerdosDelDia, ...cartasDelDia, ...citasDelDia];
  }

  // Función auxiliar para simplificar la clave de fecha
  DateTime _date(int year, int month, int day) =>
      DateTime.utc(year, month, day);

  // 2. Diálogo para mostrar los detalles del evento (Expansión)
  void _showEventDetailsRoute(List<Recuerdo> events, String heroTag) {
    final event =
        events.first; // Solo mostramos el primer evento por simplicidad

    Navigator.of(context).push(
      PageRouteBuilder(
        // Transición rápida y sencilla
        transitionDuration: const Duration(milliseconds: 400),
        // Hace que la pantalla anterior se desvanezca
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          // Usa un Center para que el contenido parezca un diálogo centrado
          return Center(
            child: ScaleTransition(
              // Añadimos una transición de escala al diálogo mismo
              scale: animation,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                // Usamos SingleChildScrollView para el contenido
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // *** DESTINO HERO ***
                      Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            event.imagePath,
                            width: 500,
                            height: 500,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        event.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: violetaProfundo,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        event.description,
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Foscus day $_focusedDay");
    return Scaffold(
      backgroundColor: lavandaPalida,
      appBar: AppBar(
        title: const Text(
          'Fechas Importantes',
          style: TextStyle(color: violetaProfundo),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: violetaProfundo),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          ProximaCitaCounter(eventos: misEventos), // Tu lista de eventos
          const SizedBox(height: 20),
          TableCalendar(
            firstDay: _date(
              DateTime.now().year - 1,
              1,
              1,
            ), // Rango de visualización
            lastDay: _date(DateTime.now().year + 1, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat:
                CalendarFormat.month, // Mostrar siempre el mes completo
            // Estilos de la cabecera (Header)
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: violetaProfundo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: violetaProfundo),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: violetaProfundo,
              ),
            ),

            // Estilos de los Días de la Semana
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

            // Eventos: Llama a la función para cargar los eventos
            eventLoader: _getEventsForDay,

            // 3. Estilo y Lógica de los Cuadrados (Día)
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                // Personaliza los días normales (fondo)
                return Container(
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    day.day.toString(),
                    style: const TextStyle(color: violetaProfundo),
                  ),
                );
              },
              // Constructor para celdas con eventos
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;

                final dateEvents = events.cast<DateEvent>();

                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: dateEvents.map((event) {
                      if (event is Carta) {
                        DateTime now = DateTime.now();
                        // Solo comparamos la fecha sin la hora para desbloquear justo a medianoche
                        bool estaBloqueada = day.isAfter(
                          DateTime(now.year, now.month, now.day),
                        );

                        return Positioned(
                          bottom: 1,
                          child: Icon(
                            estaBloqueada ? Icons.lock : Icons.lock_open,
                            color: estaBloqueada
                                ? Colors.grey
                                : Colors.pinkAccent,
                            size: 16,
                          ),
                        );
                      } else if (event is EventoImportante) {
                        return Positioned(
                          bottom: 1,
                          child: Icon(
                            event.icon,
                            color: Colors.deepPurple,
                            size: 16,
                          ),
                        );
                      } else if (event is Recuerdo) {
                        // Agregamos el año al Hero Tag para que sea único por celda
                        final heroTag =
                            'marker-${event.imagePath}-${day.year}-${day.month}-${day.day}';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                event.imagePath,
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    }).toList(),
                  ),
                );
              },
            ),

            // 4. Lógica al tocar un día
            onDaySelected: (selectedDay, focusedDay) {
              _verificarCarta(selectedDay);
              _verificarEvento(selectedDay);
              final events = _getEventsForDay(selectedDay);
              if (events.isNotEmpty) {
                final firstEvent = events.first;

                // Solo disparamos el detalle si el primer evento es un Recuerdo
                if (firstEvent is Recuerdo) {
                  final heroTag =
                      'marker-${firstEvent.imagePath}-${selectedDay.year}-${selectedDay.month}-${selectedDay.day}';

                  _showEventDetailsRoute(
                    events
                        .cast<Recuerdo>()
                        .toList(), // Casteamos la lista para el detalle
                    heroTag,
                  ); // Muestra el diálogo de expansión
                }
              }
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
          ),
        ],
      ),
    );
  }

  void _verificarCarta(DateTime date) {
    String formattedDate = DateFormat("dd-MM-yyyy").format(date);

    try {
      Carta cartaEncontrada = misCartas.firstWhere(
        (c) => c.date == formattedDate,
      );

      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);

      if (date.isAfter(today)) {
        // Caso: Bloqueado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔒 ¡Aún no es tiempo! Espera a la fecha."),
          ),
        );
      } else {
        // Caso: Desbloqueado - Abrir animación
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LetterScreen(carta: cartaEncontrada),
          ),
        );
      }
    } catch (e) {
      // No hay carta en esta fecha, no pasa nada
    }
  }

  void _verificarEvento(DateTime date) {
    String formattedDate = DateFormat("dd-MM-yyyy").format(date);

    try {
      EventoImportante eventoEncontrado = misEventos.firstWhere(
        (c) => c.date == formattedDate,
      );

      String heroTag =
          'marker-${eventoEncontrado.title}-${date.year}-${date.month}-${date.day}';

      Navigator.of(context).push(
        PageRouteBuilder(
          // Transición rápida y sencilla
          transitionDuration: const Duration(milliseconds: 400),
          // Hace que la pantalla anterior se desvanezca
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            // Usa un Center para que el contenido parezca un diálogo centrado
            return Center(
              child: ScaleTransition(
                // Añadimos una transición de escala al diálogo mismo
                scale: animation,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Colors.white,
                  // Usamos SingleChildScrollView para el contenido
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // *** DESTINO HERO ***
                        Hero(
                          tag: heroTag,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Icon(
                              eventoEncontrado.icon,
                              color: Colors.deepPurple,
                              size: 50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          eventoEncontrado.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: violetaProfundo,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          eventoEncontrado.description,
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
            );
          },
        ),
      );
    } catch (e) {}
  }
}
