import 'package:flutter/material.dart';

import '../../models/checklist.dart';
import '../../models/fecha.dart';
import '../../services/checklists_service.dart';
import '../checklist/checklist_detail_screen.dart';

class EventChecklistEditor extends StatefulWidget {
  final EventoImportante evento;
  final ValueChanged<EventoImportante> onChanged;

  const EventChecklistEditor({
    super.key,
    required this.evento,
    required this.onChanged,
  });

  @override
  State<EventChecklistEditor> createState() => _EventChecklistEditorState();
}

class _EventChecklistEditorState extends State<EventChecklistEditor> {
  final _service = ChecklistsService();
  final _titulo = TextEditingController(text: 'Preparativos');
  final List<TextEditingController> _items = [];
  final List<bool> _comprados = [];
  late final EventoImportante _original;
  List<ChecklistBoard> _boards = [];
  String _seleccion = 'none';
  String? _error;
  bool _loading = true;

  bool get _tieneLegacy => _original.checklistId == null &&
      _original.checklist.titulo == null &&
      _original.checklist.items.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final evento = _original = widget.evento;
    if (evento.checklist.titulo != null) {
      _titulo.text = evento.checklist.titulo!;
    }
    _seleccion = evento.checklist.titulo != null
        ? 'new'
        : evento.checklistId != null
        ? 'id:${evento.checklistId}'
        : evento.checklist.items.isNotEmpty ? 'legacy' : 'none';
    for (final item in evento.checklist.items) {
      _items.add(TextEditingController(text: item.nombre));
      _comprados.add(item.incluido);
    }
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _titulo.dispose();
    for (final controller in _items) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.seedDefaults();
      final boards = await _service.getChecklists();
      if (mounted) setState(() => _boards = boards);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _emit() {
    final original = _original;
    if (_seleccion == 'legacy') {
      widget.onChanged(original);
    } else if (_seleccion == 'new') {
      widget.onChanged(original.copyWith(
        checklist: ChecklistEvento(
          titulo: _titulo.text.trim(),
          items: [
            for (var index = 0; index < _items.length; index++)
              if (_items[index].text.trim().isNotEmpty)
                ItemChecklist(
                  nombre: _items[index].text.trim(),
                  incluido: _comprados[index],
                ),
          ],
        ),
      ));
    } else {
      widget.onChanged(original.copyWith(
        checklistId: _seleccion == 'none' ? null : _seleccion.substring(3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkedId = _seleccion.startsWith('id:')
        ? _seleccion.substring(3) : null;
    final opciones = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'none', child: Text('Sin checklist')),
      const DropdownMenuItem(value: 'new', child: Text('Crear nuevo checklist')),
      if (_tieneLegacy)
        const DropdownMenuItem(
          value: 'legacy', child: Text('Conservar lista antigua'),
        ),
      for (final board in _boards)
        DropdownMenuItem(value: 'id:${board.id}', child: Text(board.titulo)),
      if (linkedId != null && !_boards.any((board) => board.id == linkedId))
        DropdownMenuItem(value: _seleccion, child: Text('Checklist $linkedId')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_seleccion),
          initialValue: _seleccion,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Checklist'),
          items: opciones,
          onChanged: (value) {
            if (value == null) return;
            setState(() => _seleccion = value);
            _emit();
          },
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_error!),
            trailing: IconButton(
              tooltip: 'Reintentar carga',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ),
        if (linkedId != null) EventChecklistLink(checklistId: linkedId),
        if (_seleccion == 'legacy')
          for (final item in _original.checklist.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.incluido ? Icons.check_circle : Icons.circle_outlined),
              title: Text(item.nombre),
            ),
        if (_seleccion == 'new') ...[
          TextField(
            controller: _titulo,
            decoration: const InputDecoration(labelText: 'Titulo del checklist'),
            onChanged: (_) => _emit(),
          ),
          for (var index = 0; index < _items.length; index++)
            Row(
              children: [
                Checkbox(
                  value: _comprados[index],
                  onChanged: (value) {
                    setState(() => _comprados[index] = value ?? false);
                    _emit();
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _items[index],
                    decoration: const InputDecoration(labelText: 'Item'),
                    onChanged: (_) => _emit(),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar item',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _items.removeAt(index).dispose();
                      _comprados.removeAt(index);
                    });
                    _emit();
                  },
                ),
              ],
            ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar item'),
            onPressed: _items.length >= 98 ? null : () {
              setState(() {
                _items.add(TextEditingController());
                _comprados.add(false);
              });
              _emit();
            },
          ),
        ],
      ],
    );
  }
}

class EventChecklistLink extends StatefulWidget {
  final String checklistId;

  const EventChecklistLink({super.key, required this.checklistId});

  @override
  State<EventChecklistLink> createState() => _EventChecklistLinkState();
}

class _EventChecklistLinkState extends State<EventChecklistLink> {
  final _service = ChecklistsService();
  late Future<ChecklistBoard> _board;

  @override
  void initState() {
    super.initState();
    _board = _service.getChecklist(widget.checklistId);
  }

  @override
  void didUpdateWidget(covariant EventChecklistLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checklistId != widget.checklistId) {
      _board = _service.getChecklist(widget.checklistId);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _board = _service.getChecklist(widget.checklistId));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChecklistBoard>(
      future: _board,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final missing = error is ChecklistApiException && error.statusCode == 404;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(missing ? 'El checklist vinculado ya no existe' : '$error'),
            subtitle: missing
                ? const Text('Edita la cita para desvincularlo o seleccionar otro.')
                : null,
            trailing: IconButton(
              tooltip: 'Reintentar carga',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          );
        }
        final board = snapshot.data!;
        final completos = board.items.where((item) => item.comprado).length;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.checklist),
          title: Text(board.titulo),
          subtitle: Text('$completos / ${board.items.length} - Estado compartido'),
          trailing: IconButton(
            tooltip: 'Abrir checklist',
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ChecklistDetailScreen(checklistId: widget.checklistId),
              ));
              if (mounted) _reload();
            },
          ),
        );
      },
    );
  }
}