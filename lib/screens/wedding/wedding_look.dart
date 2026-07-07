// lib/screens/wedding/wedding_look.dart
import 'package:flutter/material.dart';
import '../../models/boda.dart';

const Color _rose = Color(0xFFE91E63);
const List<String> _personas = ['Ella', 'Él'];

class WeddingLookScreen extends StatefulWidget {
  const WeddingLookScreen({super.key});
  @override
  State<WeddingLookScreen> createState() => _WeddingLookScreenState();
}

class _WeddingLookScreenState extends State<WeddingLookScreen> {
  final List<LookBoda> _items = [
    LookBoda(id: '1', persona: 'Ella', prenda: 'Vestido', precio: 18000),
    LookBoda(id: '2', persona: 'Él', prenda: 'Traje', precio: 9000),
  ];

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
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregar(context),
          ),
        ],
      ),
      body: ListView(
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                    persona == 'Ella' ? Icons.woman_rounded : Icons.man_rounded,
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
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

  Widget _buildCard(LookBoda it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: CheckboxListTile(
        value: it.comprado,
        activeColor: _rose,
        onChanged: (v) => setState(() => it.comprado = v ?? false),
        title: Text(
          it.prenda,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: it.comprado ? TextDecoration.lineThrough : null,
            color: it.comprado ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          [
            if (it.tienda.isNotEmpty) it.tienda,
            if (it.talla.isNotEmpty) 'Talla ${it.talla}',
            if (it.precio > 0) _fmt(it.precio),
          ].join(' · '),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    setState(() {
                      _items.add(
                        LookBoda(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          persona: persona,
                          prenda: prendaCtrl.text.trim(),
                          tienda: tiendaCtrl.text.trim(),
                          talla: tallaCtrl.text.trim(),
                          precio: double.tryParse(precioCtrl.text) ?? 0,
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
