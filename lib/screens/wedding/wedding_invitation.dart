import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingInvitationScreen extends StatefulWidget {
  const WeddingInvitationScreen({super.key});

  @override
  State<WeddingInvitationScreen> createState() => _WeddingInvitationScreenState();
}

class _WeddingInvitationScreenState extends State<WeddingInvitationScreen> {
  final WeddingService _service = WeddingService();
  final MapController _mapController = MapController();
  WeddingMeta? _meta;
  LatLng? _eventPoint;
  bool _mapLoading = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final meta = await _service.getPrimaryWedding();
      if (!mounted) return;
      setState(() {
        _meta = meta;
      });
      await _resolveEventPoint(meta);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final nombre = meta?.nombre ?? 'Nuestra boda';
    final fecha = meta?.fechaEvento ?? 'Por definir';
    final lugar = meta?.lugar ?? 'Por definir';
    final direccion = meta?.direccion ?? 'Por definir';
    final contacto = meta?.contacto ?? 'Sin contacto';
    final dressCode = meta?.dressCode ?? 'Por definir';
    final hashtag = meta?.instagramHashtag ?? '#NuestraBoda';

    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Invitación', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _rose),
            onPressed: _loadInvitation,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: _rose, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar la invitación',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadInvitation,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('💍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              nombre,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _rose,
                fontFamily: 'Serif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _meta?.mensajeBienvenida ?? 'Tienen el honor de invitarte\na su boda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF880E4F),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              Icons.calendar_today,
              'Fecha',
              fecha,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.location_on, 'Lugar', lugar),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.map_outlined, 'Dirección', direccion),
            const SizedBox(height: 12),
            _buildMapCard(meta),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.checkroom_outlined, 'Dress code', dressCode),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.phone_outlined, 'Contacto', contacto),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              hashtag,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveEventPoint(WeddingMeta? meta) async {
    if (meta == null) return;

    final query = _composeLocationQuery(meta);
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _eventPoint = null;
      });
      return;
    }

    final fromUrl = _parseCoordsFromGoogleMapsUrl(query);
    if (fromUrl != null) {
      if (!mounted) return;
      setState(() {
        _eventPoint = fromUrl;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _mapLoading = true;
    });

    try {
      final result = await locationFromAddress(query);
      if (!mounted) return;
      if (result.isNotEmpty) {
        setState(() {
          _eventPoint = LatLng(result.first.latitude, result.first.longitude);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _eventPoint = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _mapLoading = false;
      });
    }
  }

  String _composeLocationQuery(WeddingMeta meta) {
    final parts = <String>[
      if (meta.lugar != null && meta.lugar!.trim().isNotEmpty) meta.lugar!.trim(),
      if (meta.direccion != null && meta.direccion!.trim().isNotEmpty) meta.direccion!.trim(),
    ];
    return parts.join(', ');
  }

  LatLng? _parseCoordsFromGoogleMapsUrl(String value) {
    final regex = RegExp(r'(-?\d+(?:\.\d+)?),\s*(-?\d+(?:\.\d+)?)');
    final match = regex.firstMatch(value);
    if (match == null) return null;

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    return LatLng(lat, lng);
  }

  Future<void> _openExternalMap(WeddingMeta? meta) async {
    if (meta == null) return;

    final query = _composeLocationQuery(meta);
    if (query.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay dirección disponible para abrir el mapa.')),
      );
      return;
    }

    Uri uri;
    final coords = _eventPoint;
    if (coords != null) {
      uri = Uri.parse('https://www.google.com/maps?q=${coords.latitude},${coords.longitude}');
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
      );
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de mapas.')),
      );
    }
  }

  Widget _buildMapCard(WeddingMeta? meta) {
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
              const Icon(Icons.travel_explore_outlined, color: _rose, size: 22),
              const SizedBox(width: 10),
              Text(
                'Ubicación en mapa',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_mapLoading)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: _rose)),
            )
          else if (_eventPoint != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 190,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _eventPoint!,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                    ),
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
                          width: 42,
                          height: 42,
                          child: const Icon(
                            Icons.location_on,
                            color: _rose,
                            size: 38,
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
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'No se pudo ubicar la dirección automáticamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openExternalMap(meta),
              icon: const Icon(Icons.navigation_outlined, color: _rose),
              label: const Text('Abrir en mapas', style: TextStyle(color: _rose)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF8BBD0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _rose, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _rose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
