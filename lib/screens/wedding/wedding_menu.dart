// lib/screens/wedding/wedding_menu.dart
import 'package:flutter/material.dart';
import 'models/wedding_models.dart';

const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

class WeddingMenuScreen extends StatefulWidget {
  const WeddingMenuScreen({super.key});

  @override
  State<WeddingMenuScreen> createState() => _WeddingMenuScreenState();
}

class _WeddingMenuScreenState extends State<WeddingMenuScreen> {
  late List<MenuBoda> _menus;
  bool _expandirTodo = false;

  @override
  void initState() {
    super.initState();
    _menus = [
      MenuBoda(
        id: '1',
        nombre: 'Entrada',
        platos: [
          PlatoMenu(
            id: '1-1',
            nombre: 'Tabla de quesos y embutidos',
            descripcion: 'Selección gourmet con frutas frescas',
            esVegetariano: true,
          ),
          PlatoMenu(
            id: '1-2',
            nombre: 'Camarones al ajillo',
            descripcion: 'Camarones frescos con ajo y limón',
          ),
        ],
      ),
      MenuBoda(
        id: '2',
        nombre: 'Plato Principal',
        platos: [
          PlatoMenu(
            id: '2-1',
            nombre: 'Filete Mignon',
            descripcion: 'Corte premium con salsa de vino tinto',
          ),
          PlatoMenu(
            id: '2-2',
            nombre: 'Salmón a la mantequilla',
            descripcion: 'Con salsa cítrica y vegetales del día',
          ),
          PlatoMenu(
            id: '2-3',
            nombre: 'Ratatouille gourmet',
            descripcion: 'Opción vegetariana con queso de cabra',
            esVegetariano: true,
            esSinGluten: true,
          ),
        ],
      ),
      MenuBoda(
        id: '3',
        nombre: 'Postres',
        platos: [
          PlatoMenu(
            id: '3-1',
            nombre: 'Pastel de chocolate',
            descripcion: 'Torta de 3 pisos con ganache',
          ),
          PlatoMenu(
            id: '3-2',
            nombre: 'Fresas con champagne',
            descripcion: 'Fresas frescas bañadas en champagne',
            esVegetariano: true,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _roseLight,
      appBar: AppBar(
        title: const Text('Menú de Boda', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregarMenu(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _menus.length,
        itemBuilder: (_, i) => _buildMenuCard(_menus[i]),
      ),
    );
  }

  Widget _buildMenuCard(MenuBoda menu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          menu.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _rose,
          ),
        ),
        children: [
          ...menu.platos.map((plato) => _buildPlatoTile(plato)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar plato'),
              onPressed: () => _mostrarAgregarPlato(context, menu),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatoTile(PlatoMenu plato) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plato.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      plato.descripcion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    child: Text('Editar'),
                  ),
                  const PopupMenuItem(
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              if (plato.esVegetariano)
                Chip(
                  label: const Text('🌱 Vegetariano'),
                  backgroundColor: Colors.green[100],
                  labelStyle: const TextStyle(fontSize: 11),
                ),
              if (plato.esSinGluten)
                Chip(
                  label: const Text('🌾 Sin gluten'),
                  backgroundColor: Colors.yellow[100],
                  labelStyle: const TextStyle(fontSize: 11),
                ),
              if (plato.alergenos.isNotEmpty)
                Chip(
                  label: Text('⚠️ ${plato.alergenos.join(', ')}'),
                  backgroundColor: Colors.red[100],
                  labelStyle: const TextStyle(fontSize: 10),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _mostrarAgregarMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva sección'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Ej: Bebidas, Aperitivos'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _mostrarAgregarPlato(BuildContext context, MenuBoda menu) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar plato'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(hintText: 'Nombre')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Descripción')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
