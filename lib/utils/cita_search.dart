import 'package:flutter/material.dart';

import '../models/cita.dart';
import 'colors.dart';

class CitaQuickFilters {
  final String? categoria;
  final String? presupuesto;
  final String? typeLocation;

  const CitaQuickFilters({
    this.categoria,
    this.presupuesto,
    this.typeLocation,
  });

  bool get isEmpty =>
      categoria == null && presupuesto == null && typeLocation == null;

  CitaQuickFilters copyWith({
    String? categoria,
    bool clearCategoria = false,
    String? presupuesto,
    bool clearPresupuesto = false,
    String? typeLocation,
    bool clearTypeLocation = false,
  }) {
    return CitaQuickFilters(
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      presupuesto:
          clearPresupuesto ? null : (presupuesto ?? this.presupuesto),
      typeLocation:
          clearTypeLocation ? null : (typeLocation ?? this.typeLocation),
    );
  }
}

class CitaQuickFilterOptions {
  final List<String> categorias;
  final List<String> presupuestos;
  final List<String> typeLocations;

  const CitaQuickFilterOptions({
    required this.categorias,
    required this.presupuestos,
    required this.typeLocations,
  });
}

CitaQuickFilterOptions buildCitaQuickFilterOptions(List<Cita> citas) {
  List<String> sortedUnique(Iterable<String> values) {
    final unique = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return unique;
  }

  return CitaQuickFilterOptions(
    categorias: sortedUnique(citas.map((cita) => cita.categoria)),
    presupuestos: sortedUnique(citas.map((cita) => cita.presupuesto)),
    typeLocations: sortedUnique(citas.map((cita) => cita.typeLocation)),
  );
}

String normalizeCitaSearchQuery(String query) => query.trim().toLowerCase();

Iterable<String> splitCitaSearchTerms(String query) {
  return normalizeCitaSearchQuery(query)
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty);
}

String buildCitaSearchText(Cita cita) {
  return [
    cita.nombre,
    cita.descripcion,
    cita.categoria,
    cita.presupuesto,
    cita.typeLocation,
    '${cita.tiempo}',
    '${cita.tiempo} horas',
    cita.link,
  ].join(' ').toLowerCase();
}

bool matchesCitaQuery(Cita cita, String query) {
  final normalized = normalizeCitaSearchQuery(query);
  if (normalized.isEmpty) return true;

  final haystack = buildCitaSearchText(cita);
  final terms = splitCitaSearchTerms(normalized);

  return terms.every(haystack.contains);
}

bool textMatchesSearchQuery(String text, String query) {
  final normalized = normalizeCitaSearchQuery(query);
  if (normalized.isEmpty) return false;

  final haystack = text.toLowerCase();
  final terms = splitCitaSearchTerms(normalized);
  return terms.every(haystack.contains);
}

int citaSearchRank(Cita cita, String query) {
  final normalized = normalizeCitaSearchQuery(query);
  if (normalized.isEmpty) return 0;

  final name = cita.nombre.trim().toLowerCase();
  final haystack = buildCitaSearchText(cita);
  final terms = splitCitaSearchTerms(normalized).toList();

  if (name == normalized) return 500;
  if (name.startsWith(normalized)) return 400;
  if (name.contains(normalized)) return 300;
  if (terms.isNotEmpty && terms.every(name.contains)) return 220;
  if (terms.isNotEmpty && terms.any(name.contains)) return 180;
  if (haystack.contains(normalized)) return 100;
  return 0;
}

List<Cita> sortCitasBySearchRelevance(
  Iterable<Cita> citas,
  String query, {
  int Function(Cita a, Cita b)? tieBreaker,
}) {
  final sorted = citas.toList()
    ..sort((a, b) {
      final rankCompare = citaSearchRank(b, query).compareTo(
        citaSearchRank(a, query),
      );
      if (rankCompare != 0) return rankCompare;
      if (tieBreaker != null) {
        final tie = tieBreaker(a, b);
        if (tie != 0) return tie;
      }
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

  return sorted;
}

bool matchesCitaFilters(
  Cita cita, {
  String query = '',
  CitaQuickFilters filters = const CitaQuickFilters(),
}) {
  final matchesQuery = matchesCitaQuery(cita, query);
  final matchesCategoria =
      filters.categoria == null || cita.categoria == filters.categoria;
  final matchesPresupuesto = filters.presupuesto == null ||
      cita.presupuesto == filters.presupuesto;
  final matchesTypeLocation = filters.typeLocation == null ||
      cita.typeLocation == filters.typeLocation;

  return matchesQuery &&
      matchesCategoria &&
      matchesPresupuesto &&
      matchesTypeLocation;
}

String citaSearchSummary(Cita cita) {
  final parts = <String>[
    if (cita.categoria.isNotEmpty) cita.categoria,
    if (cita.presupuesto.isNotEmpty) cita.presupuesto,
    if (cita.typeLocation.isNotEmpty) cita.typeLocation,
    if (cita.tiempo > 0) '${cita.tiempo} h',
  ];

  return parts.join(' • ');
}

bool shouldShowCitaDescription(Cita cita, String query) {
  if (cita.descripcion.trim().isEmpty) return false;
  if (citaSearchSummary(cita).isEmpty) return true;
  return textMatchesSearchQuery(cita.descripcion, query);
}

bool hasTitleMatch(Cita cita, String query) {
  return textMatchesSearchQuery(cita.nombre, query);
}

bool hasDescriptionMatch(Cita cita, String query) {
  return textMatchesSearchQuery(cita.descripcion, query);
}

bool isDescriptionPrimaryMatch(Cita cita, String query) {
  final descriptionMatch = hasDescriptionMatch(cita, query);
  if (!descriptionMatch) return false;
  return !hasTitleMatch(cita, query);
}

class CitaSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const CitaSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, color: AppColors.violeta),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
        filled: true,
        fillColor: const Color(0xFFF7F4FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.violeta, width: 1.5),
        ),
      ),
    );
  }
}

class CitaHighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int? maxLines;
  final TextOverflow overflow;

  const CitaHighlightedText(
    this.text, {
    super.key,
    required this.query,
    this.style,
    this.highlightStyle,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final normalizedTerms = splitCitaSearchTerms(query).toList();

    if (text.isEmpty || normalizedTerms.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final ranges = _collectHighlightRanges(text, normalizedTerms);
    if (ranges.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final effectiveHighlightStyle = highlightStyle ??
        baseStyle.copyWith(
          fontWeight: FontWeight.w800,
          color: baseStyle.color,
          backgroundColor: AppColors.celeste.withOpacity(0.35),
        );

    return Text.rich(
      TextSpan(
        children: _buildHighlightSpans(
          text,
          ranges,
          baseStyle,
          effectiveHighlightStyle,
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class CitaResultsSwitcher extends StatelessWidget {
  final Object transitionKey;
  final Widget child;

  const CitaResultsSwitcher({
    super.key,
    required this.transitionKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(transitionKey), child: child),
    );
  }
}

class CitaDescriptionMatchBadge extends StatelessWidget {
  final String label;

  const CitaDescriptionMatchBadge({
    super.key,
    this.label = 'Match en descripción',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.celeste.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.celeste.withOpacity(0.55)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.violeta,
        ),
      ),
    );
  }
}

class CitaQuickFilterChips extends StatelessWidget {
  final List<Cita> citas;
  final CitaQuickFilters filters;
  final String query;
  final bool Function(Cita cita)? extraPredicate;
  final ValueChanged<CitaQuickFilters> onChanged;

  const CitaQuickFilterChips({
    super.key,
    required this.citas,
    required this.filters,
    this.query = '',
    this.extraPredicate,
    required this.onChanged,
  });

  int _countFor({
    String? categoria,
    String? presupuesto,
    String? typeLocation,
  }) {
    final scopedFilters = CitaQuickFilters(
      categoria: categoria,
      presupuesto: presupuesto,
      typeLocation: typeLocation,
    );

    return citas.where((cita) {
      final matchesExtra = extraPredicate?.call(cita) ?? true;
      return matchesExtra &&
          matchesCitaFilters(cita, query: query, filters: scopedFilters);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final options = buildCitaQuickFilterOptions(citas);
    final hasFilters = options.categorias.length > 1 ||
        options.presupuestos.isNotEmpty ||
        options.typeLocations.length > 1;

    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros rápidos',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        if (options.categorias.length > 1)
          _FilterGroup(
            label: 'Categoría',
            values: options.categorias,
            selectedValue: filters.categoria,
            activeColor: AppColors.violeta,
            allCount: _countFor(
              presupuesto: filters.presupuesto,
              typeLocation: filters.typeLocation,
            ),
            valueCount: (value) => _countFor(
              categoria: value,
              presupuesto: filters.presupuesto,
              typeLocation: filters.typeLocation,
            ),
            onSelected: (value) => onChanged(
              filters.copyWith(
                categoria: value,
                clearCategoria: value == null,
              ),
            ),
          ),
        if (options.presupuestos.isNotEmpty) ...[
          if (options.categorias.length > 1) const SizedBox(height: 10),
          _FilterGroup(
            label: 'Presupuesto',
            values: options.presupuestos,
            selectedValue: filters.presupuesto,
            activeColor: AppColors.celeste,
            allCount: _countFor(
              categoria: filters.categoria,
              typeLocation: filters.typeLocation,
            ),
            valueCount: (value) => _countFor(
              categoria: filters.categoria,
              presupuesto: value,
              typeLocation: filters.typeLocation,
            ),
            onSelected: (value) => onChanged(
              filters.copyWith(
                presupuesto: value,
                clearPresupuesto: value == null,
              ),
            ),
          ),
        ],
        if (options.typeLocations.length > 1) ...[
          if (options.categorias.length > 1 || options.presupuestos.isNotEmpty)
            const SizedBox(height: 10),
          _FilterGroup(
            label: 'Locación',
            values: options.typeLocations,
            selectedValue: filters.typeLocation,
            activeColor: AppColors.malva,
            allCount: _countFor(
              categoria: filters.categoria,
              presupuesto: filters.presupuesto,
            ),
            valueCount: (value) => _countFor(
              categoria: filters.categoria,
              presupuesto: filters.presupuesto,
              typeLocation: value,
            ),
            onSelected: (value) => onChanged(
              filters.copyWith(
                typeLocation: value,
                clearTypeLocation: value == null,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String label;
  final List<String> values;
  final String? selectedValue;
  final Color activeColor;
  final int allCount;
  final int Function(String value) valueCount;
  final ValueChanged<String?> onSelected;

  const _FilterGroup({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.activeColor,
    required this.allCount,
    required this.valueCount,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final visibleValues = values.where(
      (value) => valueCount(value) > 0 || selectedValue == value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChipOption(
              label: 'Todos',
              count: allCount,
              isSelected: selectedValue == null,
              activeColor: activeColor,
              onTap: () => onSelected(null),
            ),
            ...visibleValues.map(
              (value) => _FilterChipOption(
                label: value,
                count: valueCount(value),
                isSelected: selectedValue == value,
                activeColor: activeColor,
                onTap: () => onSelected(selectedValue == value ? null : value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChipOption extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChipOption({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.16) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: count == 0
                ? Colors.grey.shade400
                : isSelected
                    ? activeColor
                    : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

List<({int start, int end})> _collectHighlightRanges(
  String text,
  List<String> terms,
) {
  final lower = text.toLowerCase();
  final ranges = <({int start, int end})>[];

  for (final term in terms) {
    if (term.isEmpty) continue;
    int startIndex = 0;
    while (startIndex < lower.length) {
      final matchIndex = lower.indexOf(term, startIndex);
      if (matchIndex < 0) break;
      ranges.add((start: matchIndex, end: matchIndex + term.length));
      startIndex = matchIndex + term.length;
    }
  }

  if (ranges.isEmpty) return ranges;
  ranges.sort((a, b) => a.start.compareTo(b.start));

  final merged = <({int start, int end})>[];
  var current = ranges.first;
  for (final next in ranges.skip(1)) {
    if (next.start <= current.end) {
      current = (
        start: current.start,
        end: next.end > current.end ? next.end : current.end,
      );
      continue;
    }
    merged.add(current);
    current = next;
  }
  merged.add(current);
  return merged;
}

List<TextSpan> _buildHighlightSpans(
  String text,
  List<({int start, int end})> ranges,
  TextStyle baseStyle,
  TextStyle highlightStyle,
) {
  final spans = <TextSpan>[];
  int currentIndex = 0;

  for (final range in ranges) {
    if (range.start > currentIndex) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex, range.start),
          style: baseStyle,
        ),
      );
    }

    spans.add(
      TextSpan(
        text: text.substring(range.start, range.end),
        style: highlightStyle,
      ),
    );
    currentIndex = range.end;
  }

  if (currentIndex < text.length) {
    spans.add(
      TextSpan(text: text.substring(currentIndex), style: baseStyle),
    );
  }

  return spans;
}