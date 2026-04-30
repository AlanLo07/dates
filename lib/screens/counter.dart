// lib/screens/counter.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../models/fecha.dart';
import '../utils/colors.dart';

class ProximaCitaCounter extends StatefulWidget {
  final List<EventoImportante> eventos;
  const ProximaCitaCounter({super.key, required this.eventos});

  @override
  State<ProximaCitaCounter> createState() => _ProximaCitaCounterState();
}

class _ProximaCitaCounterState extends State<ProximaCitaCounter>
    with WidgetsBindingObserver {
  late ConfettiController _confettiController;
  Timer? _timer;
  Duration _duration = Duration.zero;
  EventoImportante? _proximoEvento;

  static final DateFormat _fmt = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Para pausar en background
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    );
    _calcularProximoEvento();
    _startTimer();
  }

  // ── Pausa el timer cuando la app va al background ─────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _calcularProximoEvento();
      _startTimer();
    }
  }

  // ── Recalcula cuando cambia la lista de eventos (hot-reload safe) ─────────
  @override
  void didUpdateWidget(ProximaCitaCounter old) {
    super.didUpdateWidget(old);
    if (old.eventos != widget.eventos) {
      _timer?.cancel();
      _calcularProximoEvento();
      _startTimer();
    }
  }

  void _calcularProximoEvento() {
    final now = DateTime.now();

    final futuros =
        widget.eventos.where((e) {
            try {
              return _fmt.parse(e.date).isAfter(now);
            } catch (_) {
              return false;
            }
          }).toList()
          ..sort((a, b) => _fmt.parse(a.date).compareTo(_fmt.parse(b.date)));

    if (mounted) {
      setState(
        () => _proximoEvento = futuros.isNotEmpty ? futuros.first : null,
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_proximoEvento == null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final eventDate = _fmt.parse(_proximoEvento!.date);
      final remaining = eventDate.difference(DateTime.now());

      if (remaining.isNegative) {
        _timer?.cancel();
        _confettiController.play();
        setState(() => _duration = Duration.zero);
      } else {
        setState(() => _duration = remaining);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_proximoEvento == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          '¡No hay eventos próximos!',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
      );
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                'FALTA PARA: ${_proximoEvento!.title.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeColumn(_duration.inDays.toString(), 'Días'),
                  _buildSeparator(),
                  _buildTimeColumn((_duration.inHours % 24).toString(), 'Hrs'),
                  _buildSeparator(),
                  _buildTimeColumn(
                    (_duration.inMinutes % 60).toString(),
                    'Min',
                  ),
                  _buildSeparator(),
                  _buildTimeColumn(
                    (_duration.inSeconds % 60).toString(),
                    'Seg',
                  ),
                ],
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          colors: const [
            Colors.pink,
            Colors.blue,
            Colors.orange,
            Colors.purple,
          ],
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.violeta,
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.violeta.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value.padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
