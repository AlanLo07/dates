// lib/screens/wedding/wedding_menu.dart
import 'package:flutter/material.dart';

import '../../models/boda.dart';
import '../../services/wedding_service.dart';

const Color _green = Color(0xFF388E3C);
const Color _greenLight = Color(0xFFE8F5E9);
const Color _rose = Color(0xFFE91E63);

const List<String> _momentos = [
  'Cóctel',
  'Recepción',
  'Cena',
  'Postre',
  'Madrugada',
];

const List<String> _tipos = [
  'Entrada',
  'Plato fuerte',
  'Guarnición',
  'Postre',
  'Bebida',
  'Snack',
  'Otro',
];

class WeddingMenuScreen extends StatefulWidget {
  const WeddingMenuScreen({super.key});

  @override
  State<WeddingMenuScreen> createState() => _WeddingMenuScreenState();
}

class _WeddingMenuScreenState extends State<WeddingMenuScreen> {
  final WeddingService _service = WeddingService();
  final List<MenuBodaItem> _items = [];

  String? _bodaId;
  bool _loading = true;
  String? _error;
  String _filtroMomento = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
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
      final items = await _service.getMenuItems(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _items
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

  List<MenuBodaItem> get _filtrados {
    if (_filtroMomento == 'Todos') return _items;
    return _items.where((i) => i.momento == _filtroMomento).toList();
  }

  Map<String, List<MenuBodaItem>> get _agrupados {
    final map = <String, List<MenuBodaItem>>{};
    for (final item in _filtrados) {
      map.putIfAbsent(item.momento, () => []).add(item);
    }
    return map;
  }

  void _mostrarAgregar() {
    _mostrarFormulario(null);
  }

  Future<void> _mostrarFormulario(MenuBodaItem? existente) async {
    final bodaId = _bodaId;
    if (bodaId == null) return;

    final nombreCtrl = TextEditingController(text: existente?.nombre ?? '');
    final descCtrl = TextEditingController(text: existente?.descripcion ?? '');
    String momento = existente?.momento ?? _momentos.first;
    String tipo = existente?.tipo.isNotEmpty == true
        ? existente!.tipo
        : _tipos.first;
    bool esVegetariano = existente?.esVegetariano ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  existente == null ? 'Agregar platillo' : 'Editar platillo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: momento,
                  decoration: const InputDecoration(
                    labelText: 'Momento',
                    border: OutlineInputBorder(),
                  ),
                  items: _momentos
                      .map(
                        (m) => DropdownMenuItem(value: m, child: Text(m)),
                      )
                      .toList(),
                  onChanged: (v) => setSheet(() => momento = v ?? momento),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                  items: _tipos
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (v) => setSheet(() => tipo = v ?? tipo),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: esVegetariano,
                  onChanged: (v) => setSheet(() => esVegetariano = v),
                  title: const Text('🌱 Vegetariano'),
                  activeColor: _green,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nombre = nombreCtrl.text.trim();
                      if (nombre.isEmpty) return;

                      Navigator.pop(ctx);

                      try {
                        if (existente == null) {
                          final nuevo = MenuBodaItem(
                            id: '',
                            nombre: nombre,
                            momento: momento,
                            descripcion: descCtrl.text.trim(),
                            tipo: tipo,
                            esVegetariano: esVegetariano,
                          );
                          final creado =
                              await _service.createMenuItem(bodaId, nuevo);
                          if (mounted) {
                            setState(() => _items.add(creado));
                          }
                        } else {
                          existente.nombre = nombre;
                          existente.momento = momento;
                          existente.descripcion = descCtrl.text.trim();
                          existente.tipo = tipo;
                          existente.esVegetariano = esVegetariano;
                          final actualizado =
                              await _service.updateMenuItem(bodaId, existente);
                          final idx =
                              _items.indexWhere((i) => i.id == existente.id);
                          if (idx != -1 && mounted) {
                            setState(() => _items[idx] = actualizado);
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
                      backgroundColor: _green,
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
      backgroundColor: _greenLight,
      appBar: AppBar(
        title: const Text(
          'Menú',
          style: TextStyle(color: _green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _green),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _green),
            onPressed: _loadMenu,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarAgregar,
        backgroundColor: _green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
          ? _buildError()
          : Column(
              children: [
                _buildFiltros(),
                Expanded(
                  child: _items.isEmpty
                      ? _buildEmpty()
                      : _buildLista(),
                ),
              ],
            ),
    );
  }

  Widget _buildFiltros() {
    final opciones = ['Todos', ..._momentos];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: opciones.map((m) {
            final sel = _filtroMomento == m;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(m),
                selected: sel,
                onSelected: (_) => setState(() => _filtroMomento = m),
                selectedColor: _green,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLista() {
    final grupos = _agrupados;
    if (grupos.isEmpty) {
      return const Center(
        child: Text(
          'Sin platillos para este filtro',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grupos.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _green,
                ),
              ),
            ),
            ...entry.value.map((item) => _buildCard(item)),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCard(MenuBodaItem item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: _greenLight,
          child: Text(
            item.esVegetariano ? '🌱' : '🍽️',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          item.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.tipo.isNotEmpty)
              Text(item.tipo, style: const TextStyle(fontSize: 12)),
            if (item.descripcion.isNotEmpty)
              Text(
                item.descripcion,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_rounded, color: _green, size: 20),
          onPressed: () => _mostrarFormulario(item),
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
            Icons.restaurant_menu_rounded,
            size: 72,
            color: _green.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'El menú está vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _green.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para agregar el primer platillo',
            style: TextStyle(color: _green.withValues(alpha: 0.5)),
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
              onPressed: _loadMenu,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: _green),
            ),
          ],
        ),
      ),
    );
  }
}
