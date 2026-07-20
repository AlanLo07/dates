// lib/screens/home/widgets/home_mascot_bubble.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../../../models/phrase.dart';
import '../../../services/home_mascot_service.dart';
import '../../../services/phrases_service.dart';
import '../../../utils/colors.dart';

/// Mascota flotante en la esquina inferior derecha del Home.
/// Muestra una imagen remota al azar junto a un globo
/// de texto con una frase aleatoria del pool del ahorcado.
/// Tocar la mascota cambia la frase; el botón (x) la oculta.
class HomeMascotBubble extends StatefulWidget {
  const HomeMascotBubble({super.key});

  @override
  State<HomeMascotBubble> createState() => _HomeMascotBubbleState();
}

class _HomeMascotBubbleState extends State<HomeMascotBubble>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final HomeMascotService _mascotService = HomeMascotService();

  String? _imageUrl;

  LovePhrase? _phrase;
  bool _isLoading = true;
  bool _isImageLoading = true;
  bool _visible = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);

    _loadMascotImage();
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

  Future<void> _loadMascotImage({bool forceRefresh = false}) async {
    final imageUrl = await _mascotService.getRandomImage(
      forceRefresh: forceRefresh,
    );
    if (!mounted) return;
    setState(() {
      _imageUrl = imageUrl;
      _isImageLoading = false;
    });
  }

  Future<void> _shuffle() async {
    setState(() {
      _isLoading = true;
      _isImageLoading = true;
    });
    final phraseFuture = PhrasesService().getRandomPhrase();
    final imagesFuture = _mascotService.getMascotImages();
    final phrase = await phraseFuture;
    final images = await imagesFuture;
    if (!mounted) return;
    setState(() {
      _phrase = phrase;
      _imageUrl = images.isEmpty ? null : images[_random.nextInt(images.length)];
      _isLoading = false;
      _isImageLoading = false;
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
                    child: _buildMascotImage(),
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

  Widget _buildMascotImage() {
    if (_isImageLoading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.violeta,
          ),
        ),
      );
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      return Container(
        color: const Color(0xFFF6F0FF),
        child: const Icon(
          Icons.favorite_rounded,
          color: AppColors.violeta,
          size: 30,
        ),
      );
    }

    return Image.network(
      _imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF6F0FF),
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.violeta,
          size: 26,
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.violeta,
            ),
          ),
        );
      },
    );
  }
}
