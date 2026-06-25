// lib/screens/wedding.dart
import 'package:flutter/material.dart';
import 'models/wedding_option.dart';
import 'widgets/wedding_countdown_header.dart';
import 'widgets/wedding_option_card.dart';
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

  static const List<WeddingOption> _opciones = [
    WeddingOption(
      emoji: '💌',
      titulo: 'Invitación',
      subtitulo: 'Fecha, hora y lugar',
      color: Color(0xFFFCE4EC),
      screen: WeddingInvitationScreen(),
    ),
    WeddingOption(
      emoji: '👥',
      titulo: 'Invitados',
      subtitulo: 'Lista y confirmaciones',
      color: Color(0xFFE8EAF6),
      screen: WeddingGuestsScreen(),
    ),
    WeddingOption(
      emoji: '✅',
      titulo: 'Checklist',
      subtitulo: 'Tareas por categoría',
      color: Color(0xFFE1F5EE),
      screen: WeddingChecklistScreen(),
    ),
    WeddingOption(
      emoji: '🗓️',
      titulo: 'Itinerario',
      subtitulo: 'Plan del gran día',
      color: Color(0xFFE0F2F1),
      screen: WeddingItineraryScreen(),
    ),
    WeddingOption(
      emoji: '💰',
      titulo: 'Presupuesto',
      subtitulo: 'Gastos y estimados',
      color: Color(0xFFFFF9C4),
      screen: WeddingBudgetScreen(),
    ),
    WeddingOption(
      emoji: '🎵',
      titulo: 'Playlist',
      subtitulo: 'Música del evento',
      color: Color(0xFFFFF3E0),
      screen: WeddingPlaylistScreen(),
    ),
    WeddingOption(
      emoji: '📸',
      titulo: 'Álbum',
      subtitulo: 'Fotos del gran día',
      color: Color(0xFFF3E5F5),
      screen: null,
    ), // TODO
    WeddingOption(
      emoji: '🎁',
      titulo: 'Mesa de regalos',
      subtitulo: 'Lista de deseos',
      color: Color(0xFFFBE9E7),
      screen: null,
    ), // TODO
    WeddingOption(
      emoji: '🌸',
      titulo: 'Flores',
      subtitulo: 'Arreglos y decoración',
      color: Color(0xFFFCE4EC),
      screen: null,
    ), // TODO
    WeddingOption(
      emoji: '🍽️',
      titulo: 'Menú',
      subtitulo: 'Catering y opciones',
      color: Color(0xFFE8F5E9),
      screen: null,
    ), // TODO
    WeddingOption(
      emoji: '🏨',
      titulo: 'Hospedaje',
      subtitulo: 'Para los invitados',
      color: Color(0xFFE3F2FD),
      screen: null,
    ), // TODO
    WeddingOption(
      emoji: '💄',
      titulo: 'Look',
      subtitulo: 'Vestido, traje y estilismo',
      color: Color(0xFFF8BBD0),
      screen: null,
    ), // TODO
  ];

  @override
  Widget build(BuildContext context) {
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
          SliverToBoxAdapter(
            child: WeddingCountdownHeader(
              weddingDate: kWeddingDate,
              accentColor: _rose,
            ),
          ),

          // ── Grid de opciones ────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => WeddingOptionCard(
                  option: _opciones[i],
                  accentColor: _rose,
                ),
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
}
