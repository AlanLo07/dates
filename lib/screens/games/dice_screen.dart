// lib/screens/games/dice_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/desire_content.dart';
import '../../utils/colors.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with TickerProviderStateMixin {
  final _random = Random();
  DesireLevel? _filterLevel; // null = todos los niveles

  late DiceEntry _accion;
  late DiceEntry _zona;
  late DiceEntry _modificador;

  final List<bool> _locked = [false, false, false];

  late final AnimationController _rollController;
  int _rollTick = 0; // fuerza el flicker de valores random durante el roll

  @override
  void initState() {
    super.initState();
    _accion = _pick(kAcciones);
    _zona = _pick(kZonas);
    _modificador = _pick(kModificadores);

    _rollController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          setState(() => _rollTick++);
        });
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  List<T> _filtered<T>(List<T> source, DesireLevel Function(T) level) {
    if (_filterLevel == null) return source;
    final f = source.where((e) => level(e) == _filterLevel).toList();
    return f.isEmpty ? source : f;
  }

  DiceEntry _pick(List<DiceEntry> source) {
    final pool = _filtered<DiceEntry>(source, (e) => e.level);
    return pool[_random.nextInt(pool.length)];
  }

  Future<void> _rollDice() async {
    HapticFeedback.mediumImpact();
    _rollController.reset();
    await _rollController.forward();

    setState(() {
      if (!_locked[0]) _accion = _pick(kAcciones);
      if (!_locked[1]) _zona = _pick(kZonas);
      if (!_locked[2]) _modificador = _pick(kModificadores);
    });
    HapticFeedback.heavyImpact();
  }

  DesireLevel get _combinedLevel {
    final levels = [_accion.level, _zona.level, _modificador.level];
    if (levels.contains(DesireLevel.atrevido)) return DesireLevel.atrevido;
    if (levels.contains(DesireLevel.picante)) return DesireLevel.picante;
    return DesireLevel.suave;
  }

  @override
  Widget build(BuildContext context) {
    final level = _combinedLevel;

    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          '🎲 Dado del Deseo',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLevelFilter(),
              const SizedBox(height: 20),

              // ── Carta de resultado ─────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: level.bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: level.color.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: level.color.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(level.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          level.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: level.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.violeta,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: '${_displayAccion()} '),
                          TextSpan(
                            text: '${_displayZona()} ',
                            style: TextStyle(color: level.color),
                          ),
                          TextSpan(text: _displayModificador()),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Los 3 dados ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _DiceTile(
                      emoji: '💋',
                      label: 'Acción',
                      value: _accion.text,
                      color: _accion.level.color,
                      locked: _locked[0],
                      rollTick: _rollTick,
                      isRolling: _rollController.isAnimating,
                      onLockToggle: () =>
                          setState(() => _locked[0] = !_locked[0]),
                      randomPreview: () => _pick(kAcciones).text,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DiceTile(
                      emoji: '📍',
                      label: 'Zona',
                      value: _zona.text,
                      color: _zona.level.color,
                      locked: _locked[1],
                      rollTick: _rollTick,
                      isRolling: _rollController.isAnimating,
                      onLockToggle: () =>
                          setState(() => _locked[1] = !_locked[1]),
                      randomPreview: () => _pick(kZonas).text,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DiceTile(
                      emoji: '✨',
                      label: 'Estilo',
                      value: _modificador.text,
                      color: _modificador.level.color,
                      locked: _locked[2],
                      rollTick: _rollTick,
                      isRolling: _rollController.isAnimating,
                      onLockToggle: () =>
                          setState(() => _locked[2] = !_locked[2]),
                      randomPreview: () => _pick(kModificadores).text,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Toca el 🔒 para fijar un dado antes de volver a tirar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),

              const SizedBox(height: 28),

              // ── Botón lanzar ─────────────────────────────────────────────
              GestureDetector(
                onTap: _rollController.isAnimating ? null : _rollDice,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF48FB1), Color(0xFFCE6D8B)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCE6D8B).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎲', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Text(
                          _rollController.isAnimating
                              ? 'Lanzando...'
                              : '¡LANZAR LOS DADOS!',
                          style: const TextStyle(
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
            ],
          ),
        ),
      ),
    );
  }

  String _displayAccion() => _accion.text;
  String _displayZona() => _zona.text;
  String _displayModificador() => _modificador.text;

  Widget _buildLevelFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _levelChip(null, 'Todos', '🎲'),
          const SizedBox(width: 8),
          for (final l in DesireLevel.values) ...[
            _levelChip(l, l.label, l.emoji),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _levelChip(DesireLevel? level, String label, String emoji) {
    final isSelected = _filterLevel == level;
    final color = level?.color ?? AppColors.violeta;
    return GestureDetector(
      onTap: () => setState(() => _filterLevel = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dado individual con animación de flicker + candado ─────────────────────
class _DiceTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final bool locked;
  final bool isRolling;
  final int rollTick;
  final VoidCallback onLockToggle;
  final String Function() randomPreview;

  const _DiceTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.locked,
    required this.isRolling,
    required this.rollTick,
    required this.onLockToggle,
    required this.randomPreview,
  });

  @override
  Widget build(BuildContext context) {
    final showFlicker = isRolling && !locked;
    final displayText = showFlicker ? randomPreview() : value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      constraints: const BoxConstraints(minHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: locked ? color : Colors.grey.shade200,
          width: locked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                GestureDetector(
                  onTap: onLockToggle,
                  child: Icon(
                    locked ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 16,
                    color: locked ? color : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 80),
                  child: Text(
                    displayText,
                    key: ValueKey('$displayText$rollTick'),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: locked ? color : AppColors.violeta,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
