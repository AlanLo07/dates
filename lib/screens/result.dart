// lib/screens/result_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../services/cita_service.dart';

class FadingTitle extends StatefulWidget {
  final String title;

  const FadingTitle({required this.title, super.key});

  @override
  State<FadingTitle> createState() => _FadingTitleState();
}

class _FadingTitleState extends State<FadingTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color violetaProfundo = Color(0xFF796B9B);

    return FadeTransition(
      opacity: _opacityAnimation,
      child: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: violetaProfundo,
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final Cita cita;

  const ResultScreen({required this.cita, super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('No se pudo abrir el enlace $url');
    }
  }

  Widget _buildMediaWidget() {
    if (cita.imagenUrl.isEmpty) {
      return const Icon(
        Icons.favorite_border,
        size: 80,
        color: violetaProfundo,
      );
    }

    if (cita.imagenUrl.endsWith('.json')) {
      return Lottie.network(
        cita.imagenUrl,
        width: 250,
        height: 250,
        repeat: true,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: CachedNetworkImage(
        imageUrl: cita.imagenUrl,
        width: 250,
        height: 250,
        fit: BoxFit.scaleDown,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(
          Icons.image_not_supported_outlined,
          size: 80,
          color: violetaProfundo,
        ),
      ),
    );
  }

  /// Abre el bottom sheet para seleccionar la fecha y agendar la cita
  void _mostrarAgendarCita(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgendarCitaSheet(cita: cita),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¡Su Plan de Aniversario!'),
        backgroundColor: grisClaroCalido,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildMediaWidget(),
              const SizedBox(height: 20),

              FadingTitle(title: cita.nombre),
              const SizedBox(height: 15),

              Text(
                cita.descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: violetaProfundo),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetail(
                    Icons.attach_money,
                    'Presupuesto: ${cita.presupuesto}',
                  ),
                  _buildDetail(Icons.access_time, 'Tiempo: ${cita.tiempo}h'),
                ],
              ),
              const SizedBox(height: 50),

              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Icon(
                    index < (cita.rating) ? Icons.star : Icons.star_border,
                    color: Colors.black,
                    size: 28,
                  );
                }),
              ),

              const SizedBox(height: 30),

              // ── Botón Agendar Cita ──────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => _mostrarAgendarCita(context),
                icon: const Icon(Icons.backpack_outlined),
                label: const Text('Agendar Cita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: violetaProfundo,
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

              const SizedBox(height: 16),

              // Botón de Enlace
              if (cita.link.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(cita.link),
                  icon: const Icon(Icons.link),
                  label: const Text('Ver Detalles / Mapa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: malvaSuave,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 40, color: violetaProfundo),
        const SizedBox(height: 5),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet: formulario para agendar la cita con fecha
// ─────────────────────────────────────────────────────────────────────────────
class _AgendarCitaSheet extends StatefulWidget {
  final Cita cita;

  const _AgendarCitaSheet({required this.cita});

  @override
  State<_AgendarCitaSheet> createState() => _AgendarCitaSheetState();
}

class _AgendarCitaSheetState extends State<_AgendarCitaSheet> {
  DateTime? _fechaSeleccionada;
  bool _isLoading = false;

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: violetaProfundo,
              onPrimary: Colors.white,
              onSurface: violetaProfundo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _fechaSeleccionada = picked);
    }
  }

  String _formatearFecha(DateTime date) {
    // Formato dd-MM-yyyy para consistencia con el resto de la app
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d-$m-$y';
  }

  Future<void> _agendarCita() async {
    if (_fechaSeleccionada == null) return;

    setState(() => _isLoading = true);

    try {
      // Construimos el evento usando DateEvent como referencia,
      // pero guardamos vía la API de citas con la fecha embebida.
      // Reutilizamos ApiService para crear/actualizar la cita agendada.
      final citaAgendada = widget.cita;

      await ApiService().agendarCita(
        cita: citaAgendada,
        fecha: _formatearFecha(_fechaSeleccionada!),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Cierra el sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Cita agendada para el ${_formatearFecha(_fechaSeleccionada!)}!',
            ),
            backgroundColor: violetaProfundo,
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
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

          // Título
          Row(
            children: [
              const Icon(
                Icons.backpack_outlined,
                color: violetaProfundo,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agendar: ${widget.cita.nombre}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: violetaProfundo,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Descripción (preview)
          Text(
            widget.cita.descripcion,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),

          // Selector de fecha
          GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _fechaSeleccionada != null
                      ? violetaProfundo
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _fechaSeleccionada != null
                    ? const Color(0xFFEDE9F5)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _fechaSeleccionada != null
                        ? violetaProfundo
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _fechaSeleccionada != null
                        ? _formatearFecha(_fechaSeleccionada!)
                        : 'Selecciona una fecha',
                    style: TextStyle(
                      fontSize: 16,
                      color: _fechaSeleccionada != null
                          ? violetaProfundo
                          : Colors.grey,
                      fontWeight: _fechaSeleccionada != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Botón confirmar
          ElevatedButton.icon(
            onPressed: (_fechaSeleccionada == null || _isLoading)
                ? null
                : _agendarCita,
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
            label: Text(_isLoading ? 'Agendando...' : 'Confirmar Cita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: violetaProfundo,
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
    );
  }
}
