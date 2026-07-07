// lib/screens/home/widgets/home_mascot_bubble.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../models/phrase.dart';
import '../../../services/phrases_service.dart';
import '../../../utils/colors.dart';

/// Mascota flotante en la esquina inferior derecha del Home.
/// Muestra una imagen al azar (Chopper / Luffy) junto a un globo
/// de texto con una frase aleatoria del pool del ahorcado.
/// Tocar la mascota cambia la frase; el botón (x) la oculta.
class HomeMascotBubble extends StatefulWidget {
  const HomeMascotBubble({super.key});

  @override
  State<HomeMascotBubble> createState() => _HomeMascotBubbleState();
}

class _HomeMascotBubbleState extends State<HomeMascotBubble>
    with SingleTickerProviderStateMixin {
  static const List<String> _images = [
    'Alan1.jpeg',
    'Alan2.jpeg',
    'Nati1.jpeg',
    'Nati2.jpeg',
  ];

  final Random _random = Random();
  late final String _imagePath;

  LovePhrase? _phrase;
  bool _isLoading = true;
  bool _visible = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _imagePath = _images[_random.nextInt(_images.length)];

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);

    _loadPhrase();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPhrase() async {
    final phrase = await PhrasesService().getRandomPhrase();
    if (!mounted) return;
    setState(() {
      _phrase = phrase;
      _isLoading = false;
    });
    _entryCtrl.forward();
  }

  Future<void> _shuffle() async {
    setState(() => _isLoading = true);
    final phrase = await PhrasesService().getRandomPhrase();
    if (!mounted) return;
    setState(() {
      _phrase = phrase;
      _isLoading = false;
    });
  }

  void _dismiss() => setState(() => _visible = false);

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _scale,
      alignment: Alignment.bottomRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Globo de texto ──────────────────────────────────────
          Flexible(
            child: GestureDetector(
              onTap: _shuffle,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 180),
                margin: const EdgeInsets.only(bottom: 34, right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violeta.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.violeta,
                          ),
                        )
                      : Text(
                          _phrase?.text ?? 'Toca para otra frase 💌',
                          key: ValueKey(_phrase?.text),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.violeta,
                            height: 1.35,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // ── Mascota + botón cerrar ──────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _shuffle,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violeta.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(_imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.violeta,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
