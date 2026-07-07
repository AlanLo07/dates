// lib/screens/wedding/wedding_gifts.dart
import 'package:flutter/material.dart';
import 'models/wedding_models.dart';

const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

class WeddingGiftsScreen extends StatefulWidget {
  const WeddingGiftsScreen({super.key});

  @override
  State<WeddingGiftsScreen> createState() => _WeddingGiftsScreenState();
}

class _WeddingGiftsScreenState extends State<WeddingGiftsScreen> {
  late List<Regalo> _regalos;
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _regalos = [
      Regalo(
        id: '1',
        nombre: 'Juego de ollas premium',
        descripcion: 'Set de 10 piezas, marca Tefal',
        precio: 2500,
        enlace: 'https://example.com/ollas',
        adquirido: true,
        compradorNombre: 'Maria Garcia',
      ),
      Regalo(
        id: '2',
        nombre: 'Lámpara de piso moderna',
        descripcion: 'Diseño minimalista, blanca',
        precio: 1800,
        enlace: 'https://example.com/lampara',
      ),
      Regalo(
        id: '3',
        nombre: 'Cámara Instax',
        descripcion: 'Cámara instantánea, color rose',
        precio: 4500,
        enlace: 'https://example.com/instax',
        adquirido: true,
        compradorNombre: 'Los Tíos',
      ),
      Regalo(
        id: '4',
        nombre: 'Plantas y macetas decorativas',
        descripcion: 'Set de 5 plantas con macetas',
        precio: 1200,
      ),
      Regalo(
        id: '5',
        nombre: 'Sistema de sonido Bluetooth',
        descripcion: 'Altavoz portátil de alta calidad',
        precio: 3200,
        adquirido: true,
        compradorNombre: 'Juan',
      ),
    ];
  }

  List<Regalo> get _regalosFilterados {
    if (_filtro == 'Adquiridos') {
      return _regalos.where((r) => r.adquirido).toList();
    }
    if (_filtro == 'Pendientes') {
      return _regalos.where((r) => !r.adquirido).toList();
    }
    return _regalos;
  }

  double get _presupuestoTotal => _regalos.fold(0, (s, r) => s + r.precio);
  double get _presupuestoCubierto =>
      _regalos.where((r) => r.adquirido).fold(0, (s, r) => s + r.precio);
  double get _porcentajeCubierto => _presupuestoTotal == 0
      ? 0
      : (_presupuestoCubierto / _presupuestoTotal).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _roseLight,
      appBar: AppBar(
        title: const Text('🎁 Mesa de Regalos', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregarRegalo(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 🟢 Resumen superior
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '\$${_presupuestoTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _rose,
                                ),
                              ),
                              const Text(
                                'Presupuesto total',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '\$${_presupuestoCubierto.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                'Cubierto',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${(_porcentajeCubierto * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _rose,
                                ),
                              ),
                              const Text(
                                'Progreso',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _porcentajeCubierto,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(Colors.green[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🟢 Filtros
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Todos'),
                  _buildFilterChip('Pendientes'),
                  _buildFilterChip('Adquiridos'),
                ],
              ),
            ),
          ),

          // 🟢 Lista de regalos
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildRegaloCard(_regalosFilterados[i]),
                childCount: _regalosFilterados.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filtro == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filtro = label),
        selectedColor: _rose,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRegaloCard(Regalo regalo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: regalo.adquirido ? Colors.green[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.card_giftcard,
            color: regalo.adquirido ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          regalo.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(regalo.descripcion),
            const SizedBox(height: 4),
            Text(
              '\$${regalo.precio.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: _rose),
            ),
            if (regalo.adquirido && regalo.compradorNombre != null)
              Text(
                '✓ ${regalo.compradorNombre}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: () => _marcarAdquirido(regalo),
              child: Text(
                regalo.adquirido ? '✓ Desmarcar' : '☐ Marcar adquirido',
              ),
            ),
            const PopupMenuItem(child: Text('✏️ Editar')),
            const PopupMenuItem(
              child: Text('🗑️ Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _marcarAdquirido(Regalo regalo) {
    setState(() {
      final index = _regalos.indexWhere((r) => r.id == regalo.id);
      if (index != -1) {
        _regalos[index] = Regalo(
          id: regalo.id,
          nombre: regalo.nombre,
          descripcion: regalo.descripcion,
          precio: regalo.precio,
          enlace: regalo.enlace,
          imagen: regalo.imagen,
          adquirido: !regalo.adquirido,
          compradorNombre: regalo.compradorNombre,
          notas: regalo.notas,
        );
      }
    });
  }

  void _mostrarAgregarRegalo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar regalo'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Nombre del regalo'),
              ),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Descripción')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Precio')),
              SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(hintText: 'Enlace (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
