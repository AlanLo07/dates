// lib/screens/wedding.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'models/wedding_option.dart';
import 'models/wedding_models.dart';
import 'widgets/wedding_countdown_header.dart';
import 'widgets/wedding_option_card.dart';
import 'wedding_guests.dart';
import 'wedding_checklist.dart';
import 'wedding_itinerary.dart';
import 'wedding_budget.dart';
import 'wedding_playlist.dart';
import 'wedding_invitation.dart';
import 'wedding_flowers.dart';
import 'wedding_lodging.dart';
import 'wedding_look.dart';
import 'wedding_menu.dart';
import 'wedding_album.dart';
import 'wedding_gifts.dart';
import 'wedding_providers.dart';

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
      screen: WeddingAlbumScreen(),
    ),
    WeddingOption(
      emoji: '🎁',
      titulo: 'Mesa de regalos',
      subtitulo: 'Lista de deseos',
      color: Color(0xFFFBE9E7),
      screen: WeddingGiftsScreen(),
    ),
    WeddingOption(
      emoji: '🌸',
      titulo: 'Flores',
      subtitulo: 'Arreglos y decoración',
      color: Color(0xFFFCE4EC),
      screen: WeddingFlowersScreen(),
    ),
    WeddingOption(
      emoji: '🍽️',
      titulo: 'Menú',
      subtitulo: 'Catering y opciones',
      color: Color(0xFFE8F5E9),
      screen: WeddingMenuScreen(),
    ),
    WeddingOption(
      emoji: '🏨',
      titulo: 'Hospedaje',
      subtitulo: 'Para los invitados',
      color: Color(0xFFE3F2FD),
      screen: WeddingLodgingScreen(),
    ),
    WeddingOption(
      emoji: '💄',
      titulo: 'Look',
      subtitulo: 'Vestido, traje y estilismo',
      color: Color(0xFFF8BBD0),
      screen: WeddingLookScreen(),
    ),
    WeddingOption(
      emoji: '👨‍💼',
      titulo: 'Proveedores',
      subtitulo: 'Servicios y contactos',
      color: Color(0xFFE8EAF6),
      screen: WeddingProvidersScreen(),
    ),
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
        actions: [
          PopupMenuButton(
            color: Colors.white,
            itemBuilder: (_) => [
              const PopupMenuItem(
                child: Text('📥 Exportar Checklist (CSV)'),
              ),
              const PopupMenuItem(
                child: Text('📥 Exportar Presupuesto (CSV)'),
              ),
              const PopupMenuItem(
                child: Text('📥 Exportar Proveedores (CSV)'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                child: Text('⚙️ Configuración'),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WeddingCountdownHeader(
              weddingDate: kWeddingDate,
              accentColor: _rose,
            ),
          ),

          // ── Información rápida ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '13',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _rose,
                            ),
                          ),
                          Text(
                            'Secciones',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      VerticalDivider(),
                      Column(
                        children: [
                          Text(
                            '∞',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _rose,
                            ),
                          ),
                          Text(
                            'Detalles',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      VerticalDivider(),
                      Column(
                        children: [
                          Text(
                            '✓',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'Listo',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
