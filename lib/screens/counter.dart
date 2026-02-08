import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../models/fecha.dart';

class ProximaCitaCounter extends StatefulWidget {
  final List<EventoImportante> eventos;
  const ProximaCitaCounter({super.key, required this.eventos});

  @override
  State<ProximaCitaCounter> createState() => _ProximaCitaCounterState();
}

class _ProximaCitaCounterState extends State<ProximaCitaCounter> {
  late ConfettiController _confettiController;
  Timer? _timer;
  Duration _duration = const Duration();
  EventoImportante? proximoEvento;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 10));
    _calcularProximoEvento();
    _startTimer();
  }

  void _calcularProximoEvento() {
    DateTime now = DateTime.now();
    DateFormat format = DateFormat("dd-MM-yyyy");

    // Filtramos eventos futuros y ordenamos por el más cercano
    List<EventoImportante> futuros = widget.eventos.where((e) {
      return format.parse(e.fecha).isAfter(now);
    }).toList();

    futuros.sort((a, b) => format.parse(a.fecha).compareTo(format.parse(b.fecha)));

    if (futuros.isNotEmpty) {
      setState(() {
        proximoEvento = futuros.first;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (proximoEvento == null) return;

      DateTime eventDate = DateFormat("dd-MM-yyyy").parse(proximoEvento!.fecha);
      final remaining = eventDate.difference(DateTime.now());

      if (remaining.isNegative) {
        timer.cancel();
        _confettiController.play(); // ¡ANIMACIÓN DE CELEBRACIÓN!
      } else {
        setState(() {
          _duration = remaining;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (proximoEvento == null) return const Text("¡No hay citas próximas!");

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            Text(
              "FALTA PARA: ${proximoEvento!.nombre.toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeColumn(_duration.inDays.toString(), "Días"),
                _buildTimeColumn((_duration.inHours % 24).toString(), "Hrs"),
                _buildTimeColumn((_duration.inMinutes % 60).toString(), "Min"),
                _buildTimeColumn((_duration.inSeconds % 60).toString(), "Seg"),
              ],
            ),
          ],
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          colors: const [Colors.pink, Colors.blue, Colors.orange, Colors.purple],
        ),
      ],
    );
  }

  Widget _buildTimeColumn(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF796B9B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value.padLeft(2, '0'), 
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF796B9B))),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}