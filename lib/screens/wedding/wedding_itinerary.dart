// lib/screens/wedding_itinerary.dart
import 'package:flutter/material.dart';
import '../../models/boda.dart';
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              paso.titulo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _rose,
                              ),
                            ),
                            Text(
                              paso.hora,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
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
            Text('No se pudo cargar el itinerario', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadItinerario, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  void _mostrarAgregar(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final horaCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
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
                          const SnackBar(content: Text('No se pudo agregar el paso')),
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
}
