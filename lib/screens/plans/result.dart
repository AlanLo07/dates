// lib/screens/result.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cita.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../../services/cita_service.dart';
import '../../utils/colors.dart';

// ── Título con fade-in ────────────────────────────────────────────────────────
class FadingTitle extends StatefulWidget {
  final String title;
  const FadingTitle({required this.title, super.key});

  @override
  State<FadingTitle> createState() => _FadingTitleState();
}

class _FadingTitleState extends State<FadingTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(
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
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.violeta,
        ),
      ),
    );
  }
}

// ── Pantalla principal ────────────────────────────────────────────────────────
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
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.lavanda,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          size: 80,
          color: AppColors.violeta,
        ),
      );
    }
    if (cita.imagenUrl.endsWith('.json')) {
      return Lottie.network(
        cita.imagenUrl,
        width: 220,
        height: 220,
        repeat: true,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CachedNetworkImage(
        imageUrl: cita.imagenUrl,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.violeta),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: AppColors.violeta,
        ),
      ),
    );
  }

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
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          '🎉 ¡Su Plan!',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Media ────────────────────────────────────────────────────
            Center(child: _buildMediaWidget()),
            const SizedBox(height: 24),

            // ── Nombre ───────────────────────────────────────────────────
            FadingTitle(title: cita.nombre),
            const SizedBox(height: 12),

            // ── Descripción ──────────────────────────────────────────────
            Text(
              cita.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Info chips ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInfoChip(Icons.attach_money_rounded, cita.presupuesto),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.access_time_rounded, '${cita.tiempo}h'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.category_rounded, cita.categoria),
              ],
            ),
            const SizedBox(height: 24),

            // ── Rating ───────────────────────────────────────────────────
            if (cita.rating > 0) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violeta.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(5, (i) {
                        return Icon(
                          i < cita.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: i < cita.rating
                              ? const Color(0xFFFFCA28)
                              : Colors.grey.shade300,
                          size: 26,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Botón Agendar ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: () => _mostrarAgendarCita(context),
              icon: const Icon(Icons.backpack_outlined),
              label: const Text('Agendar esta Cita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),

            // ── Botón Link ────────────────────────────────────────────────
            if (cita.link.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _launchUrl(cita.link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ver Detalles / Mapa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.violeta,
                  side: const BorderSide(color: AppColors.violeta, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.violeta.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.violeta),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.violeta,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet: agendar ─────────────────────────────────────────────────────
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
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

  String _formatearFecha(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d-$m-${date.year}';
  }

  Future<void> _agendarCita() async {
    if (_fechaSeleccionada == null) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().agendarCita(
        cita: widget.cita,
        fecha: _formatearFecha(_fechaSeleccionada!),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Cita agendada para el ${_formatearFecha(_fechaSeleccionada!)}!',
            ),
            backgroundColor: AppColors.violeta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agendar: $e'),
            backgroundColor: AppColors.error,
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
          Row(
            children: [
              const Icon(
                Icons.backpack_outlined,
                color: AppColors.violeta,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agendar: ${widget.cita.nombre}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.cita.descripcion,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _fechaSeleccionada != null
                      ? AppColors.violeta
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
                    Icons.calendar_today_rounded,
                    color: _fechaSeleccionada != null
                        ? AppColors.violeta
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
                          ? AppColors.violeta
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
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_isLoading ? 'Agendando...' : 'Confirmar Cita'),
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
    );
  }
}
