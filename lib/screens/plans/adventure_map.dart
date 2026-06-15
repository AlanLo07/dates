// lib/screens/plans/adventure_map.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cita.dart';
import '../../utils/colors.dart';
import '../../utils/animations.dart';
import 'result.dart';

// ── Modelo interno para el marker ────────────────────────────────────────────
class _PlaceMarker {
  final Cita cita;
  final LatLng position;

  const _PlaceMarker({required this.cita, required this.position});
}

class AdventureMapScreen extends StatefulWidget {
  final List<Cita> lugares;
  final String titulo;

  const AdventureMapScreen({
    super.key,
    required this.lugares,
    required this.titulo,
  });

  @override
  State<AdventureMapScreen> createState() => _AdventureMapScreenState();
}

class _AdventureMapScreenState extends State<AdventureMapScreen> {
  final MapController _mapController = MapController();

  List<_PlaceMarker> _markers = [];
  bool _isLoading = true;
  String? _error;
  _PlaceMarker? _selectedMarker;

  // México DF como centro por defecto
  static const LatLng _defaultCenter = LatLng(19.4326, -99.1332);

  @override
  void initState() {
    super.initState();
    _geocodeLugares();
  }

  // ── Geocodificación ───────────────────────────────────────────────────────
  Future<void> _geocodeLugares() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final resolved = <_PlaceMarker>[];

    for (final cita in widget.lugares) {
      // Solo los visitados tienen sentido en el mapa
      if (!cita.isVisited) continue;

      final coords = await _resolveCoords(cita);
      if (coords != null) {
        resolved.add(_PlaceMarker(cita: cita, position: coords));
      }
    }

    if (!mounted) return;
    setState(() {
      _markers = resolved;
      _isLoading = false;
    });

    // Centrar el mapa si hay markers
    if (_markers.isNotEmpty) {
      _fitBounds();
    }
  }

  /// Intenta extraer coords del link de Google Maps o geocodifica el nombre.
  Future<LatLng?> _resolveCoords(Cita cita) async {
    // 1. Intentar parsear lat/lng del link de Google Maps
    if (cita.link.isNotEmpty) {
      final fromLink = _parseCoordsFromGoogleMapsUrl(cita.link);
      if (fromLink != null) return fromLink;
    }

    // 2. Geocodificar por nombre + "México" para contexto
    try {
      final query = '${cita.nombre}, México';
      final locations = await locationFromAddress(
        query,
      ).timeout(const Duration(seconds: 5));
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {}

    // 3. Geocodificar por descripción como último recurso
    try {
      final locations = await locationFromAddress(
        cita.descripcion,
      ).timeout(const Duration(seconds: 5));
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (_) {}

    return null;
  }

  LatLng? _parseCoordsFromGoogleMapsUrl(String url) {
    final atPattern = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');
    var match = atPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    final llPattern = RegExp(r'(?:ll|q)=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    match = llPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null) return LatLng(lat, lng);
    }

    return null;
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    if (_markers.length == 1) {
      _mapController.move(_markers.first.position, 13);
      return;
    }

    double minLat = _markers.first.position.latitude;
    double maxLat = minLat;
    double minLng = _markers.first.position.longitude;
    double maxLng = minLng;

    for (final m in _markers) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat - 0.5, minLng - 0.5),
      LatLng(maxLat + 0.5, maxLng + 0.5),
    );

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  void _navigateToResult(Cita cita) {
    Navigator.of(context).push(createRoute(ResultScreen(cita: cita)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: Text(
          '🗺️ ${widget.titulo}',
          style: const TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_markers.length} lugares',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.violeta.withOpacity(0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _markers.isEmpty
          ? _buildEmpty()
          : _buildMap(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.violeta),
          const SizedBox(height: 16),
          Text(
            'Ubicando tus aventuras...',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text(
            'Sin lugares visitados aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.violeta,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Marca lugares como visitados\npara verlos en el mapa',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        // ── Mapa ───────────────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _markers.isNotEmpty
                ? _markers.first.position
                : _defaultCenter,
            initialZoom: 5,
            onTap: (_, __) => setState(() => _selectedMarker = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nuestrolugarseguro.app',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _markers.map((pm) => _buildMarker(pm)).toList(),
            ),
          ],
        ),

        // ── Botón "encuadrar todos" ────────────────────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'fit_bounds',
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.violeta,
            elevation: 3,
            onPressed: _fitBounds,
            child: const Icon(Icons.fit_screen_rounded),
          ),
        ),

        // ── Card del lugar seleccionado ────────────────────────────────────
        if (_selectedMarker != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildPlaceCard(_selectedMarker!),
          ),
      ],
    );
  }

  Marker _buildMarker(_PlaceMarker pm) {
    final isSelected = _selectedMarker == pm;

    return Marker(
      point: pm.position,
      width: isSelected ? 70 : 56,
      height: isSelected ? 70 : 56,
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedMarker = isSelected ? null : pm;
          if (!isSelected) {
            _mapController.move(pm.position, 14);
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.violeta : Colors.white,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violeta.withOpacity(isSelected ? 0.4 : 0.2),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: pm.cita.imagenUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: pm.cita.imagenUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _emojiMarker(),
                    errorWidget: (_, __, ___) => _emojiMarker(),
                  )
                : _emojiMarker(),
          ),
        ),
      ),
    );
  }

  Widget _emojiMarker() {
    return Container(
      color: AppColors.lavanda,
      child: const Center(child: Text('✈️', style: TextStyle(fontSize: 22))),
    );
  }

  Widget _buildPlaceCard(_PlaceMarker pm) {
    final cita = pm.cita;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(20),
      shadowColor: AppColors.violeta.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fila principal: foto + info + link ─────────────────────────
            Row(
              children: [
                // Foto o emoji
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: cita.imagenUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: cita.imagenUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _cardEmojiBox(),
                        )
                      : _cardEmojiBox(),
                ),

                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cita.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.violeta,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cita.descripcion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cita.descripcion,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (cita.rating > 0) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < cita.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 13,
                              color: i < cita.rating
                                  ? const Color(0xFFFFCA28)
                                  : Colors.grey.shade300,
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Botón link externo (mapa)
                if (cita.link.isNotEmpty)
                  GestureDetector(
                    onTap: () => _launchUrl(cita.link),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.violeta.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: AppColors.violeta,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Botón "Más detalles" ────────────────────────────────────────
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToResult(cita),
                icon: const Icon(Icons.info_outline_rounded, size: 17),
                label: const Text('Ver detalle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violeta,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardEmojiBox() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.lavanda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: Text('✈️', style: TextStyle(fontSize: 26))),
    );
  }
}
