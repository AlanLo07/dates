// lib/screens/wedding_itinerary.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/boda.dart';
import '../memories/location_picker.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingItineraryScreen extends StatefulWidget {
  const WeddingItineraryScreen({super.key});
  @override
  State<WeddingItineraryScreen> createState() => _WeddingItineraryScreenState();
}

class _WeddingItineraryScreenState extends State<WeddingItineraryScreen> {
  final WeddingService _service = WeddingService();
  final List<PasoBoda> _pasos = [];
  String? _bodaId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItinerario();
  }

  Future<void> _loadItinerario() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final meta = await _service.getPrimaryWedding();
      final bodaId = meta?.id;
      if (bodaId == null || bodaId.isEmpty) {
        throw Exception('No hay boda activa.');
      }
      final pasos = await _service.getItinerario(bodaId);
      pasos.sort((a, b) => a.hora.compareTo(b.hora));
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _pasos
          ..clear()
          ..addAll(pasos);
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Itinerario', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _rose),
            onPressed: _loadItinerario,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregar(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : _error != null
          ? _buildError()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pasos.length,
              itemBuilder: (ctx, i) {
                final paso = _pasos[i];
                final isLast = i == _pasos.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Línea de tiempo
                      SizedBox(
                        width: 48,
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCE4EC),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  paso.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: Colors.pink.shade100,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Contenido
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      paso.titulo,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _rose,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        paso.hora,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _mostrarEditar(context, paso),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: _rose,
                                          size: 20,
                                        ),
                                        tooltip: 'Editar paso',
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (paso.nota.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  paso.nota,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                              if (paso.ubicacion.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _PasoLocationPreview(
                                  ubicacion: paso.ubicacion,
                                  ubicacionLat: paso.ubicacionLat,
                                  ubicacionLng: paso.ubicacionLng,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: _rose, size: 42),
            const SizedBox(height: 10),
            Text(
              'No se pudo cargar el itinerario',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadItinerario,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAgregar(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final horaCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
    final ubicacionCtrl = TextEditingController();
    final coordsNotifier = ValueNotifier<LatLng?>(null);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agregar paso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _rose,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tituloCtrl,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: horaCtrl,
              decoration: InputDecoration(
                labelText: 'Hora (ej: 18:30)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notaCtrl,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildUbicacionField(context, ubicacionCtrl, coordsNotifier),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (tituloCtrl.text.trim().isEmpty) return;
                  final bodaId = _bodaId;
                  if (bodaId == null) return;
                  final nuevo = PasoBoda(
                    id: '',
                    titulo: tituloCtrl.text.trim(),
                    hora: horaCtrl.text.trim(),
                    nota: notaCtrl.text.trim(),
                    ubicacion: ubicacionCtrl.text.trim(),
                    ubicacionLat: coordsNotifier.value?.latitude,
                    ubicacionLng: coordsNotifier.value?.longitude,
                  );
                  _service
                      .createPaso(bodaId, nuevo)
                      .then((creado) {
                        if (!mounted) return;
                        setState(() {
                          _pasos.add(creado);
                          _pasos.sort((a, b) => a.hora.compareTo(b.hora));
                        });
                      })
                      .catchError((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo agregar el paso'),
                          ),
                        );
                      });
                  Navigator.pop(context);
                },
                child: const Text('Agregar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarEditar(BuildContext context, PasoBoda paso) {
    final tituloCtrl = TextEditingController(text: paso.titulo);
    final horaCtrl = TextEditingController(text: paso.hora);
    final notaCtrl = TextEditingController(text: paso.nota);
    final ubicacionCtrl = TextEditingController(text: paso.ubicacion);
    final initialPoint =
        (paso.ubicacionLat != null && paso.ubicacionLng != null)
        ? LatLng(paso.ubicacionLat!, paso.ubicacionLng!)
        : null;
    final coordsNotifier = ValueNotifier<LatLng?>(initialPoint);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Editar paso',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _rose,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tituloCtrl,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: horaCtrl,
              decoration: InputDecoration(
                labelText: 'Hora (ej: 18:30)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notaCtrl,
              decoration: InputDecoration(
                labelText: 'Nota (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildUbicacionField(context, ubicacionCtrl, coordsNotifier),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (tituloCtrl.text.trim().isEmpty) return;
                  final bodaId = _bodaId;
                  if (bodaId == null) return;

                  final actualizado = PasoBoda(
                    id: paso.id,
                    titulo: tituloCtrl.text.trim(),
                    hora: horaCtrl.text.trim(),
                    nota: notaCtrl.text.trim(),
                    emoji: paso.emoji,
                    ubicacion: ubicacionCtrl.text.trim(),
                    ubicacionLat: coordsNotifier.value?.latitude,
                    ubicacionLng: coordsNotifier.value?.longitude,
                  );

                  try {
                    final saved = await _service.updatePaso(
                      bodaId,
                      actualizado,
                    );
                    if (!mounted) return;
                    setState(() {
                      final index = _pasos.indexWhere(
                        (item) => item.id == paso.id,
                      );
                      if (index != -1) {
                        _pasos[index] = saved;
                        _pasos.sort((a, b) => a.hora.compareTo(b.hora));
                      }
                    });
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo actualizar el paso'),
                      ),
                    );
                  }
                },
                child: const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionField(
    BuildContext context,
    TextEditingController ubicacionCtrl,
    ValueNotifier<LatLng?> coordsNotifier,
  ) {
    return _UbicacionAutocompleteField(
      controller: ubicacionCtrl,
      selectedPoint: coordsNotifier,
      onPickFromMap: () => showLocationPicker(context),
    );
  }
}

class _UbicacionAutocompleteField extends StatefulWidget {
  const _UbicacionAutocompleteField({
    required this.controller,
    required this.selectedPoint,
    required this.onPickFromMap,
  });

  final TextEditingController controller;
  final ValueNotifier<LatLng?> selectedPoint;
  final Future<String?> Function() onPickFromMap;

  @override
  State<_UbicacionAutocompleteField> createState() =>
      _UbicacionAutocompleteFieldState();
}

class _UbicacionAutocompleteFieldState
    extends State<_UbicacionAutocompleteField> {
  final List<_AddressSuggestion> _suggestions = <_AddressSuggestion>[];
  Timer? _debounce;
  int _requestId = 0;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String rawQuery) {
    final query = rawQuery.trim();
    _debounce?.cancel();
    widget.selectedPoint.value = null;

    if (query.length < 3) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _suggestions.clear();
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final currentRequestId = ++_requestId;
      if (!mounted) return;
      setState(() {
        _loading = true;
      });

      final results = await _searchSuggestions(query);
      if (!mounted || currentRequestId != _requestId) return;
      setState(() {
        _loading = false;
        _suggestions
          ..clear()
          ..addAll(results);
      });
    });
  }

  Future<List<_AddressSuggestion>> _searchSuggestions(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?format=jsonv2&limit=6&q=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'dates-app/1.0 (wedding itinerary autocomplete)',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const <_AddressSuggestion>[];
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return const <_AddressSuggestion>[];
      }

      final results = <_AddressSuggestion>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final label = (map['display_name'] ?? '').toString().trim();
        if (label.isEmpty) continue;
        final lat = double.tryParse((map['lat'] ?? '').toString());
        final lon = double.tryParse((map['lon'] ?? '').toString());
        results.add(
          _AddressSuggestion(label: label, latitude: lat, longitude: lon),
        );
      }
      return results;
    } catch (_) {
      return const <_AddressSuggestion>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: 'Ubicación (opcional)',
            hintText: 'Escribe una dirección, coordenadas o enlace de mapa',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                final subtitle =
                    (item.latitude != null && item.longitude != null)
                    ? '${item.latitude!.toStringAsFixed(5)}, ${item.longitude!.toStringAsFixed(5)}'
                    : null;
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.place_outlined,
                    color: _rose,
                    size: 18,
                  ),
                  title: Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: subtitle == null ? null : Text(subtitle),
                  onTap: () {
                    widget.controller.text = item.label;
                    if (item.latitude != null && item.longitude != null) {
                      widget.selectedPoint.value = LatLng(
                        item.latitude!,
                        item.longitude!,
                      );
                    } else {
                      widget.selectedPoint.value = null;
                    }
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _suggestions.clear();
                    });
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              final url = await widget.onPickFromMap();
              if (url == null) return;
              widget.controller.text = url;
              widget.selectedPoint.value = _parseCoords(url);
              if (!mounted) return;
              setState(() {
                _suggestions.clear();
              });
            },
            icon: const Icon(Icons.map_outlined, color: _rose),
            label: const Text(
              'Elegir en mapa',
              style: TextStyle(color: _rose, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
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
}

class _AddressSuggestion {
  const _AddressSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double? latitude;
  final double? longitude;
}

class _PasoLocationPreview extends StatefulWidget {
  const _PasoLocationPreview({
    required this.ubicacion,
    this.ubicacionLat,
    this.ubicacionLng,
  });

  final String ubicacion;
  final double? ubicacionLat;
  final double? ubicacionLng;

  @override
  State<_PasoLocationPreview> createState() => _PasoLocationPreviewState();
}

class _PasoLocationPreviewState extends State<_PasoLocationPreview> {
  LatLng? _point;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.ubicacionLat != null && widget.ubicacionLng != null) {
      _point = LatLng(widget.ubicacionLat!, widget.ubicacionLng!);
      _loading = false;
      return;
    }
    _resolvePoint();
  }

  Future<void> _resolvePoint() async {
    final parsed = _parseCoords(widget.ubicacion);
    if (parsed != null) {
      if (!mounted) return;
      setState(() {
        _point = parsed;
        _loading = false;
      });
      return;
    }

    try {
      final result = await locationFromAddress(widget.ubicacion);
      if (!mounted) return;
      if (result.isNotEmpty) {
        setState(() {
          _point = LatLng(result.first.latitude, result.first.longitude);
        });
      }
    } catch (_) {
      // Si falla geocoding, se mantiene fallback con botón externo.
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
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

  Future<void> _openExternalMap() async {
    Uri uri;
    if (_point != null) {
      uri = Uri.parse(
        'https://www.google.com/maps?q=${_point!.latitude},${_point!.longitude}',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.ubicacion)}',
      );
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de mapas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.ubicacion,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const SizedBox(
            height: 86,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: _rose),
            ),
          )
        else if (_point != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 110,
              child: FlutterMap(
                options: MapOptions(initialCenter: _point!, initialZoom: 14),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nuestrolugarseguro.app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point!,
                        width: 32,
                        height: 32,
                        child: const Icon(
                          Icons.location_on,
                          color: _rose,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _openExternalMap,
            icon: const Icon(Icons.map_outlined, size: 18, color: _rose),
            label: const Text('Abrir mapa', style: TextStyle(color: _rose)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.pink.shade100),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
