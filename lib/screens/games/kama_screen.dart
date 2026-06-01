// lib/screens/games/kama_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/kama.dart';
import '../../utils/colors.dart';

class KamaScreen extends StatefulWidget {
  const KamaScreen({super.key});

  @override
  State<KamaScreen> createState() => _KamaScreenState();
}

class _KamaScreenState extends State<KamaScreen>
    with SingleTickerProviderStateMixin {
  KamaLevel? _filterLevel; // null = todos
  late List<KamaPosition> _pool;
  late KamaPosition _current;
  bool _showDetails = false;

  // Animación de flip al cambiar de tarjeta
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _rebuildPool();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _rebuildPool({KamaLevel? level}) {
    _filterLevel = level;
    _pool = level == null
        ? List.from(kKamaPositions)
        : kKamaPositions.where((p) => p.level == level).toList();
    _pool.shuffle(Random());
    _current = _pool.first;
    _showDetails = false;
  }

  Future<void> _nextCard() async {
    await _flipCtrl.forward();
    setState(() {
      _pool.remove(_current);
      if (_pool.isEmpty) {
        // Recarga la misma lista al terminar el mazo
        _rebuildPool(level: _filterLevel);
      } else {
        _current = _pool.first;
        _showDetails = false;
      }
    });
    _flipCtrl.reverse();
  }

  Future<void> _launchLink(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  // ── Colores por nivel ──────────────────────────────────────────────────────

  Color _levelBg(KamaLevel l) {
    switch (l) {
      case KamaLevel.facil:
        return const Color(0xFFE1F5EE); // teal
      case KamaLevel.medio:
        return const Color(0xFFFAEEDA); // amber
      case KamaLevel.avanzado:
        return const Color(0xFFFAECE7); // coral
    }
  }

  Color _levelText(KamaLevel l) {
    switch (l) {
      case KamaLevel.facil:
        return const Color(0xFF0F6E56);
      case KamaLevel.medio:
        return const Color(0xFF854F0B);
      case KamaLevel.avanzado:
        return const Color(0xFF993C1D);
    }
  }

  Color _levelFire(KamaLevel l) {
    switch (l) {
      case KamaLevel.facil:
        return const Color(0xFF1D9E75);
      case KamaLevel.medio:
        return const Color(0xFFBA7517);
      case KamaLevel.avanzado:
        return const Color(0xFFD85A30);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Kamasutra 🃏',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
        actions: [
          // Contador de tarjetas restantes
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_pool.length} restantes',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.violeta.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (ctx, child) {
                // Efecto de volteo: cuando pasa de 0.5 ocultamos el frente
                final angle = _flipAnim.value * pi;
                final isBack = angle > pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle),
                  child: isBack ? const SizedBox.shrink() : child,
                );
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: _buildCard(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra de filtro ────────────────────────────────────────────────────────

  Widget _buildFilterBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildFilterChip(label: 'Todos', level: null),
          const SizedBox(width: 8),
          _buildFilterChip(label: '🟢 Fácil', level: KamaLevel.facil),
          const SizedBox(width: 8),
          _buildFilterChip(label: '🟠 Medio', level: KamaLevel.medio),
          const SizedBox(width: 8),
          _buildFilterChip(label: '🔴 Difícil', level: KamaLevel.avanzado),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required KamaLevel? level}) {
    final isSelected = _filterLevel == level;
    return GestureDetector(
      onTap: () {
        if (_filterLevel == level) return;
        setState(() => _rebuildPool(level: level));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.violeta.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.violeta : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.violeta : Colors.grey,
          ),
        ),
      ),
    );
  }

  // ── Tarjeta principal ──────────────────────────────────────────────────────

  Widget _buildCard() {
    final pos = _current;
    final bg = _levelBg(pos.level);
    final textColor = _levelText(pos.level);
    final fireColor = _levelFire(pos.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tarjeta ──────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.violeta.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera de color
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(pos.emoji, style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 12),
                    Text(
                      pos.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Indicador de dificultad con fueguitos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(
                                3,
                                (i) => Text(
                                  '🔥',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: i < pos.level.fires
                                        ? fireColor
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pos.level.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Descripción corta
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                child: Text(
                  pos.shortDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),

              // Botón "Ver cómo hacerlo"
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: () => setState(() => _showDetails = !_showDetails),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.violeta,
                    padding: EdgeInsets.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showDetails ? 'Ocultar detalles' : 'Ver cómo hacerlo',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Detalles expandibles ──────────────────────────────────────
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: _buildDetails(pos),
                crossFadeState: _showDetails
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Botón siguiente ───────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: _nextCard,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Siguiente posición'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.violeta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sección de detalles ────────────────────────────────────────────────────

  Widget _buildDetails(KamaPosition pos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 12),

          // Descripción explícita
          _buildDetailSection(
            icon: Icons.info_outline,
            title: 'Cómo hacerlo',
            content: pos.fullDesc,
          ),

          const SizedBox(height: 14),

          // Consejo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lavanda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consejo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.violeta,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pos.tips,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.violeta,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botón de referencia visual
          OutlinedButton.icon(
            onPressed: () => _launchLink(pos.link),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Ver referencia visual'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.violeta,
              side: const BorderSide(color: AppColors.violeta, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.violeta),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.violeta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
