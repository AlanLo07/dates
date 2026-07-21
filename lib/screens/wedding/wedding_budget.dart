// lib/screens/wedding/wedding_budget.dart
import 'package:flutter/material.dart';
import '../../models/boda.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingBudgetScreen extends StatefulWidget {
  const WeddingBudgetScreen({super.key});
  @override
  State<WeddingBudgetScreen> createState() => _WeddingBudgetScreenState();
}

class _WeddingBudgetScreenState extends State<WeddingBudgetScreen> {
  final WeddingService _service = WeddingService();
  final List<GastoBoda> _gastos = [];
  String? _bodaId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGastos();
  }

  Future<void> _loadGastos() async {
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
      final gastos = await _service.getGastos(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _gastos
          ..clear()
          ..addAll(gastos);
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

  double get _totalEstimado => _gastos.fold(0, (s, g) => s + g.estimado);
  double get _totalPagado => _gastos.fold(0, (s, g) => s + g.pagado);
  double get _progreso =>
      _totalEstimado == 0 ? 0 : (_totalPagado / _totalEstimado).clamp(0, 1);

  Map<String, List<GastoBoda>> get _grouped {
    final m = <String, List<GastoBoda>>{};
    for (final g in _gastos) {
      m.putIfAbsent(g.categoria, () => []).add(g);
    }
    return m;
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Presupuesto', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _rose),
            onPressed: _loadGastos,
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
                _buildSummaryCard(),
                Expanded(
                  child: _gastos.isEmpty
                      ? _buildEmpty()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: _grouped.entries.map((entry) {
                            final subtotalEstimado = entry.value.fold<double>(
                              0,
                              (s, g) => s + g.estimado,
                            );
                            final subtotalPagado = entry.value.fold<double>(
                              0,
                              (s, g) => s + g.pagado,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _rose,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '${_fmt(subtotalPagado)} / ${_fmt(subtotalEstimado)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...entry.value.map((g) => _buildGastoCard(g)),
                              ],
                            );
                          }).toList(),
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
            Text(
              'No se pudieron cargar los gastos',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadGastos,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _rose.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryStat(
                'Estimado',
                _fmt(_totalEstimado),
                Colors.grey.shade700,
              ),
              _summaryStat('Pagado', _fmt(_totalPagado), _rose),
              _summaryStat(
                'Restante',
                _fmt((_totalEstimado - _totalPagado).clamp(0, double.infinity)),
                const Color(0xFFFB8C00),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _progreso,
              minHeight: 10,
              backgroundColor: const Color(0xFFFCE4EC),
              valueColor: const AlwaysStoppedAnimation<Color>(_rose),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_progreso * 100).toStringAsFixed(0)}% pagado',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGastoCard(GastoBoda g) {
    final pendiente = g.estimado - g.pagado;
    final pagadoCompleto = pendiente <= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pagadoCompleto
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              pagadoCompleto
                  ? Icons.check_circle_outline
                  : Icons.hourglass_bottom_rounded,
              color: pagadoCompleto ? const Color(0xFF2E7D32) : _rose,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.concepto,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  pagadoCompleto
                      ? 'Pagado por completo · ${_fmt(g.estimado)}'
                      : '${_fmt(g.pagado)} de ${_fmt(g.estimado)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _mostrarEditarPago(g),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💰', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Agrega el primer gasto',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _mostrarEditarPago(GastoBoda g) {
    final ctrl = TextEditingController(text: g.pagado.toStringAsFixed(0));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                g.concepto,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _rose,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Estimado: ${_fmt(g.estimado)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monto pagado',
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
                  final val = double.tryParse(ctrl.text) ?? g.pagado;
                  final bodaId = _bodaId;
                  if (bodaId == null) return;
                  final prev = g.pagado;
                  setState(() => g.pagado = val);
                  _service.updateGasto(bodaId, g).catchError((_) {
                    if (!mounted) return null;
                    setState(() => g.pagado = prev);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo actualizar el gasto'),
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAgregar(BuildContext context) {
    final conceptoCtrl = TextEditingController();
    final categoriaCtrl = TextEditingController();
    final estimadoCtrl = TextEditingController();
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
              'Nuevo gasto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _rose,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: conceptoCtrl,
              decoration: InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoriaCtrl,
              decoration: InputDecoration(
                labelText: 'Categoría',
                hintText: 'Venue, Catering...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: estimadoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto estimado',
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
                  if (conceptoCtrl.text.trim().isEmpty) return;
                  final bodaId = _bodaId;
                  if (bodaId == null) return;
                  final nuevo = GastoBoda(
                    id: '',
                    concepto: conceptoCtrl.text.trim(),
                    categoria: categoriaCtrl.text.trim().isEmpty
                        ? 'General'
                        : categoriaCtrl.text.trim(),
                    estimado: double.tryParse(estimadoCtrl.text) ?? 0,
                    pagado: 0,
                  );
                  _service
                      .createGasto(bodaId, nuevo)
                      .then((creado) {
                        if (!mounted) return;
                        setState(() => _gastos.add(creado));
                      })
                      .catchError((_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No se pudo agregar el gasto'),
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
