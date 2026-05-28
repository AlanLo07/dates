// lib/screens/input.dart
import 'package:flutter/material.dart';
import '../models/cita.dart';
import 'result.dart';
import 'dart:math';
import '../utils/animations.dart';
import '../utils/colors.dart';
import '../services/cita_service.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  bool _isLoading = false;
  String? _selectedCategory;
  String? _selectedBudget;
  double _selectedTimeHours = 2.0;
  final double maxTotalTime = 200.0;

  final List<String> categories = [
    'Romántico',
    'Aventura',
    'Relajante',
    'Compras',
    'Comida',
    'Cualquiera',
  ];
  final List<String> budgets = ['Bajo', 'Medio', 'Alto', 'Cualquiera'];

  // Emoji por categoría
  static const Map<String, String> _categoryEmoji = {
    'Romántico': '💑',
    'Aventura': '🌄',
    'Relajante': '🛋️',
    'Compras': '🛍️',
    'Comida': '🍽️',
    'Cualquiera': '✨',
  };

  static const Map<String, String> _budgetEmoji = {
    'Bajo': '🪙',
    'Medio': '💳',
    'Alto': '💎',
    'Cualquiera': '🎲',
  };

  Future<void> _obtenerYGenerarCita() async {
    setState(() => _isLoading = true);
    try {
      List<Cita> citasActualizadas = await ApiService().getCitas();
      List<Cita> citasFiltradas = citasActualizadas.where((cita) {
        bool cumpleCategoria =
            (_selectedCategory == 'Cualquiera' || _selectedCategory == null) ||
            cita.categoria == _selectedCategory;
        bool cumplePresupuesto =
            (_selectedBudget == 'Cualquiera' || _selectedBudget == null) ||
            cita.presupuesto == _selectedBudget;
        bool cumpleTiempo = cita.tiempo <= _selectedTimeHours;
        return cumpleCategoria && cumplePresupuesto && cumpleTiempo;
      }).toList();

      if (citasFiltradas.isNotEmpty) {
        final random = Random();
        Cita citaElegida =
            citasFiltradas[random.nextInt(citasFiltradas.length)];
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(createRoute(ResultScreen(cita: citaElegida)));
      } else {
        _mostrarSnackBar('No encontramos planes con esos filtros. 🤔');
      }
    } catch (e) {
      _mostrarSnackBar('Error al conectar con la API: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.violeta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          '💘 Generador de Citas',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Header card ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
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
                      const Text(
                        '¿Qué tipo de plan buscan hoy?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.violeta,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajusta los filtros y la suerte hará el resto 🎲',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Categorías ─────────────────────────────────────────────
                _buildSectionLabel('Tipo de Cita'),
                const SizedBox(height: 10),
                _buildChipSelector(
                  options: categories,
                  selected: _selectedCategory,
                  emojiMap: _categoryEmoji,
                  onSelected: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 20),

                // ── Presupuesto ────────────────────────────────────────────
                _buildSectionLabel('Presupuesto'),
                const SizedBox(height: 10),
                _buildChipSelector(
                  options: budgets,
                  selected: _selectedBudget,
                  emojiMap: _budgetEmoji,
                  onSelected: (v) => setState(() => _selectedBudget = v),
                ),
                const SizedBox(height: 20),

                // ── Tiempo ─────────────────────────────────────────────────
                _buildSectionLabel('Tiempo disponible'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violeta.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Máximo',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violeta.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_selectedTimeHours.round()} horas',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.violeta,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.violeta,
                          inactiveTrackColor: AppColors.violeta.withOpacity(
                            0.15,
                          ),
                          thumbColor: AppColors.violeta,
                          overlayColor: AppColors.violeta.withOpacity(0.1),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _selectedTimeHours,
                          min: 1,
                          max: maxTotalTime,
                          divisions: (maxTotalTime - 1).toInt(),
                          onChanged: (v) =>
                              setState(() => _selectedTimeHours = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1h',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            '200h',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Botón generar ──────────────────────────────────────────
                _GenerateButton(
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _obtenerYGenerarCita,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.violeta),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.violeta,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> options,
    required String? selected,
    required Map<String, String> emojiMap,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.violeta : AppColors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isSelected ? AppColors.violeta : Colors.grey.shade200,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.violeta.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emojiMap[option] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Botón animado de generar ──────────────────────────────────────────────────
class _GenerateButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GenerateButton({required this.isLoading, required this.onPressed});

  @override
  State<_GenerateButton> createState() => _GenerateButtonState();
}

class _GenerateButtonState extends State<_GenerateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF9C8DC4), AppColors.violeta],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.isLoading ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isLoading
                ? []
                : [
                    BoxShadow(
                      color: AppColors.violeta.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        '¡GENERAR CITA!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
