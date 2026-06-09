// lib/screens/plans/checklist.dart
import 'package:flutter/material.dart';
import '../../services/cita_service.dart';
import '../../models/cita.dart';
import 'result.dart';
import '../../utils/animations.dart';
import '../../utils/colors.dart';
import 'adventure_map.dart';

class AdventureListScreen extends StatefulWidget {
  final Cita cita;
  final List<Cita> citas;
  const AdventureListScreen({
    required this.cita,
    required this.citas,
    super.key,
  });

  @override
  State<AdventureListScreen> createState() => _AdventureListScreenState();
}

class _AdventureListScreenState extends State<AdventureListScreen> {
  late Cita citaSelected;
  late List<Cita> listaLugares;

  @override
  void initState() {
    super.initState();
    citaSelected = widget.cita;
    listaLugares = widget.citas;
  }

  // ── Helpers de progreso ───────────────────────────────────────────────────
  List<Cita> get _lugares => listaLugares
      .where((l) => l.typeLocation == citaSelected.typeLocation)
      .toList();

  int get _visitados => _lugares.where((l) => l.isVisited).length;
  int get _total => _lugares.length;
  double get _progreso => _total == 0 ? 0.0 : _visitados / _total;

  // ── Rating stars ──────────────────────────────────────────────────────────
  Widget _buildRatingStars(Cita lugar) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() => lugar.rating = index + 1.0);
            saveLugares(lugar);
          },
          child: Icon(
            index < lugar.rating
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            color: const Color(0xFFFFCA28),
            size: 26,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lugares = _lugares;
    final visitados = _visitados;
    final total = _total;
    final progreso = _progreso;

    // Emoji y mensaje dinámico según progreso
    final String progresoEmoji;
    final String progresoMensaje;
    if (visitados == 0) {
      progresoEmoji = '🗺️';
      progresoMensaje = '¡La aventura está por comenzar!';
    } else if (progreso < 0.5) {
      progresoEmoji = '🚶';
      progresoMensaje = '¡Van bien! Sigan explorando';
    } else if (progreso < 1.0) {
      progresoEmoji = '🏃';
      progresoMensaje = '¡Casi lo logran!';
    } else {
      progresoEmoji = '🏆';
      progresoMensaje = '¡Completaron todos los lugares!';
    }

    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Nuestras Aventuras',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'map_btn',
        onPressed: () => Navigator.of(context).push(
          createRoute(
            AdventureMapScreen(
              lugares: lugares,
              titulo: citaSelected.typeLocation,
            ),
          ),
        ),
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.map_rounded),
        label: Text('Mapa ($visitados)'),
      ),
      body: Column(
        children: [
          // ── Barra de progreso ─────────────────────────────────────────────
          _ProgressHeader(
            visitados: visitados,
            total: total,
            progreso: progreso,
            emoji: progresoEmoji,
            mensaje: progresoMensaje,
          ),

          // ── Lista de lugares ──────────────────────────────────────────────
          Expanded(
            child: total == 0
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: lugares.length,
                    itemBuilder: (context, index) {
                      final lugar = lugares[index];
                      return _LugarCard(
                        lugar: lugar,
                        onVisitadoChanged: (value) {
                          setState(() => lugar.isVisited = value);
                          saveLugares(lugar);
                        },
                        onRatingChanged: (value) {
                          setState(() => lugar.rating = value);
                          saveLugares(lugar);
                        },
                        onTap: () => Navigator.of(
                          context,
                        ).push(createRoute(ResultScreen(cita: lugar))),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'No hay lugares en esta categoría',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega lugares desde la pantalla anterior',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> saveLugares(lugar) async {
    List<Cita> lista = [lugar];
    try {
      await ApiService().syncLugares(lista);
    } catch (e) {
      debugPrint('No se pudo guardar en la nube: $e');
    }
  }
}

// ── Header con barra de progreso ──────────────────────────────────────────────
class _ProgressHeader extends StatelessWidget {
  final int visitados;
  final int total;
  final double progreso;
  final String emoji;
  final String mensaje;

  const _ProgressHeader({
    required this.visitados,
    required this.total,
    required this.progreso,
    required this.emoji,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    final bool completado = visitados == total && total > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.violeta.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Fila superior: emoji + mensaje + contador ──────────────────
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mensaje,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: completado
                        ? const Color(0xFF2E7D32)
                        : AppColors.violeta,
                  ),
                ),
              ),
              // Contador numérico
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: completado
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : AppColors.violeta.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$visitados / $total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: completado
                        ? const Color(0xFF2E7D32)
                        : AppColors.violeta,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Barra de progreso animada ──────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progreso),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.lavanda,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completado ? const Color(0xFF4CAF50) : AppColors.violeta,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Mini stats: visitados vs pendientes ────────────────────────
          Row(
            children: [
              _buildStat(
                icon: Icons.check_circle_rounded,
                color: completado ? const Color(0xFF4CAF50) : AppColors.celeste,
                label: '$visitados visitados',
              ),
              const SizedBox(width: 16),
              _buildStat(
                icon: Icons.radio_button_unchecked_rounded,
                color: Colors.grey.shade400,
                label: '${total - visitados} pendientes',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Card individual de lugar ───────────────────────────────────────────────────
class _LugarCard extends StatelessWidget {
  final Cita lugar;
  final ValueChanged<bool> onVisitadoChanged;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onTap;

  const _LugarCard({
    required this.lugar,
    required this.onVisitadoChanged,
    required this.onRatingChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lugar.isVisited
              ? AppColors.celeste.withOpacity(0.6)
              : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: lugar.isVisited
                ? AppColors.celeste.withOpacity(0.15)
                : AppColors.violeta.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
            leading: GestureDetector(
              onTap: () => onVisitadoChanged(!lugar.isVisited),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lugar.isVisited
                      ? AppColors.celeste.withOpacity(0.2)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lugar.isVisited
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: lugar.isVisited
                      ? AppColors.celeste
                      : Colors.grey.shade400,
                  size: 26,
                ),
              ),
            ),
            title: Text(
              lugar.nombre,
              style: TextStyle(
                decoration: lugar.isVisited ? TextDecoration.lineThrough : null,
                decorationColor: Colors.grey,
                color: lugar.isVisited
                    ? Colors.grey.shade400
                    : AppColors.violeta,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                lugar.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey.shade400,
            ),
            onTap: onTap,
          ),

          // ── Rating (solo visible si fue visitado) ──────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildRatingRow(),
            crossFadeState: lugar.isVisited
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '¿Qué tan increíble fue?',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    index < lugar.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: index < lugar.rating
                        ? const Color(0xFFFFCA28)
                        : Colors.grey.shade300,
                    size: 26,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
