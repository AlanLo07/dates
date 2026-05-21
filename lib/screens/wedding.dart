// lib/screens/wedding.dart
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/animations.dart';
import 'wedding_guests.dart';
import 'wedding_checklist.dart';
import 'wedding_itinerary.dart';
import 'wedding_budget.dart';
import 'wedding_playlist.dart';
import 'wedding_invitation.dart';

// ── Fecha de la boda — ajusta según corresponda ──────────────────────────
DateTime kWeddingDate = DateTime(2027, 2, 14);

// ── Colores temáticos boda ────────────────────────────────────────────────
const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

class WeddingScreen extends StatelessWidget {
  const WeddingScreen({super.key});

  static const List<_WeddingOption> _opciones = [
    _WeddingOption(
      emoji: '💌',
      titulo: 'Invitación',
      subtitulo: 'Fecha, hora y lugar',
      color: Color(0xFFFCE4EC),
      screen: WeddingInvitationScreen(),
    ),
    _WeddingOption(
      emoji: '👥',
      titulo: 'Invitados',
      subtitulo: 'Lista y confirmaciones',
      color: Color(0xFFE8EAF6),
      screen: WeddingGuestsScreen(),
    ),
    _WeddingOption(
      emoji: '✅',
      titulo: 'Checklist',
      subtitulo: 'Tareas por categoría',
      color: Color(0xFFE1F5EE),
      screen: WeddingChecklistScreen(),
    ),
    _WeddingOption(
      emoji: '🗓️',
      titulo: 'Itinerario',
      subtitulo: 'Plan del gran día',
      color: Color(0xFFE0F2F1),
      screen: WeddingItineraryScreen(),
    ),
    _WeddingOption(
      emoji: '💰',
      titulo: 'Presupuesto',
      subtitulo: 'Gastos y estimados',
      color: Color(0xFFFFF9C4),
      screen: WeddingBudgetScreen(),
    ),
    _WeddingOption(
      emoji: '🎵',
      titulo: 'Playlist',
      subtitulo: 'Música del evento',
      color: Color(0xFFFFF3E0),
      screen: WeddingPlaylistScreen(),
    ),
    _WeddingOption(
      emoji: '📸',
      titulo: 'Álbum',
      subtitulo: 'Fotos del gran día',
      color: Color(0xFFF3E5F5),
      screen: null,
    ), // TODO
    _WeddingOption(
      emoji: '🎁',
      titulo: 'Mesa de regalos',
      subtitulo: 'Lista de deseos',
      color: Color(0xFFFBE9E7),
      screen: null,
    ), // TODO
    _WeddingOption(
      emoji: '🌸',
      titulo: 'Flores',
      subtitulo: 'Arreglos y decoración',
      color: Color(0xFFFCE4EC),
      screen: null,
    ), // TODO
    _WeddingOption(
      emoji: '🍽️',
      titulo: 'Menú',
      subtitulo: 'Catering y opciones',
      color: Color(0xFFE8F5E9),
      screen: null,
    ), // TODO
    _WeddingOption(
      emoji: '🏨',
      titulo: 'Hospedaje',
      subtitulo: 'Para los invitados',
      color: Color(0xFFE3F2FD),
      screen: null,
    ), // TODO
    _WeddingOption(
      emoji: '💄',
      titulo: 'Look',
      subtitulo: 'Vestido, traje y estilismo',
      color: Color(0xFFF8BBD0),
      screen: null,
    ), // TODO
  ];

  @override
  Widget build(BuildContext context) {
    final days = kWeddingDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: _roseLight,
      appBar: AppBar(
        title: const Text(
          '💍 Nuestra Boda',
          style: TextStyle(color: _rose, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        elevation: 1,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Countdown header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _rose.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('💍', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    days > 0
                        ? '¡Faltan $days días!'
                        : '¡Hoy es el gran día! 🎉',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _rose,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${kWeddingDate.day.toString().padLeft(2, '0')}-'
                    '${kWeddingDate.month.toString().padLeft(2, '0')}-'
                    '${kWeddingDate.year}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // ── Grid de opciones ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildOptionCard(ctx, _opciones[i]),
                childCount: _opciones.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, _WeddingOption opt) {
    return GestureDetector(
      onTap: () {
        if (opt.screen != null) {
          Navigator.of(context).push(createRoute(opt.screen!));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('¡Próximamente! 💍')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _rose.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: opt.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(opt.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              opt.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _rose,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                opt.subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeddingOption {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final Color color;
  final Widget? screen;
  const _WeddingOption({
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.color,
    required this.screen,
  });
}
