import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/finances.dart';
import '../../models/monthly_challenge.dart';
import '../../services/auth_service.dart';
import '../../services/finances_service.dart';
import '../../services/monthly_challenges_service.dart';
import '../../utils/colors.dart';

const Map<String, String> _challengeCategories = {
  'diversion': 'Diversión',
  'actividades_juntos': 'Actividades juntos',
  'comunicacion': 'Comunicación',
  'ahorro': 'Ahorro',
  'otro': 'Otro',
};

class MonthlyChallengesScreen extends StatefulWidget {
  const MonthlyChallengesScreen({super.key});

  @override
  State<MonthlyChallengesScreen> createState() => _MonthlyChallengesScreenState();
}

class _MonthlyChallengesScreenState extends State<MonthlyChallengesScreen> {
  final MonthlyChallengesService _service = MonthlyChallengesService();
  final FinancesService _financesService = FinancesService();
  MonthlyChallengeState? _state;
  MonthlyChallengeCoupon? _coupon;
  List<MonthlyChallengeFavorite> _favorites = [];
  bool _loading = true;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      MonthlyChallengeState state;
      try {
        state = await _service.getCurrent();
      } on MonthlyChallengesApiException catch (error) {
        if (error.statusCode != 403) rethrow;
        await _initializeMembership();
        state = await _service.getCurrent();
      }

      MonthlyChallengeCoupon? coupon;
      if (state.isCompleted) {
        try {
          coupon = (await _service.getCurrentCoupon()).coupon;
        } catch (_) {}
      }
      List<MonthlyChallengeFavorite> favorites = [];
      try {
        favorites = await _service.getFavorites();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _state = state;
        _coupon = coupon;
        _favorites = favorites;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _initializeMembership() async {
    User? first;
    User? second;
    try {
      final couple = await _financesService.getCouple(forceRefresh: true);
      if (couple.user1.email.isNotEmpty && couple.user2.email.isNotEmpty) {
        first = couple.user1;
        second = couple.user2;
      }
    } catch (_) {}

    if (first == null || second == null) {
      final me = await AuthService.instance.getMe();
      if (me == null || me.email.isEmpty) {
        throw const FormatException('No se pudo obtener el correo de la sesión.');
      }
      final partnerEmail = TextEditingController();
      final partnerName = TextEditingController();
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Configurar retos de pareja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tu cuenta: ${me.email}'),
              const SizedBox(height: 12),
              TextField(
                controller: partnerName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre de tu pareja'),
              ),
              TextField(
                controller: partnerEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo de tu pareja'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (saved != true) {
        partnerEmail.dispose();
        partnerName.dispose();
        throw const FormatException('La configuración de pareja fue cancelada.');
      }
      final email = partnerEmail.text.trim();
      final name = partnerName.text.trim();
      partnerEmail.dispose();
      partnerName.dispose();
      if (email.isEmpty ||
          name.isEmpty ||
          email.toLowerCase() == me.email.toLowerCase()) {
        throw const FormatException('Ingresa un nombre y correo válido de tu pareja.');
      }
      first = User(email: me.email, name: me.name.isEmpty ? me.email : me.name);
      second = User(email: email, name: name);
    }
    try {
      await _service.initializeCouple(
        user1Email: first.email,
        user2Email: second.email,
        user1Name: first.name,
        user2Name: second.name,
      );
    } on MonthlyChallengesApiException catch (error) {
      if (error.statusCode != 409) rethrow;
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
    } on MonthlyChallengesApiException catch (error) {
      if (error.statusCode == 409) {
        await _load(showLoading: false);
        _showMessage('El estado cambió. Actualicé el reto; revisa antes de intentarlo otra vez.', error: true);
      } else {
        _showMessage(error.message, error: true);
      }
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _applyState(Future<MonthlyChallengeState> Function() request) async {
    await _runAction(() async {
      final state = await request();
      if (!mounted) return;
      setState(() => _state = state);
      if (state.isCompleted) await _load(showLoading: false);
    });
  }

  Future<void> _showProposalMenu({MonthlyChallengeContent? replacement}) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: const Text('Crear propuesta'),
              onTap: () => Navigator.pop(context, 'custom'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: const Text('Elegir del catálogo'),
              onTap: () => Navigator.pop(context, 'catalog'),
            ),
            ListTile(
              leading: const Icon(Icons.shuffle_rounded),
              title: const Text('Pedir una sugerencia aleatoria'),
              onTap: () => Navigator.pop(context, 'random'),
            ),
            if (replacement == null)
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded),
                title: const Text('Usar un favorito'),
                onTap: () => Navigator.pop(context, 'favorites'),
              ),
          ],
        ),
      ),
    );
    if (choice == 'custom') await _showCustomProposal(replacement: replacement);
    if (choice == 'catalog') await _showCatalog(replacement: replacement);
    if (choice == 'random') await _showRandomSuggestion(replacement: replacement);
    if (choice == 'favorites') await _showFavorites();
  }

  Future<void> _showCustomProposal({MonthlyChallengeContent? replacement}) async {
    final titleController = TextEditingController(text: replacement?.title ?? '');
    final descriptionController = TextEditingController(
      text: replacement?.description ?? '',
    );
    var category = replacement?.category ?? 'diversion';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(replacement == null ? 'Proponer reto' : 'Proponer reemplazo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  maxLength: 120,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLength: 600,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: _challengeCategories.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => category = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Proponer'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final title = titleController.text.trim();
      final description = descriptionController.text.trim();
      if (title.isEmpty || description.isEmpty) {
        _showMessage('Completa el título y la descripción.', error: true);
      } else {
        await _runAction(() async {
          final state = replacement == null
              ? await _service.proposeCustom(
                  title: title,
                  description: description,
                  category: category,
                )
              : await _service.replaceActive(
                  content: MonthlyChallengeContent(
                    source: 'custom',
                    title: title,
                    description: description,
                    category: category,
                  ),
                );
          if (mounted) setState(() => _state = state);
          _showMessage('Propuesta compartida con tu pareja.');
        });
      }
    }
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showCatalog({MonthlyChallengeContent? replacement}) async {
    await _runAction(() async {
      final items = await _service.getCatalog();
      if (!mounted) return;
      final selected = await showModalBottomSheet<MonthlyChallengeCatalogItem>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: items.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'El catálogo aún no tiene retos. Puedes crear una propuesta personalizada.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Retos del catálogo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...items.map(
                        (item) => ListTile(
                          title: Text(item.title),
                          subtitle: Text(
                            '${_categoryLabel(item.category)} · ${item.description}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.pop(context, item),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
      if (selected == null) return;
      final state = replacement == null
          ? await _service.proposeCatalog(selected.challengeId)
          : await _service.replaceActive(content: selected);
      if (mounted) setState(() => _state = state);
      _showMessage('Propuesta del catálogo compartida.');
    });
  }

  Future<void> _showRandomSuggestion({MonthlyChallengeContent? replacement}) async {
    await _runAction(() async {
      try {
        final suggestion = await _service.getRandomSuggestion();
        if (!mounted) return;
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sugerencia aleatoria'),
            content: _ChallengeDescription(content: suggestion),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Proponer'),
              ),
            ],
          ),
        );
        if (accepted != true) return;
        final state = replacement == null
            ? await _service.proposeCatalog(suggestion.challengeId)
            : await _service.replaceActive(content: suggestion);
        if (mounted) setState(() => _state = state);
        _showMessage('La sugerencia quedó como propuesta; falta el acuerdo de ambos.');
      } on MonthlyChallengesApiException catch (error) {
        if (error.statusCode == 404) {
          _showMessage('El catálogo todavía no contiene retos activos.', error: true);
        } else {
          rethrow;
        }
      }
    });
  }

  Future<void> _showFavorites() async {
    await _runAction(() async {
      final favorites = await _service.getFavorites();
      if (!mounted) return;
      final selected = await showModalBottomSheet<MonthlyChallengeFavorite>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: favorites.isEmpty
                ? const Center(child: Text('Aún no tienen retos favoritos.'))
                : ListView(
                    children: [
                      for (final favorite in favorites)
                        ListTile(
                          title: Text(favorite.title),
                          subtitle: Text(_categoryLabel(favorite.category)),
                          trailing: IconButton(
                            tooltip: 'Quitar de favoritos',
                            icon: const Icon(Icons.bookmark_remove_outlined),
                            onPressed: () async {
                              await _service.removeFavorite(favorite.favoriteId);
                              if (context.mounted) Navigator.pop(context);
                              if (mounted) {
                                setState(() => _favorites.removeWhere(
                                      (item) => item.favoriteId == favorite.favoriteId,
                                    ));
                              }
                            },
                          ),
                          onTap: () => Navigator.pop(context, favorite),
                        ),
                    ],
                  ),
          ),
        ),
      );
      if (selected == null) return;
      final state = await _proposeFavorite(selected);
      if (mounted) setState(() => _state = state);
      _showMessage('Favorito enviado como propuesta personalizada.');
    });
  }

  Future<void> _toggleFavorite(MonthlyChallengeContent content) async {
    await _runAction(() async {
      try {
        await _service.addFavorite(content);
        final favorites = await _service.getFavorites();
        if (mounted) setState(() => _favorites = favorites);
        _showMessage('Reto guardado en favoritos.');
      } on MonthlyChallengesApiException catch (error) {
        if (error.statusCode == 409) {
          _showMessage('Este reto ya está en favoritos.');
        } else {
          rethrow;
        }
      }
    });
  }

  Future<void> _chooseProposal(MonthlyChallengeProposal proposal) async {
    await _applyState(() => _service.chooseProposal(proposal.proposedBy));
  }

  Future<MonthlyChallengeState> _proposeFavorite(
    MonthlyChallengeFavorite favorite,
  ) => favorite.source == 'catalog' && favorite.catalogChallengeId != null
      ? _service.proposeCatalog(favorite.catalogChallengeId!)
      : _service.proposeCustom(
          title: favorite.title,
          description: favorite.description,
          category: favorite.category,
        );

  Future<void> _requestRandomTieBreak() async {
    final agree = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desempate aleatorio'),
        content: const Text(
          'Tu solicitud cuenta como un voto. El reto aleatorio solo se asigna cuando ambos lo soliciten.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Solicitar')),
        ],
      ),
    );
    if (agree == true) {
      await _applyState(_service.requestRandomTiebreak);
    }
  }

  Future<void> _editActive(MonthlyChallengeContent content) async {
    final titleController = TextEditingController(text: content.title);
    final descriptionController = TextEditingController(text: content.description);
    var category = content.category;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar reto activo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, maxLength: 120, decoration: const InputDecoration(labelText: 'Título')),
                TextField(controller: descriptionController, maxLength: 600, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción')),
                DropdownButtonFormField<String>(
                  value: category,
                  items: _challengeCategories.entries
                      .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => category = value);
                  },
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (saved == true) {
      final fields = <String, String>{};
      final title = titleController.text.trim();
      final description = descriptionController.text.trim();
      if (title.isEmpty || description.isEmpty) {
        _showMessage('Título y descripción son obligatorios.', error: true);
      } else {
        fields.addAll({'title': title, 'description': description, 'category': category});
        await _applyState(() => _service.editActive(fields));
      }
    }
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _cancelActive({required bool replace}) async {
    if (replace) {
      await _showProposalMenu(replacement: _state?.selectedChallenge);
      return;
    }
    final reason = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar reto'),
        content: TextField(
          controller: reason,
          maxLength: 300,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancelar reto')),
        ],
      ),
    );
    if (saved == true) {
      await _applyState(() => _service.cancelActive(reason: reason.text.trim()));
    }
    reason.dispose();
  }

  Future<void> _completeChallenge() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Completaron el reto?'),
        content: const Text('Al confirmar, se registrará quién lo completó y se creará un cupón compartido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Todavía no')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sí, completar')),
        ],
      ),
    );
    if (accepted == true) {
      await _runAction(() async {
        final result = await _service.completeCurrent();
        final current = await _service.getCurrent();
        if (mounted) {
          setState(() {
            _state = current;
            _coupon = result.coupon;
          });
        }
        await _showCoupon(result.coupon, created: result.couponCreated);
      });
    }
  }

  Future<void> _showCoupon(MonthlyChallengeCoupon coupon, {bool created = false}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.card_giftcard_rounded, size: 40, color: AppColors.success),
        title: Text(created ? '¡Reto completado!' : coupon.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(coupon.description, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Recompensa por: ${coupon.sourceChallengeTitle}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Registrado por ${coupon.createdByName}', style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  String _categoryLabel(String category) =>
      _challengeCategories[category] ?? _challengeCategories['otro']!;

  String _monthLabel(String monthKey) {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final date = DateTime.tryParse('${parts[0]}-${parts[1]}-01');
    return date == null ? monthKey : DateFormat('MMMM yyyy', 'es_ES').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFF9),
      appBar: AppBar(
        title: const Text('Reto del mes'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.violeta,
        actions: [
          IconButton(
            tooltip: 'Favoritos',
            onPressed: _loading ? null : _showFavorites,
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : state == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  _monthHeader(state),
                  const SizedBox(height: 14),
                  if (state.isPending) _pendingContent(state),
                  if (state.isAssigned) _assignedContent(state),
                  if (state.isCompleted) _completedContent(state),
                  if (_favorites.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Favoritos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.violeta)),
                        ),
                        TextButton(onPressed: _showFavorites, child: const Text('Ver todos')),
                      ],
                    ),
                    ..._favorites.take(3).map(
                      (favorite) => _FavoriteTile(
                        favorite: favorite,
                        onPropose: () => _applyState(() => _service.proposeCustom(
                              title: favorite.title,
                              description: favorite.description,
                              category: favorite.category,
                            )),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _monthHeader(MonthlyChallengeState state) {
    final statusText = switch (state.status) {
      'PENDING' => 'Por elegir',
      'ASSIGNED' => 'En curso',
      'COMPLETED' => 'Completado',
      _ => state.status,
    };
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.violeta.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFF1EDF8),
            child: Icon(Icons.calendar_month_rounded, color: AppColors.violeta),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_monthLabel(state.monthKey), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                Text('Ciclo ${state.cycle} · $statusText', style: TextStyle(color: Colors.grey.shade700)),
                if (state.isPending && state.deadlineAt != null)
                  Text(
                    'Elección hasta ${DateFormat('d MMM, HH:mm', 'es_ES').format(state.deadlineAt!.toLocal())}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (_working)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }

  Widget _pendingContent(MonthlyChallengeState state) {
    final myProposal = state.proposals.any(
      (proposal) => proposal.proposedBy == state.viewer?.sub,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.handshake_outlined, color: Color(0xFF9A6811)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state.disagreement
                      ? 'Eligieron propuestas distintas. Cambien su elección o pidan ambos el desempate aleatorio.'
                      : 'Elijan juntos una propuesta. El silencio no cuenta como aceptación.',
                  style: const TextStyle(height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                state.proposals.isEmpty ? 'Propongan el reto' : 'Propuestas del mes',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.violeta),
              ),
            ),
            if (state.availableActions.contains('propose') || state.availableActions.contains('updateProposal'))
              IconButton.filledTonal(
                tooltip: myProposal ? 'Cambiar mi propuesta' : 'Proponer reto',
                onPressed: _working ? null : () => _showProposalMenu(),
                icon: const Icon(Icons.add),
              ),
          ],
        ),
        if (state.proposals.isEmpty)
          _emptyPanel('Aún no hay propuestas', 'Cada integrante puede proponer un reto para este mes.', Icons.lightbulb_outline_rounded)
        else
          ...state.proposals.map((proposal) {
            final selectedByMe = state.choices.any(
              (choice) => choice.userSub == state.viewer?.sub && choice.proposedBy == proposal.proposedBy,
            );
            final selectedByPartner = state.choices.any(
              (choice) => choice.userSub != state.viewer?.sub && choice.proposedBy == proposal.proposedBy,
            );
            return _ProposalCard(
              proposal: proposal,
              categoryLabel: _categoryLabel(proposal.category),
              selectedByMe: selectedByMe,
              selectedByPartner: selectedByPartner,
              canChoose: state.availableActions.contains('chooseProposal'),
              canWithdraw: proposal.proposedBy == state.viewer?.sub && state.availableActions.contains('withdrawProposal'),
              working: _working,
              onChoose: () => _chooseProposal(proposal),
              onWithdraw: () => _applyState(_service.withdrawProposal),
              onFavorite: () => _toggleFavorite(proposal),
            );
          }),
        if (state.disagreement && state.availableActions.contains('requestRandomTiebreak')) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _working ? null : _requestRandomTieBreak,
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('Pedir desempate aleatorio'),
            ),
          ),
        ],
        if (state.choices.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Votos registrados: ${state.choices.length} de 2',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }

  Widget _assignedContent(MonthlyChallengeState state) {
    final challenge = state.selectedChallenge;
    if (challenge == null) return const SizedBox.shrink();
    final actions = state.availableActions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChallengeDescription(content: challenge, categoryLabel: _categoryLabel(challenge.category)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _working ? null : () => _toggleFavorite(challenge),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Guardar en favoritos'),
        ),
        if (actions.contains('completeChallenge')) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _working ? null : _completeChallenge,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Marcar como completado'),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (actions.contains('editChallenge'))
              TextButton.icon(
                onPressed: _working ? null : () => _editActive(challenge),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            if (actions.contains('replaceChallenge'))
              TextButton.icon(
                onPressed: _working ? null : () => _cancelActive(replace: true),
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text('Reemplazar'),
              ),
            if (actions.contains('cancelChallenge'))
              TextButton.icon(
                onPressed: _working ? null : () => _cancelActive(replace: false),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancelar reto'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _completedContent(MonthlyChallengeState state) {
    final challenge = state.selectedChallenge;
    return Column(
      children: [
        if (challenge != null) _ChallengeDescription(content: challenge),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFEAF5EF), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.celebration_rounded, color: AppColors.success, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Completado${state.completedByEmail == null ? '' : ' por ${state.completedByEmail}'}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _coupon == null
                ? () => _runAction(() async {
                      final coupon = (await _service.getCurrentCoupon()).coupon;
                      if (mounted) setState(() => _coupon = coupon);
                      await _showCoupon(coupon);
                    })
                : () => _showCoupon(_coupon!),
            icon: const Icon(Icons.card_giftcard_rounded),
            label: Text(_coupon == null ? 'Ver cupón compartido' : _coupon!.title),
          ),
        ),
      ],
    );
  }

  Widget _emptyPanel(String title, String subtitle, IconData icon) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icon, color: AppColors.violeta),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChallengeDescription extends StatelessWidget {
  const _ChallengeDescription({required this.content, this.categoryLabel});

  final MonthlyChallengeContent content;
  final String? categoryLabel;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.violeta.withValues(alpha: 0.12)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryLabel != null)
          Text(categoryLabel!, style: const TextStyle(color: AppColors.violeta, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(content.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(content.description, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
      ],
    ),
  );
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.categoryLabel,
    required this.selectedByMe,
    required this.selectedByPartner,
    required this.canChoose,
    required this.canWithdraw,
    required this.working,
    required this.onChoose,
    required this.onWithdraw,
    required this.onFavorite,
  });

  final MonthlyChallengeProposal proposal;
  final String categoryLabel;
  final bool selectedByMe;
  final bool selectedByPartner;
  final bool canChoose;
  final bool canWithdraw;
  final bool working;
  final VoidCallback onChoose;
  final VoidCallback onWithdraw;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final voters = [
      if (selectedByMe) 'Tú',
      if (selectedByPartner) 'Tu pareja',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(proposal.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                tooltip: 'Guardar en favoritos',
                onPressed: working ? null : onFavorite,
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
            ],
          ),
          Text(categoryLabel, style: const TextStyle(color: AppColors.violeta, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(proposal.description, style: TextStyle(color: Colors.grey.shade800, height: 1.35)),
          const SizedBox(height: 8),
          Text('Propuesto por ${proposal.proposedByName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          if (voters.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Eligieron: ${voters.join(' y ')}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
          if (canChoose) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: selectedByMe
                  ? const OutlinedButton(onPressed: null, child: Text('Tu elección actual'))
                  : FilledButton(
                      onPressed: working ? null : onChoose,
                      child: const Text('Elegir esta propuesta'),
                    ),
            ),
          ],
          if (canWithdraw) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: working ? null : onWithdraw,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Retirar mi propuesta'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.favorite, required this.onPropose});

  final MonthlyChallengeFavorite favorite;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: const Icon(Icons.bookmark, color: AppColors.violeta),
      title: Text(favorite.title),
      subtitle: Text(_challengeCategories[favorite.category] ?? 'Otro'),
      trailing: IconButton(
        tooltip: 'Proponer este favorito',
        onPressed: onPropose,
        icon: const Icon(Icons.send_rounded),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}
