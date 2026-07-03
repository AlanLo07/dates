// lib/screens/wedding/widgets/proveedor_list_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/boda.dart';

const Color _rose = Color(0xFFE91E63);

class ProveedorListScreen extends StatefulWidget {
  final String titulo;
  final String emojiHeader;
  final List<ProveedorBoda> seed;
  final List<String> categoriaOptions;
  final String contactoLabel; // ej: 'Contacto' o 'Teléfono'

  const ProveedorListScreen({
    super.key,
    required this.titulo,
    required this.emojiHeader,
    required this.seed,
    required this.categoriaOptions,
    this.contactoLabel = 'Contacto',
  });

  @override
  State<ProveedorListScreen> createState() => _ProveedorListScreenState();
}

class _ProveedorListScreenState extends State<ProveedorListScreen> {
  late List<ProveedorBoda> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.seed);
  }

  Future<void> _abrirLink(String link) async {
    if (link.isEmpty) return;
    final uri = Uri.parse(link);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  String _fmt(double v) => v == 0 ? '' : '\$${v.toStringAsFixed(0)}';

  Map<String, List<ProveedorBoda>> get _grouped {
    final m = <String, List<ProveedorBoda>>{};
    for (final it in _items) {
      m.putIfAbsent(it.categoria, () => []).add(it);
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: Text(widget.titulo, style: const TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: _rose), onPressed: () => _mostrarAgregar(context)),
        ],
      ),
      body: _items.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _rose, fontSize: 13),
                      ),
                    ),
                    ...entry.value.map((it) => _buildCard(it)),
                    const SizedBox(height: 6),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.emojiHeader, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('Agrega la primera opción', style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildCard(ProveedorBoda it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(it.nombre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              GestureDetector(
                onTap: () => _cambiarEstado(it),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: it.estado.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    it.estado.label,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: it.estado.color),
                  ),
                ),
              ),
            ],
          ),
          if (it.contacto.isNotEmpty || it.costo > 0) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (it.contacto.isNotEmpty)
                  Text('${widget.contactoLabel}: ${it.contacto}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                if (it.costo > 0)
                  Text(_fmt(it.costo), style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          if (it.notas.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(it.notas, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ],
          if (it.link.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _abrirLink(it.link),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.open_in_new_rounded, size: 14, color: _rose),
                  const SizedBox(width: 4),
                  const Text('Ver más', style: TextStyle(fontSize: 12, color: _rose, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _cambiarEstado(ProveedorBoda it) {
    setState(() {
      final next = EstadoProveedor.values[(it.estado.index + 1) % EstadoProveedor.values.length];
      it.estado = next;
    });
  }

  void _mostrarAgregar(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final contactoCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    String categoria = widget.categoriaOptions.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nueva opción', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _rose)),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(labelText: 'Nombre', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.categoriaOptions.map((c) {
                    final selected = categoria == c;
                    return GestureDetector(
                      onTap: () => setLocal(() => categoria = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? _rose : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey.shade700),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactoCtrl,
                  decoration: InputDecoration(labelText: widget.contactoLabel, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Costo (opcional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(labelText: 'Link (opcional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notasCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: 'Notas (opcional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (nombreCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _items.add(ProveedorBoda(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreCtrl.text.trim(),
                        categoria: categoria,
                        contacto: contactoCtrl.text.trim(),
                        link: linkCtrl.text.trim(),
                        costo: double.tryParse(costoCtrl.text) ?? 0,
                        notas: notasCtrl.text.trim(),
                      ));
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