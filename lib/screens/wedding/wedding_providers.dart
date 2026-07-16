import 'package:flutter/material.dart';

import '../../models/boda.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

class WeddingProvidersScreen extends StatefulWidget {
  const WeddingProvidersScreen({super.key});

  @override
  State<WeddingProvidersScreen> createState() => _WeddingProvidersScreenState();
}

class _WeddingProvidersScreenState extends State<WeddingProvidersScreen> {
  final WeddingService _service = WeddingService();
  final List<ProveedorBoda> _proveedores = [];

  String? _bodaId;
  bool _loading = true;
  String? _error;
  String _filtro = 'Todos';
  String _query = '';
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _loadProveedores();
  }

  Future<void> _loadProveedores() async {
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

      final proveedores = await _service.getProveedores(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _proveedores
          ..clear()
          ..addAll(proveedores);
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

  List<ProveedorBoda> get _filtrados {
    Iterable<ProveedorBoda> list = _proveedores;
    if (_filtro == 'Pendientes') {
      list = list.where((p) => p.estado == EstadoProveedor.pendiente);
    } else if (_filtro == 'Confirmados') {
      list = list.where((p) => p.estado == EstadoProveedor.confirmado);
    } else if (_filtro == 'Pagados') {
      list = list.where((p) => p.estado == EstadoProveedor.pagado);
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where(
        (p) =>
            p.nombre.toLowerCase().contains(q) ||
            p.categoria.toLowerCase().contains(q) ||
            p.contacto.toLowerCase().contains(q),
      );
    }

    return list.toList();
  }

  List<ProveedorBoda> get _visibles {
    if (_filtrados.length <= _visibleCount) return _filtrados;
    return _filtrados.take(_visibleCount).toList();
  }

  double get _total => _proveedores.fold(0, (s, p) => s + p.costo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _roseLight,
      appBar: AppBar(
        title: const Text('Proveedores', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _rose),
            onPressed: _loadProveedores,
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
          : Column(
              children: [
                _buildResumen(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                        _visibleCount = 20;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar proveedor o categoría',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _chipFiltro('Todos'),
                      _chipFiltro('Pendientes'),
                      _chipFiltro('Confirmados'),
                      _chipFiltro('Pagados'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtrados.isEmpty
                      ? _buildEmpty()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ..._visibles.map(_buildItem),
                            if (_filtrados.length > _visibleCount)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _visibleCount += 20;
                                      });
                                    },
                                    icon: const Icon(Icons.expand_more),
                                    label: const Text('Cargar más'),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
            const Icon(Icons.error_outline, color: _rose, size: 42),
            const SizedBox(height: 10),
            Text('No se pudieron cargar proveedores', style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadProveedores, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _miniStat('Total', _proveedores.length.toString(), _rose),
          _miniStat(
            'Pendientes',
            _proveedores.where((e) => e.estado == EstadoProveedor.pendiente).length.toString(),
            const Color(0xFFFB8C00),
          ),
          _miniStat('Costo', '\$${_total.toStringAsFixed(0)}', _rose),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _chipFiltro(String text) {
    final selected = _filtro == text;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: selected,
        onSelected: (_) => setState(() => _filtro = text),
        selectedColor: _rose,
        label: Text(
          text,
          style: TextStyle(color: selected ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👨‍💼', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('Sin proveedores registrados', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildItem(ProveedorBoda p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.estado.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.business_center_outlined, color: p.estado.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${p.categoria} · ${p.contacto.isEmpty ? 'Sin contacto' : p.contacto}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (p.costo > 0)
                  Text(
                    '\$${p.costo.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          PopupMenuButton<EstadoProveedor>(
            initialValue: p.estado,
            onSelected: (estado) => _cambiarEstado(p, estado),
            itemBuilder: (_) => EstadoProveedor.values
                .map(
                  (e) => PopupMenuItem<EstadoProveedor>(
                    value: e,
                    child: Text(e.label),
                  ),
                )
                .toList(),
            child: Chip(
              label: Text(p.estado.label, style: TextStyle(color: p.estado.color)),
              backgroundColor: p.estado.color.withOpacity(0.1),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _rose),
            onPressed: () => _mostrarEditar(context, p),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(ProveedorBoda proveedor, EstadoProveedor estado) async {
    final bodaId = _bodaId;
    if (bodaId == null) return;

    final previo = proveedor.estado;
    setState(() => proveedor.estado = estado);

    try {
      await _service.updateProveedor(bodaId, proveedor);
    } catch (_) {
      if (!mounted) return;
      setState(() => proveedor.estado = previo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar estado de proveedor')),
      );
    }
  }

  void _mostrarAgregar(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final categoriaCtrl = TextEditingController();
    final contactoCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    final costoCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nuevo proveedor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _rose),
                ),
                const SizedBox(height: 14),
                _textField(nombreCtrl, 'Nombre'),
                const SizedBox(height: 10),
                _textField(categoriaCtrl, 'Categoría'),
                const SizedBox(height: 10),
                _textField(contactoCtrl, 'Contacto'),
                const SizedBox(height: 10),
                _textField(linkCtrl, 'Link (opcional)'),
                const SizedBox(height: 10),
                _textField(costoCtrl, 'Costo', keyboard: TextInputType.number),
                const SizedBox(height: 10),
                _textField(notasCtrl, 'Notas (opcional)'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (nombreCtrl.text.trim().isEmpty) return;
                      final bodaId = _bodaId;
                      if (bodaId == null) return;

                      final nuevo = ProveedorBoda(
                        id: '',
                        nombre: nombreCtrl.text.trim(),
                        categoria: categoriaCtrl.text.trim().isEmpty ? 'General' : categoriaCtrl.text.trim(),
                        contacto: contactoCtrl.text.trim(),
                        link: linkCtrl.text.trim(),
                        costo: double.tryParse(costoCtrl.text) ?? 0,
                        estado: EstadoProveedor.pendiente,
                        notas: notasCtrl.text.trim(),
                      );

                      _service
                          .createProveedor(bodaId, nuevo)
                          .then((creado) {
                            if (!mounted) return;
                            setState(() => _proveedores.add(creado));
                          })
                          .catchError((_) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No se pudo agregar proveedor')),
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
        ),
      ),
    );
  }

  void _mostrarEditar(BuildContext context, ProveedorBoda proveedor) {
    final nombreCtrl = TextEditingController(text: proveedor.nombre);
    final categoriaCtrl = TextEditingController(text: proveedor.categoria);
    final contactoCtrl = TextEditingController(text: proveedor.contacto);
    final linkCtrl = TextEditingController(text: proveedor.link);
    final costoCtrl = TextEditingController(text: proveedor.costo.toStringAsFixed(0));
    final notasCtrl = TextEditingController(text: proveedor.notas);
    EstadoProveedor estado = proveedor.estado;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Editar proveedor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _rose,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _textField(nombreCtrl, 'Nombre'),
                  const SizedBox(height: 10),
                  _textField(categoriaCtrl, 'Categoría'),
                  const SizedBox(height: 10),
                  _textField(contactoCtrl, 'Contacto'),
                  const SizedBox(height: 10),
                  _textField(linkCtrl, 'Link'),
                  const SizedBox(height: 10),
                  _textField(costoCtrl, 'Costo', keyboard: TextInputType.number),
                  const SizedBox(height: 10),
                  _textField(notasCtrl, 'Notas'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<EstadoProveedor>(
                    value: estado,
                    items: EstadoProveedor.values
                        .map(
                          (e) => DropdownMenuItem<EstadoProveedor>(
                            value: e,
                            child: Text(e.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => estado = v);
                    },
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        final bodaId = _bodaId;
                        if (bodaId == null || nombreCtrl.text.trim().isEmpty) return;

                        final prev = ProveedorBoda(
                          id: proveedor.id,
                          nombre: proveedor.nombre,
                          categoria: proveedor.categoria,
                          contacto: proveedor.contacto,
                          link: proveedor.link,
                          costo: proveedor.costo,
                          estado: proveedor.estado,
                          notas: proveedor.notas,
                        );

                        setState(() {
                          proveedor.nombre = nombreCtrl.text.trim();
                          proveedor.categoria = categoriaCtrl.text.trim().isEmpty
                              ? 'General'
                              : categoriaCtrl.text.trim();
                          proveedor.contacto = contactoCtrl.text.trim();
                          proveedor.link = linkCtrl.text.trim();
                          proveedor.costo = double.tryParse(costoCtrl.text) ?? 0;
                          proveedor.notas = notasCtrl.text.trim();
                          proveedor.estado = estado;
                        });

                        _service.updateProveedor(bodaId, proveedor).catchError((_) {
                          if (!mounted) return;
                          setState(() {
                            proveedor.nombre = prev.nombre;
                            proveedor.categoria = prev.categoria;
                            proveedor.contacto = prev.contacto;
                            proveedor.link = prev.link;
                            proveedor.costo = prev.costo;
                            proveedor.notas = prev.notas;
                            proveedor.estado = prev.estado;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo editar proveedor')),
                          );
                        });

                        Navigator.pop(context);
                      },
                      child: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
