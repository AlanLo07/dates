import 'package:flutter/material.dart';
import '../../models/boda.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingGuestsScreen extends StatefulWidget {
  const WeddingGuestsScreen({super.key});
  @override
  State<WeddingGuestsScreen> createState() => _WeddingGuestsScreenState();
}

class _WeddingGuestsScreenState extends State<WeddingGuestsScreen> {
  // TODO: reemplazar con datos de la API
  final List<Invitado> _invitados = [
    Invitado(
      id: '1',
      nombre: 'Familia Martínez',
      grupo: 'Familia',
      personas: 4,
      rsvp: RsvpStatus.confirmado,
    ),
    Invitado(
      id: '2',
      nombre: 'Carlos & Sofía',
      grupo: 'Amigos',
      personas: 2,
      rsvp: RsvpStatus.confirmado,
    ),
    Invitado(
      id: '3',
      nombre: 'Laura Sánchez',
      grupo: 'Amigos',
      personas: 1,
      rsvp: RsvpStatus.pendiente,
    ),
  ];

  int get _confirmados => _invitados
      .where((i) => i.rsvp == RsvpStatus.confirmado)
      .fold(0, (s, i) => s + i.personas);
  int get _total => _invitados.fold(0, (s, i) => s + i.personas);

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
            icon: const Icon(Icons.person_add_outlined, color: _rose),
            onPressed: () => _mostrarAgregarInvitado(context),
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _invitados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _buildInvitadoCard(_invitados[i]),
            ),
          ),
        ],
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
              inv.nombre.substring(0, 1).toUpperCase(),
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
          PopupMenuButton<RsvpStatus>(
            initialValue: inv.rsvp,
            onSelected: (v) => setState(() => inv.rsvp = v),
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
                inv.rsvp.label,
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
                    setState(() {
                      _invitados.add(
                        Invitado(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          nombre: nombreCtrl.text.trim(),
                          grupo: grupoCtrl.text.trim().isEmpty
                              ? 'Amigos'
                              : grupoCtrl.text.trim(),
                          personas: personas,
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
