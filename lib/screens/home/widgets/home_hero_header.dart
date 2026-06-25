import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../utils/colors.dart';

class HomeHeroHeader extends StatelessWidget {
  final String imageUrl;

  const HomeHeroHeader({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.violeta.withOpacity(0.4)),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.violeta.withOpacity(0.4),
              child: const Icon(Icons.favorite, size: 48, color: Colors.white54),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.65),
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 18,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, Nati 💌',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Hoy es un buen día para hacer algo especial',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}