// lib/screens/wedding.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'models/wedding_option.dart';
import 'widgets/wedding_countdown_header.dart';
import 'widgets/wedding_option_card.dart';
import 'wedding_guests.dart';
import 'wedding_checklist.dart';
import 'wedding_itinerary.dart';
import 'wedding_budget.dart';
import 'wedding_playlist.dart';
import 'wedding_invitation.dart';
import 'wedding_look.dart';
import 'wedding_providers.dart';
import '../../services/wedding_service.dart';
import '../../services/wedding_pdf_export_service.dart';
import '../../widgets/motion/ambient_orbs_background.dart';
import '../../widgets/motion/motion_section_reveal.dart';

// ── Fecha de la boda — ajusta según corresponda ──────────────────────────
DateTime kWeddingDate = DateTime(2027, 2, 14);

// ── Colores temáticos boda ────────────────────────────────────────────────
const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

enum _WeddingMenuAction { exportPdf }

class WeddingScreen extends StatefulWidget {
  const WeddingScreen({super.key});

  static final WeddingPdfExportService _pdfExportService =
      WeddingPdfExportService();

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
      subtitulo: 'Próximamente',
      color: Color(0xFFF3E5F5),
      screen: null,
    ),
    WeddingOption(
      emoji: '🎁',
      titulo: 'Mesa de regalos',
      subtitulo: 'Próximamente',
      color: Color(0xFFFBE9E7),
      screen: null,
    ),
    WeddingOption(
      emoji: '🌸',
      titulo: 'Flores',
      subtitulo: 'Próximamente',
      color: Color(0xFFFCE4EC),
      screen: null,
    ),
    WeddingOption(
      emoji: '🍽️',
      titulo: 'Menú',
      subtitulo: 'Próximamente',
      color: Color(0xFFE8F5E9),
      screen: null,
    ),
    WeddingOption(
      emoji: '🏨',
      titulo: 'Hospedaje',
      subtitulo: 'Próximamente',
      color: Color(0xFFE3F2FD),
      screen: null,
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
  State<WeddingScreen> createState() => _WeddingScreenState();
}

class _WeddingScreenState extends State<WeddingScreen> {
  final WeddingService _service = WeddingService();
  final MapController _mapController = MapController();
  WeddingMeta? _meta;
  LatLng? _eventPoint;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationSummary();
  }

  Future<void> _loadLocationSummary() async {
    setState(() {
      _locationLoading = true;
    });

    try {
      final meta = await _service.getPrimaryWedding();
      final point = await _resolvePoint(meta);
      if (!mounted) return;
      setState(() {
        _meta = meta;
        _eventPoint = point;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _meta = null;
        _eventPoint = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
      });
    }
  }

  Future<LatLng?> _resolvePoint(WeddingMeta? meta) async {
    if (meta == null) return null;

    final query = _composeLocationQuery(meta);
    if (query.isEmpty) return null;

    final directPoint = _parseCoords(query);
    if (directPoint != null) return directPoint;

    try {
      final result = await locationFromAddress(query);
      if (result.isEmpty) return null;
      return LatLng(result.first.latitude, result.first.longitude);
    } catch (_) {
      return null;
    }
  }

  String _composeLocationQuery(WeddingMeta meta) {
    final parts = <String>[
      if (meta.lugar != null && meta.lugar!.trim().isNotEmpty) meta.lugar!.trim(),
      if (meta.direccion != null && meta.direccion!.trim().isNotEmpty) meta.direccion!.trim(),
    ];
    return parts.join(', ');
  }

  LatLng? _parseCoords(String value) {
    final regex = RegExp(r'(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)');
    final match = regex.firstMatch(value);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

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
          PopupMenuButton<_WeddingMenuAction>(
            color: Colors.white,
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (_) => [
              const PopupMenuItem<_WeddingMenuAction>(
                value: _WeddingMenuAction.exportPdf,
                child: Text('Exportar PDF'),
              ),
            ],
          ),
        ],
      ),
      body: AmbientOrbsBackground(
        colors: const [Color(0xFFF8BBD0), Color(0xFFFCE4EC), Color(0xFFE8EAF6)],
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: MotionSectionReveal(
                child: WeddingCountdownHeader(
                  weddingDate: kWeddingDate,
                  accentColor: _rose,
                ),
              ),
            ),

            // ── Información rápida ────────────────────────────────────────
            SliverToBoxAdapter(
              child: MotionSectionReveal(
                delay: const Duration(milliseconds: 120),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

              SliverToBoxAdapter(
                child: MotionSectionReveal(
                  delay: const Duration(milliseconds: 160),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildLocationSummaryCard(context),
                  ),
                ),
              ),

            // ── Grid de opciones ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => MotionSectionReveal(
                    delay: Duration(milliseconds: 180 + (i * 45)),
                    beginOffsetY: 0.08,
                    child: WeddingOptionCard(
                      option: WeddingScreen._opciones[i],
                      accentColor: _rose,
                    ),
                  ),
                  childCount: WeddingScreen._opciones.length,
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
      ),
    );
  }

  Widget _buildLocationSummaryCard(BuildContext context) {
    final locationLabel = _meta?.lugar?.trim().isNotEmpty == true
        ? _meta!.lugar!
        : (_meta?.direccion?.trim().isNotEmpty == true ? _meta!.direccion! : 'Ubicación pendiente');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, color: _rose),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ubicación de la boda',
                  style: TextStyle(
                    color: _rose,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WeddingInvitationScreen(),
                    ),
                  );
                },
                child: const Text('Ver detalle'),
              ),
            ],
          ),
          Text(
            locationLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          if (_locationLoading)
            const SizedBox(
              height: 130,
              child: Center(child: CircularProgressIndicator(color: _rose)),
            )
          else if (_eventPoint != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 150,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _eventPoint!,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nuestrolugarseguro.app',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _eventPoint!,
                          width: 38,
                          height: 38,
                          child: const Icon(
                            Icons.location_on,
                            color: _rose,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 90,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No fue posible ubicar la dirección automáticamente.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    _WeddingMenuAction action,
  ) async {
    switch (action) {
      case _WeddingMenuAction.exportPdf:
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Generando PDF de boda...')),
        );

        try {
          await WeddingScreen._pdfExportService.exportWeddingPdf();
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            const SnackBar(content: Text('PDF generado y listo para compartir.')),
          );
        } catch (error) {
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text('No se pudo exportar el PDF: $error')),
          );
        }
    }
  }
}
