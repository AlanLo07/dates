// lib/screens/wedding/wedding_look.dart
import 'package:flutter/material.dart';
import '../../models/boda.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);
const List<String> _personas = ['Ella', 'Él'];

class WeddingLookScreen extends StatefulWidget {
  const WeddingLookScreen({super.key});
  @override
  State<WeddingLookScreen> createState() => _WeddingLookScreenState();
}

class _WeddingLookScreenState extends State<WeddingLookScreen> {
  final WeddingService _service = WeddingService();
  final List<LookBoda> _items = [];
  String? _bodaId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLooks();
  }

  Future<void> _loadLooks() async {
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
      final looks = await _service.getLooks(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _items
          ..clear()
          ..addAll(looks);
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

  double get _totalGastado =>
      _items.where((i) => i.comprado).fold(0, (s, i) => s + i.precio);

  Map<String, List<LookBoda>> get _grouped {
    final m = <String, List<LookBoda>>{};
    for (final p in _personas) {
      m[p] = _items.where((i) => i.persona == p).toList();
    }
    return m;
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Look', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _rose),
            onPressed: _loadLooks,
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comprado hasta ahora',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        _fmt(_totalGastado),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _rose,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final persona in _personas) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          persona == 'Ella'
                              ? Icons.woman_rounded
                              : Icons.man_rounded,
                          size: 16,
                          color: _rose,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          persona,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _rose,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_grouped[persona]!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 22, bottom: 8),
                      child: Text(
                        'Sin prendas agregadas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    )
                  else
                    ..._grouped[persona]!.map((it) => _buildCard(it)),
                  const SizedBox(height: 10),
                ],
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
            const Icon(Icons.error_outline, color: _rose, size: 42),
            const SizedBox(height: 10),
            Text(
              'No se pudo cargar el look',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadLooks,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(LookBoda it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Checkbox(
            value: it.comprado,
            activeColor: _rose,
            onChanged: (v) async {
              final bodaId = _bodaId;
              if (bodaId == null) return;
              final prev = it.comprado;
              setState(() => it.comprado = v ?? false);
              try {
                await _service.updateLook(bodaId, it);
              } catch (_) {
                if (!mounted) return;
                setState(() => it.comprado = prev);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo actualizar el look'),
                  ),
                );
              }
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  it.prenda,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: it.comprado ? TextDecoration.lineThrough : null,
                    color: it.comprado ? Colors.grey : Colors.black87,
                  ),
                ),
                Text(
                  [
                    if (it.tienda.isNotEmpty) it.tienda,
                    if (it.talla.isNotEmpty) 'Talla ${it.talla}',
                    if (it.precio > 0) _fmt(it.precio),
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _rose),
            onPressed: () => _mostrarEditar(context, it),
          ),
        ],
      ),
    );
  }

  void _mostrarEditar(BuildContext context, LookBoda item) {
    final prendaCtrl = TextEditingController(text: item.prenda);
    final tiendaCtrl = TextEditingController(text: item.tienda);
    final tallaCtrl = TextEditingController(text: item.talla);
    final precioCtrl = TextEditingController(
      text: item.precio.toStringAsFixed(0),
    );
    final notasCtrl = TextEditingController(text: item.notas);
    String persona = item.persona;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Editar prenda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _rose,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: _personas.map((p) {
                    final selected = persona == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => persona = p),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _rose : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prendaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Prenda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tiendaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tienda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tallaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Talla',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: precioCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Precio',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notasCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final bodaId = _bodaId;
                    if (bodaId == null || prendaCtrl.text.trim().isEmpty)
                      return;

                    final prev = LookBoda(
                      id: item.id,
                      persona: item.persona,
                      prenda: item.prenda,
                      tienda: item.tienda,
                      talla: item.talla,
                      precio: item.precio,
                      comprado: item.comprado,
                      notas: item.notas,
                    );

                    setState(() {
                      item.persona = persona;
                      item.prenda = prendaCtrl.text.trim();
                      item.tienda = tiendaCtrl.text.trim();
                      item.talla = tallaCtrl.text.trim();
                      item.precio = double.tryParse(precioCtrl.text) ?? 0;
                      item.notas = notasCtrl.text.trim();
                    });

                    _service.updateLook(bodaId, item).catchError((_) {
                      if (!mounted) return null;
                      setState(() {
                        item.persona = prev.persona;
                        item.prenda = prev.prenda;
                        item.tienda = prev.tienda;
                        item.talla = prev.talla;
                        item.precio = prev.precio;
                        item.comprado = prev.comprado;
                        item.notas = prev.notas;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo editar el look'),
                        ),
                      );
                    });

                    Navigator.pop(context);
                  },
                  child: const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarAgregar(BuildContext context) {
    final prendaCtrl = TextEditingController();
    final tiendaCtrl = TextEditingController();
    final tallaCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    String persona = 'Ella';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nueva prenda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _rose,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: _personas.map((p) {
                    final selected = persona == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setLocal(() => persona = p),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _rose : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            p,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prendaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Prenda',
                    hintText: 'Vestido, Traje, Zapatos...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tiendaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Tienda (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tallaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Talla',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: precioCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Precio',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (prendaCtrl.text.trim().isEmpty) return;
                    final bodaId = _bodaId;
                    if (bodaId == null) return;
                    final nuevo = LookBoda(
                      id: '',
                      persona: persona,
                      prenda: prendaCtrl.text.trim(),
                      tienda: tiendaCtrl.text.trim(),
                      talla: tallaCtrl.text.trim(),
                      precio: double.tryParse(precioCtrl.text) ?? 0,
                    );

                    _service
                        .createLook(bodaId, nuevo)
                        .then((creado) {
                          if (!mounted) return;
                          setState(() => _items.add(creado));
                        })
                        .catchError((_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo agregar el look'),
                            ),
                          );
                        });
                    Navigator.pop(context);
                  },
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
