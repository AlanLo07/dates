import 'package:flutter/material.dart';
import '../models/boda.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingChecklistScreen extends StatefulWidget {
  const WeddingChecklistScreen({super.key});
  @override
  State<WeddingChecklistScreen> createState() => _WeddingChecklistScreenState();
}

class _WeddingChecklistScreenState extends State<WeddingChecklistScreen> {
  final List<TareaBoda> _tareas = [
    TareaBoda(
      id: '1',
      titulo: 'Elegir el venue',
      categoria: 'Venue',
      completada: true,
    ),
    TareaBoda(id: '2', titulo: 'Contratar fotógrafo', categoria: 'Fotos'),
    TareaBoda(id: '3', titulo: 'Elegir pastel', categoria: 'Catering'),
    TareaBoda(id: '4', titulo: 'Enviar invitaciones', categoria: 'Invitados'),
    TareaBoda(id: '5', titulo: 'Confirmar DJ / Música', categoria: 'Música'),
    TareaBoda(id: '6', titulo: 'Flores y decoración', categoria: 'Flores'),
    TareaBoda(
      id: '7',
      titulo: 'Vestido y traje',
      categoria: 'Look',
      completada: true,
    ),
    TareaBoda(id: '8', titulo: 'Reservar luna de miel', categoria: 'Viaje'),
  ];

  Map<String, List<TareaBoda>> get _grouped {
    final m = <String, List<TareaBoda>>{};
    for (final t in _tareas) {
      m.putIfAbsent(t.categoria, () => []).add(t);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final done = _tareas.where((t) => t.completada).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Checklist', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregar(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progreso
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done de ${_tareas.length} tareas completadas',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _tareas.isEmpty ? 0 : done / _tareas.length,
                    minHeight: 8,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(_rose),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _rose,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ...entry.value.map(
                      (t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: t.completada,
                          activeColor: _rose,
                          onChanged: (v) =>
                              setState(() => t.completada = v ?? false),
                          title: Text(
                            t.titulo,
                            style: TextStyle(
                              decoration: t.completada
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: t.completada
                                  ? Colors.grey
                                  : Colors.black87,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarAgregar(BuildContext context) {
    final ctrl = TextEditingController();
    String cat = 'General';
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
              'Nueva tarea',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _rose,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Tarea',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => cat = v,
              decoration: InputDecoration(
                labelText: 'Categoría',
                hintText: 'Venue, Catering, Flores…',
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
                  if (ctrl.text.trim().isEmpty) return;
                  setState(() {
                    _tareas.add(
                      TareaBoda(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        titulo: ctrl.text.trim(),
                        categoria: cat.trim().isEmpty ? 'General' : cat.trim(),
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
}
