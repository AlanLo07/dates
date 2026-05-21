// lib/screens/wedding_itinerary.dart
import 'package:flutter/material.dart';
import '../models/boda.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingItineraryScreen extends StatefulWidget {
  const WeddingItineraryScreen({super.key});
  @override
  State<WeddingItineraryScreen> createState() => _WeddingItineraryScreenState();
}

class _WeddingItineraryScreenState extends State<WeddingItineraryScreen> {
  final List<PasoBoda> _pasos = [
    PasoBoda(
      id: '1',
      titulo: 'Ceremonia religiosa',
      hora: '17:00',
      nota: 'Iglesia de San Francisco',
      emoji: '💒',
    ),
    PasoBoda(
      id: '2',
      titulo: 'Sesión de fotos',
      hora: '18:30',
      nota: 'Jardín del venue',
      emoji: '📸',
    ),
    PasoBoda(
      id: '3',
      titulo: 'Coctel de bienvenida',
      hora: '19:00',
      nota: 'Terraza principal',
      emoji: '🥂',
    ),
    PasoBoda(
      id: '4',
      titulo: 'Cena',
      hora: '20:00',
      nota: 'Salón principal',
      emoji: '🍽️',
    ),
    PasoBoda(
      id: '5',
      titulo: 'Primer baile',
      hora: '21:30',
      nota: 'Can\'t Help Falling in Love',
      emoji: '💃',
    ),
    PasoBoda(
      id: '6',
      titulo: 'Vals con padres',
      hora: '21:45',
      nota: '',
      emoji: '🌹',
    ),
    PasoBoda(
      id: '7',
      titulo: 'Fiesta',
      hora: '22:00',
      nota: 'DJ hasta las 2am',
      emoji: '🎉',
    ),
    PasoBoda(
      id: '8',
      titulo: 'Lanzamiento del ramo',
      hora: '00:30',
      nota: '',
      emoji: '💐',
    ),
  ];

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
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregar(context),
          ),
        ],
      ),
      body: ListView.builder(
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
                  setState(() {
                    _pasos.add(
                      PasoBoda(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        titulo: tituloCtrl.text.trim(),
                        hora: horaCtrl.text.trim(),
                        nota: notaCtrl.text.trim(),
                      ),
                    );
                    _pasos.sort((a, b) => a.hora.compareTo(b.hora));
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
