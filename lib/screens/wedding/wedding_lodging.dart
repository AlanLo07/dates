// lib/screens/wedding/wedding_lodging.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/boda.dart';
import '../../services/wedding_service.dart';

const Color _blue = Color(0xFF1976D2);
const Color _blueLight = Color(0xFFE3F2FD);
const Color _rose = Color(0xFFE91E63);

class WeddingLodgingScreen extends StatefulWidget {
  const WeddingLodgingScreen({super.key});

  @override
  State<WeddingLodgingScreen> createState() => _WeddingLodgingScreenState();
}

class _WeddingLodgingScreenState extends State<WeddingLodgingScreen> {
  final WeddingService _service = WeddingService();
  final List<HospedajeBoda> _hospedajes = [];

  String? _bodaId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHospedajes();
  }

  Future<void> _loadHospedajes() async {
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
      final items = await _service.getHospedajes(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _hospedajes
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _mostrarAgregar() => _mostrarFormulario(null);

  Future<void> _mostrarFormulario(HospedajeBoda? existente) async {
    final bodaId = _bodaId;
    if (bodaId == null) return;

    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final dirCtrl = TextEditingController(text: existente?.direccion ?? '');
    final contactoCtrl = TextEditingController(
      text: existente?.contacto ?? '',
    );
    final checkInCtrl = TextEditingController(text: existente?.checkIn ?? '');
    final checkOutCtrl = TextEditingController(
      text: existente?.checkOut ?? '',
    );
    final mapaCtrl = TextEditingController(text: existente?.mapaUrl ?? '');
    final notaCtrl = TextEditingController(text: existente?.nota ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existente == null ? 'Agregar hospedaje' : 'Editar hospedaje',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del hotel / lugar *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dirCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contacto / Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: checkInCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Check-in',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: checkOutCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Check-out',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mapaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Link Google Maps / URL',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map_rounded),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nombre = nombreCtrl.text.trim();
                      if (nombre.isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        if (existente == null) {
                          final nuevo = HospedajeBoda(
                            id: '',
                            nombre: nombre,
                            direccion: dirCtrl.text.trim(),
                            contacto: contactoCtrl.text.trim(),
                            checkIn: checkInCtrl.text.trim(),
                            checkOut: checkOutCtrl.text.trim(),
                            mapaUrl: mapaCtrl.text.trim(),
                            nota: notaCtrl.text.trim(),
                          );
                          final creado =
                              await _service.createHospedaje(bodaId, nuevo);
                          if (mounted) {
                            setState(() => _hospedajes.add(creado));
                          }
                        } else {
                          existente.nombre = nombre;
                          existente.direccion = dirCtrl.text.trim();
                          existente.contacto = contactoCtrl.text.trim();
                          existente.checkIn = checkInCtrl.text.trim();
                          existente.checkOut = checkOutCtrl.text.trim();
                          existente.mapaUrl = mapaCtrl.text.trim();
                          existente.nota = notaCtrl.text.trim();
                          final actualizado = await _service.updateHospedaje(
                            bodaId,
                            existente,
                          );
                          final idx = _hospedajes.indexWhere(
                            (h) => h.id == existente.id,
                          );
                          if (idx != -1 && mounted) {
                            setState(() => _hospedajes[idx] = actualizado);
                          }
                        }
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(existente == null ? 'Agregar' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _blueLight,
      appBar: AppBar(
        title: const Text(
          'Hospedaje',
          style: TextStyle(color: _blue, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _blue),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _blue),
            onPressed: _loadHospedajes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarAgregar,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _error != null
          ? _buildError()
          : _hospedajes.isEmpty
          ? _buildEmpty()
          : _buildLista(),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _hospedajes.length,
      itemBuilder: (_, idx) => _buildCard(_hospedajes[idx]),
    );
  }

  Widget _buildCard(HospedajeBoda h) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hotel_rounded, color: _blue, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    h.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20, color: _blue),
                  onPressed: () => _mostrarFormulario(h),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (h.direccion.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      h.direccion,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (h.checkIn.isNotEmpty || h.checkOut.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  if (h.checkIn.isNotEmpty)
                    Text(
                      'In: ${h.checkIn}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (h.checkIn.isNotEmpty && h.checkOut.isNotEmpty)
                    const Text(
                      '  ·  ',
                      style: TextStyle(color: Colors.grey),
                    ),
                  if (h.checkOut.isNotEmpty)
                    Text(
                      'Out: ${h.checkOut}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ],
            if (h.contacto.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    h.contacto,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (h.nota.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                h.nota,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (h.mapaUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _launchUrl(h.mapaUrl),
                  icon: const Icon(Icons.map_rounded, size: 16),
                  label: const Text('Ver en mapa'),
                  style: TextButton.styleFrom(foregroundColor: _blue),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hotel_rounded,
            size: 72,
            color: _blue.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin opciones de hospedaje',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _blue.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para agregar un hotel o lugar',
            style: TextStyle(color: _blue.withValues(alpha: 0.5)),
          ),
        ],
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
            const Icon(Icons.error_outline, color: _rose, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _rose),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHospedajes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: _blue),
            ),
          ],
        ),
      ),
    );
  }
}
