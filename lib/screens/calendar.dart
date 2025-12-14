// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/date.dart';
import '../data/dates.dart';

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
    // 1. Formatear la clave a 'MM-DD'
    // Ejemplo: Si el mes es 12 y el día es 3, devuelve '12-03'
    final month = day.month.toString().padLeft(2, '0');
    final dayOfMonth = day.day.toString().padLeft(2, '0');
    final key = '$month-$dayOfMonth';

    // 2. Buscar en el Map kImportantDates
    return kImportantDates[key] ?? [];
  }

  // Función auxiliar para simplificar la clave de fecha
  DateTime _date(int year, int month, int day) =>
      DateTime.utc(year, month, day);

  // 2. Diálogo para mostrar los detalles del evento (Expansión)
  void _showEventDetailsRoute(List<DateEvent> events, String heroTag) {
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
      body: TableCalendar(
        firstDay: _date(
          DateTime.now().year - 1,
          1,
          1,
        ), // Rango de visualización
        lastDay: _date(DateTime.now().year + 1, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month, // Mostrar siempre el mes completo
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
          rightChevronIcon: Icon(Icons.chevron_right, color: violetaProfundo),
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
            if (events.isNotEmpty) {
              final event = events.first as DateEvent;
              // El tag debe ser único. Usamos la ruta de la imagen como clave.
              final heroTag = 'event-image-${event.imagePath}';

              return Positioned(
                bottom: 1,
                child: Hero(
                  tag: heroTag, // Define el tag Hero
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: Image.asset(
                      event.imagePath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            }
            return null; // No hay evento, no hay marcador
          },
        ),

        // 4. Lógica al tocar un día
        onDaySelected: (selectedDay, focusedDay) {
          final events = _getEventsForDay(selectedDay);
          if (events.isNotEmpty) {
            final heroTag = 'event-image-${(events.first).imagePath}';
            _showEventDetailsRoute(
              events,
              heroTag,
            ); // Muestra el diálogo de expansión
          }
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
      ),
    );
  }
}
