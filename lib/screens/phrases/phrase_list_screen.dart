import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/phrase.dart';
import '../../services/phrases_service.dart';
import '../../utils/animations.dart';
import '../../utils/colors.dart';
import '../../widgets/motion/ambient_orbs_background.dart';
import '../../widgets/motion/motion_pressable.dart';
import 'phrases.dart';

/// Lista de frases de un tipo: las completadas se muestran, las pendientes
/// aparecen bloqueadas hasta adivinarlas en el ahorcado.
class PhraseListScreen extends StatefulWidget {
  final PhraseType type;
  final Color accentColor;

  const PhraseListScreen({
    required this.type,
    this.accentColor = AppColors.violeta,
    super.key,
  });

  @override
  State<PhraseListScreen> createState() => _PhraseListScreenState();
}

class _PhraseListScreenState extends State<PhraseListScreen> {
  static const Duration _kFade = Duration(milliseconds: 320);
  static const Duration _kSlide = Duration(milliseconds: 380);
  static const Duration _kStagger = Duration(milliseconds: 55);

  List<LovePhrase> _items = const [];
  bool _isLoading = true;
  String? _error;

  int get _completedCount => _items.where((p) => p.completado).length;
  bool get _hasPending => _items.any((p) => !p.completado);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final all = await PhrasesService().getPhrases(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _items = all.where((p) => p.type == widget.type).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No pudimos cargar las frases. Intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openGame({LovePhrase? phrase}) async {
    await Navigator.push(
      context,
      createRoute(
        PhrasesScreen(type: widget.type, initialPhrase: phrase),
        motion: AppRouteMotion.sharedAxisX,
      ),
    );
    if (!mounted) return;
    await _loadData();
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('🔒 Adivínala en el juego para desbloquearla'),
          backgroundColor: widget.accentColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: Text(
          '${widget.type.emoji} ${widget.type.label}',
          style: const TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.violeta),
            onPressed: () => _loadData(forceRefresh: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.violeta,
        ),
      );
    }

    if (_error != null) {
      return _PhraseListError(message: _error!, onRetry: _loadData);
    }

    return AmbientOrbsBackground(
      colors: [
        widget.accentColor.withValues(alpha: 0.55),
        AppColors.lavanda,
        AppColors.malva,
      ],
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no hay frases de este tipo',
                      style: TextStyle(color: AppColors.violeta),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final phrase = _items[index];
                      return _PhraseTile(
                        phrase: phrase,
                        index: index,
                        accentColor: widget.accentColor,
                        onTap: phrase.completado
                            ? () => _openGame(phrase: phrase)
                            : _showLockedMessage,
                      )
                          .animate()
                          .fadeIn(delay: _kStagger * index, duration: _kFade)
                          .slideY(
                            begin: 0.08,
                            delay: _kStagger * index,
                            duration: _kSlide,
                          );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final total = _items.length;
    final progress = total == 0 ? 0.0 : _completedCount / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasPending ? () => _openGame() : null,
              icon: const Icon(Icons.videogame_asset_rounded),
              label: Text(
                _hasPending ? 'Jugar frase nueva' : 'Todas desbloqueadas 🎉',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$_completedCount de $total desbloqueadas',
            style: const TextStyle(
              color: AppColors.violeta,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhraseTile extends StatelessWidget {
  final LovePhrase phrase;
  final int index;
  final Color accentColor;
  final VoidCallback onTap;

  const _PhraseTile({
    required this.phrase,
    required this.index,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = phrase.completado;

    return MotionPressable(
      onTap: onTap,
      pressedScale: 0.98,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.surface
              : AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked
                ? accentColor.withValues(alpha: 0.45)
                : Colors.grey.shade300,
            width: 1.4,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: unlocked
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: unlocked
                  ? Text(
                      phrase.emoji,
                      style: const TextStyle(fontSize: 22),
                    )
                  : Icon(
                      Icons.lock_rounded,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unlocked
                        ? (phrase.title.isNotEmpty ? phrase.title : phrase.text)
                        : 'Frase #${index + 1} bloqueada',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: unlocked
                          ? AppColors.violeta
                          : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked ? '“${phrase.text}”' : '••••• ••• ••••••',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: unlocked
                          ? Colors.grey.shade700
                          : Colors.grey.shade400,
                      fontStyle: unlocked ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              unlocked ? Icons.play_circle_fill_rounded : Icons.lock_outline,
              color: unlocked ? accentColor : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhraseListError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PhraseListError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.violeta),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
