import 'package:flutter/material.dart';
import '../../models/boda.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingGuestsScreen extends StatefulWidget {
  const WeddingGuestsScreen({super.key});
  @override
  State<WeddingGuestsScreen> createState() => _WeddingGuestsScreenState();
}

class _WeddingGuestsScreenState extends State<WeddingGuestsScreen> {
  final WeddingService _service = WeddingService();
  final bool _canConfirmRsvp = true;
  final List<Invitado> _invitados = [];
  String? _bodaId;
  bool _loading = true;
  String? _error;
  String _query = '';
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _loadInvitados();
  }

  Future<void> _loadInvitados() async {
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
      final invitados = await _service.getInvitados(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _invitados
          ..clear()
          ..addAll(invitados);
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

  int get _confirmados => _invitados
      .where((i) => i.rsvp == RsvpStatus.confirmado)
      .fold(0, (s, i) => s + i.personas);
  int get _total => _invitados.fold(0, (s, i) => s + i.personas);

  List<Invitado> get _filtrados {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _invitados;
    return _invitados
        .where(
          (i) =>
              i.nombre.toLowerCase().contains(q) ||
              i.grupo.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Invitado> get _visibles {
    final list = _filtrados;
    if (list.length <= _visibleCount) return list;
    return list.take(_visibleCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Invitados', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _rose),
            onPressed: _loadInvitados,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: _rose),
            onPressed: () => _mostrarAgregarInvitado(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : _error != null
          ? _buildError()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value;
                        _visibleCount = 20;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar invitado o grupo',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // Resumen
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStat(
                        '$_confirmados',
                        'Confirmados',
                        const Color(0xFF1B5E20),
                        const Color(0xFFE8F5E9),
                      ),
                      const SizedBox(width: 10),
                      _buildStat(
                        '${_invitados.where((i) => i.rsvp == RsvpStatus.pendiente).length}',
                        'Pendientes',
                        const Color(0xFF4A148C),
                        const Color(0xFFF3E5F5),
                      ),
                      const SizedBox(width: 10),
                      _buildStat(
                        '$_total',
                        'Total personas',
                        _rose,
                        const Color(0xFFFCE4EC),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      for (final inv in _visibles) ...[
                        _buildInvitadoCard(inv),
                        const SizedBox(height: 10),
                      ],
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
            Text(
              'No se pudieron cargar invitados',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadInvitados,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    String value,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: textColor.withOpacity(.7)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitadoCard(Invitado inv) {
    final colors = {
      RsvpStatus.confirmado: Colors.green,
      RsvpStatus.pendiente: Colors.orange,
      RsvpStatus.noVa: Colors.red,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFCE4EC),
            child: Text(
              inv.nombre.trim().isNotEmpty
                  ? inv.nombre.trim().substring(0, 1).toUpperCase()
                  : '?',
              style: const TextStyle(color: _rose, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${inv.grupo} · ${inv.personas} ${inv.personas == 1 ? 'persona' : 'personas'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: _rose),
            onPressed: () => _mostrarEditarInvitado(context, inv),
          ),
          PopupMenuButton<RsvpStatus>(
            initialValue: inv.rsvp,
            onSelected: (v) async {
              if (!_canConfirmRsvp) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Solo los novios pueden confirmar invitados.',
                    ),
                  ),
                );
                return;
              }
              final bodaId = _bodaId;
              if (bodaId == null) return;
              final previous = inv.rsvp;
              setState(() => inv.rsvp = v);
              try {
                await _service.updateInvitadoRsvp(bodaId, inv.id, v);
              } catch (_) {
                if (!mounted) return;
                setState(() => inv.rsvp = previous);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo actualizar RSVP')),
                );
              }
            },
            itemBuilder: (_) => RsvpStatus.values
                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors[inv.rsvp]!.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _canConfirmRsvp ? inv.rsvp.label : '${inv.rsvp.label} 🔒',
                style: TextStyle(
                  fontSize: 12,
                  color: colors[inv.rsvp],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarEditarInvitado(BuildContext context, Invitado invitado) {
    final nombreCtrl = TextEditingController(text: invitado.nombre);
    final grupoCtrl = TextEditingController(text: invitado.grupo);
    int personas = invitado.personas;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Editar invitado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _rose,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grupoCtrl,
                decoration: InputDecoration(
                  labelText: 'Grupo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Personas:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (personas > 1) setLocal(() => personas--);
                    },
                  ),
                  Text(
                    '$personas',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _rose),
                    onPressed: () => setLocal(() => personas++),
                  ),
                ],
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
                    if (bodaId == null || nombreCtrl.text.trim().isEmpty)
                      return;

                    final prevNombre = invitado.nombre;
                    final prevGrupo = invitado.grupo;
                    final prevPersonas = invitado.personas;

                    setState(() {
                      invitado.nombre = nombreCtrl.text.trim();
                      invitado.grupo = grupoCtrl.text.trim().isEmpty
                          ? 'Amigos'
                          : grupoCtrl.text.trim();
                      invitado.personas = personas;
                    });

                    _service.updateInvitado(bodaId, invitado).catchError((_) {
                      if (!mounted) return null;
                      setState(() {
                        invitado.nombre = prevNombre;
                        invitado.grupo = prevGrupo;
                        invitado.personas = prevPersonas;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo editar invitado'),
                        ),
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
    );
  }

  void _mostrarAgregarInvitado(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final grupoCtrl = TextEditingController(text: 'Amigos');
    int personas = 1;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Agregar invitado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _rose,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: grupoCtrl,
                decoration: InputDecoration(
                  labelText: 'Grupo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Personas:'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      if (personas > 1) setLocal(() => personas--);
                    },
                  ),
                  Text(
                    '$personas',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: _rose),
                    onPressed: () => setLocal(() => personas++),
                  ),
                ],
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
                    if (nombreCtrl.text.trim().isEmpty) return;
                    final bodaId = _bodaId;
                    if (bodaId == null) return;
                    final nuevo = Invitado(
                      id: '',
                      nombre: nombreCtrl.text.trim(),
                      grupo: grupoCtrl.text.trim().isEmpty
                          ? 'Amigos'
                          : grupoCtrl.text.trim(),
                      personas: personas,
                    );
                    _service
                        .createInvitado(bodaId, nuevo)
                        .then((creado) {
                          if (!mounted) return;
                          setState(() => _invitados.add(creado));
                        })
                        .catchError((_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo agregar invitado'),
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
      ),
    );
  }
}
