// lib/screens/memories.dart
import 'package:flutter/material.dart';
import '../utils/animations.dart';
import '../utils/colors.dart';
import '../models/cita.dart';
import '../services/cita_service.dart';
import 'checklist.dart';

class ExperienceMenuScreen extends StatefulWidget {
  const ExperienceMenuScreen({super.key});

  @override
  State<ExperienceMenuScreen> createState() => _ExperienceMenuScreenState();
}

class _ExperienceMenuScreenState extends State<ExperienceMenuScreen> {
  // ── Categorías ─────────────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Parques',
      'icono': Icons.forest,
      'tipo': 'parque',
      'emoji': '🌳',
      'color': Color(0xFF66BB6A),
    },
    {
      'nombre': 'Museos',
      'icono': Icons.museum,
      'tipo': 'museo',
      'emoji': '🏛️',
      'color': Color(0xFF5C6BC0),
    },
    {
      'nombre': 'Conciertos',
      'icono': Icons.confirmation_number,
      'tipo': 'concierto',
      'emoji': '🎵',
      'color': Color(0xFFE91E63),
    },
    {
      'nombre': 'Pueblos',
      'icono': Icons.holiday_village,
      'tipo': 'pueblo',
      'emoji': '🏘️',
      'color': Color(0xFFFF7043),
    },
    {
      'nombre': 'Países',
      'icono': Icons.public,
      'tipo': 'pais',
      'emoji': '✈️',
      'color': Color(0xFF26C6DA),
    },
    {
      'nombre': 'Restaurantes',
      'icono': Icons.restaurant,
      'tipo': 'restaurante',
      'emoji': '🍽️',
      'color': Color(0xFFFFCA28),
    },
  ];

  // ── Estado ─────────────────────────────────────────────────────────────────
  // Guardamos las citas en el state para no re-fetchear al navegar de regreso.
  List<Cita>? _citas;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCitas();
  }

  Future<void> _loadCitas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // getCitas() usa cache, así que la 2ª llamada es instantánea
      final citas = await ApiService().getCitas();
      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Nuestras Aventuras',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.violeta),
            onPressed: () => _loadCitas(),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.violeta),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCitas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final citas = _citas!;

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
        final Color color = cat['color'] as Color;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            createRoute(
              AdventureListScreen(
                cita: Cita(
                  nombre: 'nombre',
                  descripcion: 'descripcion',
                  categoria: 'categoria',
                  presupuesto: 'presupuesto',
                  tiempo: 0,
                  link: 'link',
                  typeLocation: cat['tipo'] as String,
                ),
                citas: citas,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      cat['emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cat['nombre'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // Cuenta cuántos lugares hay de este tipo
                  '${citas.where((c) => c.typeLocation == cat['tipo']).length} lugares',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
