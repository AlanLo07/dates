// lib/screens/input.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/cita.dart';
import 'result.dart';
import '../../utils/animations.dart';
import '../../utils/cita_search.dart';
import '../../utils/colors.dart';
import '../../services/cita_service.dart';

// ── Colores de la ruleta (paleta base + extras) ────────────────────────────
const List<Color> _ruletaColors = [
  Color(0xFF796B9B), // violeta
  Color(0xFFB0B6E8), // malva
  Color(0xFFA9D1DF), // celeste
  Color(0xFFD8C9E7), // lavanda
  Color(0xFFE57373), // coral
  Color(0xFF81C784), // verde pastel
  Color(0xFFFFB74D), // naranja pastel
  Color(0xFFF06292), // rosa fuerte
  Color(0xFF4FC3F7), // azul claro
  Color(0xFFAED581), // lima
];

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  bool _isLoading = false;
  bool _isRouletteMode = false;
  final TextEditingController _rouletteSearchController =
      TextEditingController();

  // Filtros
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

  // ── Ruleta ────────────────────────────────────────────────────────────────
  List<Cita> _allCitas = []; // citas cargadas de la API
  List<Cita> _filteredCitas = []; // citas filtradas para mostrar
  List<Cita> _ruletaItems = []; // items seleccionados para la ruleta
  String _rouletteSearchQuery = '';
    String? _selectedTypeLocation;

    CitaQuickFilters get _rouletteQuickFilters => CitaQuickFilters(
      categoria:
        _selectedCategory == null || _selectedCategory == 'Cualquiera'
          ? null
          : _selectedCategory,
      presupuesto:
        _selectedBudget == null || _selectedBudget == 'Cualquiera'
          ? null
          : _selectedBudget,
      typeLocation: _selectedTypeLocation,
      );

  @override
  void dispose() {
    _rouletteSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCitasParaRuleta() async {
    if (_allCitas.isNotEmpty) {
      _applyFiltersToRuleta();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final citas = await ApiService().getCitas();
      setState(() {
        _allCitas = citas;
        _isLoading = false;
      });
      _applyFiltersToRuleta();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Error al cargar citas: $e');
    }
  }

  void _applyFiltersToRuleta() {
    final filtered = _allCitas.where((cita) {
      bool cumpleTiempo = cita.tiempo <= _selectedTimeHours;
      bool cumpleBusqueda = matchesCitaFilters(
        cita,
        query: _rouletteSearchQuery,
        filters: _rouletteQuickFilters,
      );
      return cumpleTiempo && cumpleBusqueda;
    });

    setState(
      () => _filteredCitas = sortCitasBySearchRelevance(
        filtered,
        _rouletteSearchQuery,
      ),
    );
  }

  void _addToRuleta(Cita cita) {
    if (_ruletaItems.length >= 10) {
      _mostrarSnackBar('Máximo 10 citas en la ruleta 🎡');
      return;
    }
    if (_ruletaItems.any((c) => c.nombre == cita.nombre)) {
      _mostrarSnackBar('Ya está en la ruleta');
      return;
    }
    setState(() => _ruletaItems.add(cita));
  }

  void _removeFromRuleta(Cita cita) {
    setState(() => _ruletaItems.removeWhere((c) => c.nombre == cita.nombre));
  }

  void _openRuleta() {
    if (_ruletaItems.length < 2) {
      _mostrarSnackBar('Agrega al menos 2 citas a la ruleta 🎡');
      return;
    }
    Navigator.of(
      context,
    ).push(createRoute(_RouletteScreen(items: _ruletaItems)));
  }

  // ── Filtros normales ──────────────────────────────────────────────────────
  Future<void> _obtenerYGenerarCita() async {
    setState(() => _isLoading = true);
    try {
      final citasActualizadas = await ApiService().getCitas();
      final citasFiltradas = citasActualizadas.where((cita) {
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
        final citaElegida =
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: Text(
          _isRouletteMode ? '🎡 Modo Ruleta' : '💘 Generador de Citas',
          style: const TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
        actions: [
          // Toggle ruleta
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isRouletteMode = !_isRouletteMode;
                  if (_isRouletteMode) _loadCitasParaRuleta();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isRouletteMode
                      ? AppColors.violeta
                      : AppColors.violeta.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.violeta, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎡', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      'Ruleta',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _isRouletteMode
                            ? Colors.white
                            : AppColors.violeta,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isRouletteMode ? _buildRouletteMode() : _buildNormalMode(),
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

  // ── MODO NORMAL ───────────────────────────────────────────────────────────
  Widget _buildNormalMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
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
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Tipo de Cita'),
          const SizedBox(height: 10),
          _buildChipSelector(
            options: categories,
            selected: _selectedCategory,
            emojiMap: _categoryEmoji,
            onSelected: (v) => setState(() => _selectedCategory = v),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Presupuesto'),
          const SizedBox(height: 10),
          _buildChipSelector(
            options: budgets,
            selected: _selectedBudget,
            emojiMap: _budgetEmoji,
            onSelected: (v) => setState(() => _selectedBudget = v),
          ),
          const SizedBox(height: 20),
          _buildSectionLabel('Tiempo disponible'),
          const SizedBox(height: 10),
          _buildTimeSlider(),
          const SizedBox(height: 32),
          _GenerateButton(
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _obtenerYGenerarCita,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── MODO RULETA ───────────────────────────────────────────────────────────
  Widget _buildRouletteMode() {
    return Column(
      children: [
        // Filtros + botón girar
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),

                // Header con contador
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violeta.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('🎡', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Modo Ruleta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.violeta,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Agrega de 2 a 10 citas y gira la ruleta',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.violeta,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_ruletaItems.length}/10',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filtros
                _buildSectionLabel('Filtrar por tipo'),
                const SizedBox(height: 8),
                _buildChipSelector(
                  options: categories,
                  selected: _selectedCategory,
                  emojiMap: _categoryEmoji,
                  onSelected: (v) {
                    setState(() => _selectedCategory = v);
                    _applyFiltersToRuleta();
                  },
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Presupuesto'),
                const SizedBox(height: 8),
                _buildChipSelector(
                  options: budgets,
                  selected: _selectedBudget,
                  emojiMap: _budgetEmoji,
                  onSelected: (v) {
                    setState(() => _selectedBudget = v);
                    _applyFiltersToRuleta();
                  },
                ),
                const SizedBox(height: 16),
                _buildSectionLabel('Tiempo máximo'),
                const SizedBox(height: 8),
                _buildTimeSlider(onChanged: (_) => _applyFiltersToRuleta()),
                const SizedBox(height: 16),
                CitaSearchField(
                  controller: _rouletteSearchController,
                  hintText: 'Busca por nombre, categoría, presupuesto o lugar',
                  onChanged: (value) {
                    setState(() => _rouletteSearchQuery = value);
                    _applyFiltersToRuleta();
                  },
                ),
                const SizedBox(height: 12),
                CitaQuickFilterChips(
                  citas: _allCitas,
                  filters: _rouletteQuickFilters,
                  query: _rouletteSearchQuery,
                  extraPredicate: (cita) => cita.tiempo <= _selectedTimeHours,
                  onChanged: (filters) {
                    setState(() {
                      _selectedCategory = filters.categoria ?? 'Cualquiera';
                      _selectedBudget = filters.presupuesto ?? 'Cualquiera';
                      _selectedTypeLocation = filters.typeLocation;
                    });
                    _applyFiltersToRuleta();
                  },
                ),
                const SizedBox(height: 20),

                // Items seleccionados para la ruleta
                if (_ruletaItems.isNotEmpty) ...[
                  _buildSectionLabel('Tu ruleta'),
                  const SizedBox(height: 8),
                  ..._ruletaItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final cita = entry.value;
                    return _RuletaSelectedItem(
                      cita: cita,
                      color: _ruletaColors[idx % _ruletaColors.length],
                      onRemove: () => _removeFromRuleta(cita),
                    );
                  }),
                  const SizedBox(height: 16),
                  // Botón girar
                  _SpinButton(
                    enabled: _ruletaItems.length >= 2,
                    onPressed: _openRuleta,
                  ),
                  const SizedBox(height: 20),
                ],

                // Lista de citas disponibles
                _buildSectionLabel(
                  _filteredCitas.isEmpty
                      ? 'Sin resultados con esos filtros'
                      : 'Citas disponibles (${_filteredCitas.length})',
                ),
                const SizedBox(height: 8),

                CitaResultsSwitcher(
                  transitionKey: [
                    _rouletteSearchQuery,
                    _selectedCategory ?? '',
                    _selectedBudget ?? '',
                    _selectedTypeLocation ?? '',
                    _selectedTimeHours.round(),
                    ..._filteredCitas.map((cita) => cita.nombre),
                  ].join('|'),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: AppColors.violeta,
                            ),
                          ),
                        )
                      : _filteredCitas.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Cambia los filtros para ver citas 🔍',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            )
                          : Column(
                              children: _filteredCitas.map((cita) {
                                final inRuleta = _ruletaItems.any(
                                  (c) => c.nombre == cita.nombre,
                                );
                                return _CitaSelectableCard(
                                  cita: cita,
                                  searchQuery: _rouletteSearchQuery,
                                  isSelected: inRuleta,
                                  ruletaFull: _ruletaItems.length >= 10,
                                  onTap: () => inRuleta
                                      ? _removeFromRuleta(cita)
                                      : _addToRuleta(cita),
                                );
                              }).toList(),
                            ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // FAB fijo abajo si hay items
        if (_ruletaItems.length >= 2)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: AppColors.lavanda,
            child: _SpinButton(enabled: true, onPressed: _openRuleta),
          ),
      ],
    );
  }

  // ── Helpers UI compartidos ─────────────────────────────────────────────────
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

  Widget _buildTimeSlider({ValueChanged<double>? onChanged}) {
    return Container(
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
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
              inactiveTrackColor: AppColors.violeta.withOpacity(0.15),
              thumbColor: AppColors.violeta,
              overlayColor: AppColors.violeta.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _selectedTimeHours,
              min: 1,
              max: maxTotalTime,
              divisions: (maxTotalTime - 1).toInt(),
              onChanged: (v) {
                setState(() => _selectedTimeHours = v);
                onChanged?.call(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1h',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
              Text(
                '200h',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Item seleccionado en la ruleta ─────────────────────────────────────────
class _RuletaSelectedItem extends StatelessWidget {
  final Cita cita;
  final Color color;
  final VoidCallback onRemove;

  const _RuletaSelectedItem({
    required this.cita,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cita.nombre,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.remove_circle_outline, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Card seleccionable de cita ─────────────────────────────────────────────
class _CitaSelectableCard extends StatelessWidget {
  final Cita cita;
  final String searchQuery;
  final bool isSelected;
  final bool ruletaFull;
  final VoidCallback onTap;

  const _CitaSelectableCard({
    required this.cita,
    required this.searchQuery,
    required this.isSelected,
    required this.ruletaFull,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = ruletaFull && !isSelected;
    final summary = citaSearchSummary(cita);
    final showDescription = shouldShowCitaDescription(cita, searchQuery);
    final descriptionPrimaryMatch =
        isDescriptionPrimaryMatch(cita, searchQuery);
    final titleStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: disabled ? Colors.grey.shade400 : AppColors.violeta,
      fontSize: 13,
    );
    final descriptionStyle = TextStyle(
      fontSize: 11,
      color: Colors.grey.shade500,
    );

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violeta.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.violeta : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.violeta : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.add,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CitaHighlightedText(
                    cita.nombre,
                    query: searchQuery,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                    highlightStyle: titleStyle.copyWith(
                      fontWeight: FontWeight.w800,
                      backgroundColor: AppColors.malva.withOpacity(0.32),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CitaHighlightedText(
                          summary.isEmpty
                              ? '${cita.presupuesto} · ${cita.tiempo}h'
                              : summary,
                          query: searchQuery,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (descriptionPrimaryMatch) ...[
                    const SizedBox(height: 4),
                    const CitaDescriptionMatchBadge(),
                  ],
                  if (showDescription) ...[
                    const SizedBox(height: 4),
                    CitaHighlightedText(
                      cita.descripcion,
                      query: searchQuery,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: descriptionStyle,
                      highlightStyle: descriptionStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        backgroundColor: AppColors.celeste.withOpacity(0.38),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón Girar ───────────────────────────────────────────────────────────
class _SpinButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _SpinButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF9C8DC4), AppColors.violeta],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: enabled ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.violeta.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎡', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                '¡GIRAR LA RULETA!',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón animado de generar (modo normal) ────────────────────────────────
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
        scale: _ctrl,
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

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA DE LA RULETA
// ─────────────────────────────────────────────────────────────────────────────
class _RouletteScreen extends StatefulWidget {
  final List<Cita> items;
  const _RouletteScreen({required this.items});

  @override
  State<_RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<_RouletteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  int? _winnerIndex;
  bool _isSpinning = false;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
    _spinAnimation.addListener(() {
      setState(() {
        _currentAngle = _spinAnimation.value * _targetAngle;
      });
    });
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpinning = false;
          _showResult = true;
        });
        HapticFeedback.heavyImpact();
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _winnerIndex = null;
    });

    final random = Random();
    final n = widget.items.length;

    // Elegir ganador aleatorio
    final winner = random.nextInt(n);
    final sliceAngle = (2 * pi) / n;

    // Angulo base del ganador + offset para centrar en el puntero (arriba = -pi/2)
    // El puntero apunta arriba. Cada slice i ocupa [i*slice, (i+1)*slice].
    // Para que el centro del slice ganador quede en la parte de arriba:
    // targetAngle = vueltas extras + ángulo para alinear
    final extraSpins = (5 + random.nextInt(3)) * 2 * pi;
    final winnerCenter = winner * sliceAngle + sliceAngle / 2 - pi / 2;
    // Necesitamos que (currentAngle + targetDelta) mod 2π == (3π/2 - winnerCenter) mod 2π
    // Simplificado: traemos el sector ganador al top
    final alignAngle = (3 * pi / 2 - winnerCenter) % (2 * pi);
    _targetAngle =
        _currentAngle + extraSpins + alignAngle - (_currentAngle % (2 * pi));

    _spinController.reset();
    _spinController.forward();

    Future.delayed(const Duration(milliseconds: 3800), () {
      if (mounted) setState(() => _winnerIndex = winner);
    });
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    final sliceAngle = (2 * pi) / n;

    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          '🎡 Ruleta',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // Nombres en la ruleta (chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: widget.items.asMap().entries.map((e) {
                final color = _ruletaColors[e.key % _ruletaColors.length];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Text(
                    e.value.nombre,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Ruleta
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Puntero arriba
                  _buildPointer(),
                  const SizedBox(height: 4),
                  // Rueda
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: Transform.rotate(
                      angle: _currentAngle,
                      child: CustomPaint(
                        painter: _RoulettePainter(
                          items: widget.items,
                          colors: _ruletaColors,
                          sliceAngle: sliceAngle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Resultado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _showResult && _winnerIndex != null
                ? _buildResultCard(widget.items[_winnerIndex!])
                : const SizedBox(height: 20),
          ),

          // Botón girar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: GestureDetector(
              onTap: _isSpinning ? null : _spin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 58,
                decoration: BoxDecoration(
                  gradient: _isSpinning
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF9C8DC4), AppColors.violeta],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  color: _isSpinning ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isSpinning
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
                  child: _isSpinning
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.violeta,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Girando...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🎡', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Text(
                              '¡GIRAR!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointer() {
    return CustomPaint(size: const Size(24, 20), painter: _PointerPainter());
  }

  Widget _buildResultCard(Cita cita) {
    return Container(
      key: ValueKey(cita.nombre),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.violeta.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            '¡La ruleta eligió!',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            cita.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(createRoute(ResultScreen(cita: cita)));
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Ver plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CustomPainter: Ruleta ─────────────────────────────────────────────────
class _RoulettePainter extends CustomPainter {
  final List<Cita> items;
  final List<Color> colors;
  final double sliceAngle;

  _RoulettePainter({
    required this.items,
    required this.colors,
    required this.sliceAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    for (int i = 0; i < items.length; i++) {
      final startAngle = i * sliceAngle - pi / 2;
      final color = colors[i % colors.length];

      // Slice
      paint.color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        paint,
      );

      // Borde blanco entre slices
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sliceAngle,
        true,
        borderPaint,
      );

      // Texto del nombre
      final textAngle = startAngle + sliceAngle / 2;
      final textRadius = radius * 0.6;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);

      final nombre = items[i].nombre.length > 12
          ? '${items[i].nombre.substring(0, 12)}…'
          : items[i].nombre;

      final textPainter = TextPainter(
        text: TextSpan(
          text: nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 70);

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // Círculo central
    paint.color = Colors.white;
    canvas.drawCircle(center, 18, paint);
    paint.color = AppColors.violeta;
    canvas.drawCircle(center, 14, paint);

    // Texto "🎡" en el centro (usando texto)
    final centerPainter = TextPainter(
      text: const TextSpan(
        text: '●',
        style: TextStyle(color: Colors.white, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    centerPainter.paint(
      canvas,
      Offset(
        center.dx - centerPainter.width / 2,
        center.dy - centerPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_RoulettePainter old) => false;
}

// ── CustomPainter: Puntero ─────────────────────────────────────────────────
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.violeta
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
    // borde blanco
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}
