// lib/screens/wedding/wedding_providers.dart
import 'package:flutter/material.dart';
import 'models/wedding_models.dart';

const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

class WeddingProvidersScreen extends StatefulWidget {
  const WeddingProvidersScreen({super.key});

  @override
  State<WeddingProvidersScreen> createState() => _WeddingProvidersScreenState();
}

class _WeddingProvidersScreenState extends State<WeddingProvidersScreen> {
  late List<Proveedor> _proveedores;
  String _filtro = 'Todos';

  @override
  void initState() {
    super.initState();
    _proveedores = [
      Proveedor(
        id: '1',
        nombre: 'Juan García - Fotógrafo',
        servicio: 'Fotógrafo',
        telefono: '+34 622 345 678',
        email: 'juan@fotografia.com',
        website: 'https://juanfoto.com',
        precio: 15000,
        descripcion: 'Fotógrafo profesional con 10 años de experiencia',
        rating: 4.8,
        fotos: ['https://via.placeholder.com/300x200'],
        contratado: true,
        fechaContratacion: DateTime(2024, 3, 15),
        telefonosEmergencia: ['+34 622 345 679'],
        notas: 'Contactar con 2 semanas de anticipación',
      ),
      Proveedor(
        id: '2',
        nombre: 'Catering Elite',
        servicio: 'Catering',
        telefono: '+34 632 456 789',
        email: 'info@cateringelite.com',
        website: 'https://cateringelite.com',
        precio: 60000,
        descripcion: 'Catering gourmet para eventos',
        rating: 4.5,
        contratado: true,
        fechaContratacion: DateTime(2024, 4, 10),
        telefonosEmergencia: ['+34 632 456 790'],
      ),
      Proveedor(
        id: '3',
        nombre: 'Flores y Diseño',
        servicio: 'Flores',
        telefono: '+34 643 567 890',
        email: 'flores@diseño.com',
        website: 'https://floresydiseño.com',
        precio: 8500,
        descripcion: 'Decoración floral personalizada',
        rating: 4.7,
        contratado: false,
      ),
      Proveedor(
        id: '4',
        nombre: 'DJ Carlos',
        servicio: 'Música',
        telefono: '+34 654 678 901',
        email: 'carlos@djcarlos.com',
        precio: 5000,
        descripcion: 'DJ profesional con equipo de sonido premium',
        rating: 4.6,
        contratado: true,
        fechaContratacion: DateTime(2024, 5, 1),
      ),
    ];
  }

  List<Proveedor> get _proveedoresFiltrados {
    if (_filtro == 'Contratados') {
      return _proveedores.where((p) => p.contratado).toList();
    }
    if (_filtro == 'Pendientes') {
      return _proveedores.where((p) => !p.contratado).toList();
    }
    return _proveedores;
  }

  String get _serviciosFiltro => _proveedores.map((p) => p.servicio).toSet().join(', ');

  double get _costoTotal => _proveedores.fold(0, (s, p) => s + p.precio);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _roseLight,
      appBar: AppBar(
        title: const Text('👨‍💼 Proveedores', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregarProveedor(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: _rose),
            onPressed: () => _exportarCSV(),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                _proveedores.length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _rose,
                                ),
                              ),
                              const Text(
                                'Total proveedores',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _proveedores.where((p) => p.contratado).length.toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                'Contratados',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '\$${_costoTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _rose,
                                ),
                              ),
                              const Text(
                                'Costo total',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
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
                  _buildFilterChip('Contratados'),
                  _buildFilterChip('Pendientes'),
                ],
              ),
            ),
          ),

          // 🟢 Lista de proveedores
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _buildProveedorCard(_proveedoresFiltrados[i]),
                childCount: _proveedoresFiltrados.length,
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

  Widget _buildProveedorCard(Proveedor proveedor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proveedor.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    proveedor.servicio,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (proveedor.contratado)
              Chip(
                label: const Text('✓ Contratado'),
                backgroundColor: Colors.green[100],
                labelStyle: const TextStyle(fontSize: 11, color: Colors.green),
              )
            else
              Chip(
                label: const Text('⏳ Pendiente'),
                backgroundColor: Colors.orange[100],
                labelStyle: const TextStyle(fontSize: 11, color: Colors.orange),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 Contacto
                _buildSection('📞 Contacto', [
                  Row(
                    children: [
                      Expanded(child: Text('Teléfono: ${proveedor.telefono}')),
                      IconButton(
                        icon: const Icon(Icons.phone, size: 18, color: _rose),
                        onPressed: () {
                          // TODO: Implementar llamada
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Email: ${proveedor.email}')),
                      IconButton(
                        icon: const Icon(Icons.email, size: 18, color: _rose),
                        onPressed: () {
                          // TODO: Implementar email
                        },
                      ),
                    ],
                  ),
                  if (proveedor.website != null)
                    Row(
                      children: [
                        Expanded(child: Text('Web: ${proveedor.website}')),
                        IconButton(
                          icon: const Icon(Icons.language, size: 18, color: _rose),
                          onPressed: () {
                            // TODO: Abrir navegador
                          },
                        ),
                      ],
                    ),
                ]),

                const SizedBox(height: 12),

                // 🟢 Detalles
                _buildSection('💰 Detalles', [
                  Text('Precio: \$${proveedor.precio.toStringAsFixed(0)}'),
                  if (proveedor.rating > 0)
                    Row(
                      children: [
                        const Text('Rating: '),
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < proveedor.rating.toInt() ? Icons.star : Icons.star_outline,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                        Text(' (${proveedor.rating}/5)'),
                      ],
                    ),
                  if (proveedor.descripcion != null)
                    Text('Descripción: ${proveedor.descripcion}'),
                ]),

                const SizedBox(height: 12),

                // 🟢 Fechas
                if (proveedor.fechaContratacion != null)
                  _buildSection('📅 Información de Contrato', [
                    Text(
                      'Contratado: ${proveedor.fechaContratacion!.toString().split(' ')[0]}',
                    ),
                  ]),

                const SizedBox(height: 12),

                // 🟢 Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!proveedor.contratado)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Contratar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // TODO: Marcar como contratado
                        },
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: _rose),
                      onPressed: () {
                        // TODO: Editar proveedor
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        // TODO: Eliminar proveedor
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _rose,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  void _exportarCSV() {
    final csv = Proveedor.toCSV(_proveedores);
    // 🟢 Aquí iría la lógica para descargar/compartir el CSV
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ CSV preparado para descargar'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Proveedores (CSV)'),
                content: SingleChildScrollView(
                  child: SelectableText(csv),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _mostrarAgregarProveedor(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar proveedor'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(hintText: 'Nombre')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Servicio')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Teléfono')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Email')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Precio')),
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
