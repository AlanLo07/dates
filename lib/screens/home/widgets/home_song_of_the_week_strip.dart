import 'package:flutter/material.dart';

import '../../../models/phrase.dart';

class WeeklyHighlightItem {
  final PhraseType type;
  final String title;
  final String subtitle;
  final String url;
  final bool canEdit;

  const WeeklyHighlightItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.url = '',
    this.canEdit = false,
  });
}

class HomeWeeklyHighlightsStrip extends StatefulWidget {
  final bool isLoading;
  final List<WeeklyHighlightItem> items;
  final void Function(WeeklyHighlightItem item) onTapItem;
  final VoidCallback onSongEdit;

  const HomeWeeklyHighlightsStrip({
    super.key,
    required this.isLoading,
    required this.items,
    required this.onTapItem,
    required this.onSongEdit,
  });

  @override
  State<HomeWeeklyHighlightsStrip> createState() =>
      _HomeWeeklyHighlightsStripState();
}

class _HomeWeeklyHighlightsStripState extends State<HomeWeeklyHighlightsStrip> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasItems = widget.items.isNotEmpty;
    final current = hasItems ? widget.items[_currentIndex] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: _gradientForType(current?.type ?? PhraseType.cancion),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _accentForType(current?.type ?? PhraseType.cancion)
                .withOpacity(0.30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: 92,
          child: widget.isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('⏳', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: _WeeklySkeleton()),
                    ],
                  ),
                )
              : !hasItems
              ? const Center(
                  child: Text(
                    'Sin destacados de la semana',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: widget.items.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (_, index) {
                        final item = widget.items[index];
                        return _WeeklyItemView(
                          item: item,
                          onTap: () => widget.onTapItem(item),
                        );
                      },
                    ),
                    Positioned(
                      right: 10,
                      top: 12,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          ...List.generate(widget.items.length, (index) {
                            final isActive = index == _currentIndex;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              width: 6,
                              height: isActive ? 12 : 6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  isActive ? 0.95 : 0.45,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    if (current?.canEdit == true)
                      Positioned(
                        right: 34,
                        top: 10,
                        child: GestureDetector(
                          onTap: widget.onSongEdit,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  LinearGradient _gradientForType(PhraseType type) {
    switch (type) {
      case PhraseType.pelicula:
        return const LinearGradient(
          colors: [Color(0xFFFF8A65), Color(0xFFE64A19)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case PhraseType.cancion:
        return const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF158A3E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case PhraseType.libro:
        return const LinearGradient(
          colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case PhraseType.serie:
        return const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      case PhraseType.pareja:
        return const LinearGradient(
          colors: [Color(0xFFEC407A), Color(0xFFC2185B)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
    }
  }

  Color _accentForType(PhraseType type) {
    switch (type) {
      case PhraseType.pelicula:
        return const Color(0xFFE64A19);
      case PhraseType.cancion:
        return const Color(0xFF1DB954);
      case PhraseType.libro:
        return const Color(0xFF5E35B1);
      case PhraseType.serie:
        return const Color(0xFF1E88E5);
      case PhraseType.pareja:
        return const Color(0xFFC2185B);
    }
  }
}

class _WeeklyItemView extends StatelessWidget {
  final WeeklyHighlightItem item;
  final VoidCallback onTap;

  const _WeeklyItemView({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.url.isEmpty ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(item.type.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _header(item.type),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.72),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.80),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _header(PhraseType type) {
    if (type == PhraseType.pareja) {
      return 'NUESTRA FRASE DE LA SEMANA';
    }
    return '${type.label.toUpperCase()} DE LA SEMANA';
  }
}

class _WeeklySkeleton extends StatelessWidget {
  const _WeeklySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 90,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}