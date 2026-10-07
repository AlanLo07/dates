import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/coupon.dart';
import '../../services/coupons_service.dart';
import '../../utils/colors.dart';

enum _CouponView { booklet, oneByOne }

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final CouponsService _service = CouponsService();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final math.Random _random = math.Random();
  List<CouponGift> _gifts = [];
  bool _loading = true;
  bool _hasCoupon = true;
  String? _error;
  _CouponView _view = _CouponView.booklet;
  int _currentPage = 0;

  List<CouponGift> get _availableGifts =>
      _gifts.where((gift) => !gift.canjeado).toList();

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gifts = await _service.getGifts();
      if (!mounted) return;
      setState(() {
        _gifts = gifts;
        _hasCoupon = true;
        _currentPage = 0;
      });
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    } on CouponsApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 404) {
        setState(() {
          _gifts = [];
          _hasCoupon = false;
        });
      } else {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar los cupones.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editGift([CouponGift? gift]) async {
    final result = await _showGiftEditor(gift);
    if (result == null) return;
    try {
      if (gift == null) {
        if (_hasCoupon) {
          await _service.addGift(result);
        } else {
          await _service.createCoupon([result]);
        }
      } else {
        await _service.updateGift(gift.nombre, result);
      }
      await _loadGifts();
    } catch (error) {
      _showMessage('No se pudo guardar el cupón: $error');
    }
  }

  Future<void> _toggleRedeemed(CouponGift gift, bool redeemed) async {
    try {
      await _service.setRedeemed(gift.nombre, redeemed);
      await _loadGifts();
    } catch (error) {
      _showMessage('No se pudo actualizar el cupón: $error');
    }
  }

  Future<void> _deleteGift(CouponGift gift) async {
    if (!await _confirm('Eliminar cupón', '¿Eliminar "${gift.nombre}"?')) return;
    try {
      await _service.deleteGift(gift.nombre);
      await _loadGifts();
    } catch (error) {
      _showMessage('No se pudo eliminar el cupón: $error');
    }
  }

  Future<void> _deleteCoupon() async {
    if (!await _confirm('Eliminar cuponera', 'Se eliminarán todos los cupones.')) return;
    try {
      await _service.deleteCoupon();
      await _loadGifts();
    } catch (error) {
      _showMessage('No se pudo eliminar la cuponera: $error');
    }
  }

  Future<void> _pickSurprise() async {
    final available = _availableGifts;
    if (available.isEmpty) {
      _showMessage('Todos los cupones ya fueron canjeados.');
      return;
    }

    final gift = available[_random.nextInt(available.length)];
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar sorpresa',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, _, _) => _SurpriseDialog(
        gift: gift,
        onRedeem: () {
          Navigator.pop(context);
          _toggleRedeemed(gift, true);
        },
      ),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  Future<bool> _confirm(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<CouponGift?> _showGiftEditor(CouponGift? gift) async {
    final nameController = TextEditingController(text: gift?.nombre);
    final descriptionController = TextEditingController(text: gift?.descripcion);
    return showDialog<CouponGift>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gift == null ? 'Nuevo cupón' : 'Editar cupón'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Regalo')),
            const SizedBox(height: 12),
            TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context, CouponGift(nombre: name, descripcion: descriptionController.text.trim(), canjeado: gift?.canjeado ?? false));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grisCalido,
      appBar: AppBar(
        title: const Text('Cuponera de regalos'),
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh_rounded), onPressed: _loading ? null : _loadGifts),
          if (_hasCoupon)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) { if (value == 'delete') _deleteCoupon(); },
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Eliminar cuponera'))],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _editGift(),
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Regalo'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.violeta),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_rounded,
              color: AppColors.violeta,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadGifts, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_gifts.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        _buildGiftHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: SegmentedButton<_CouponView>(
            segments: const [
              ButtonSegment(
                value: _CouponView.booklet,
                icon: Icon(Icons.view_agenda_outlined),
                label: Text('Cuponera'),
              ),
              ButtonSegment(
                value: _CouponView.oneByOne,
                icon: Icon(Icons.style_outlined),
                label: Text('Uno a uno'),
              ),
            ],
            selected: {_view},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _view = selection.first);
            },
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            child: _view == _CouponView.booklet
                ? _buildBooklet()
                : _buildOneByOne(),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftHeader() {
    final available = _availableGifts.length;
    return Container(
      width: double.infinity,
      color: AppColors.violeta,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Un detalle para compartir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$available disponibles · ${_gifts.length - available} canjeados',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _pickSurprise,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.violeta,
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 19),
              label: const Text('Elegir un cupón sorpresa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooklet() {
    return RefreshIndicator(
      key: const ValueKey('booklet'),
      onRefresh: _loadGifts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _gifts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _AnimatedCouponEntry(
          key: ValueKey(_gifts[index].nombre),
          delay: Duration(milliseconds: math.min(index * 70, 420)),
          child: _CouponTicket(
            gift: _gifts[index],
            compact: true,
            onRedeem: () => _toggleRedeemed(
              _gifts[index],
              !_gifts[index].canjeado,
            ),
            onEdit: () => _editGift(_gifts[index]),
            onDelete: () => _deleteGift(_gifts[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildOneByOne() {
    return Column(
      key: const ValueKey('oneByOne'),
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _gifts.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 18),
              child: _CouponTicket(
                gift: _gifts[index],
                onRedeem: () => _toggleRedeemed(
                  _gifts[index],
                  !_gifts[index].canjeado,
                ),
                onEdit: () => _editGift(_gifts[index]),
                onDelete: () => _deleteGift(_gifts[index]),
              ),
            ),
          ),
        ),
        Text(
          '${_currentPage + 1} de ${_gifts.length}',
          style: const TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 94),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.lavanda,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.card_giftcard_rounded,
                color: AppColors.violeta,
                size: 52,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Tu cuponera está esperando',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Crea el primer regalo para empezar a compartir sorpresas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _editGift(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear primer cupón'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponTicket extends StatelessWidget {
  const _CouponTicket({
    required this.gift,
    required this.onRedeem,
    required this.onEdit,
    required this.onDelete,
    this.compact = false,
  });

  final CouponGift gift;
  final VoidCallback onRedeem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final muted = gift.canjeado;
    return Material(
      color: muted ? Colors.white.withValues(alpha: 0.68) : Colors.white,
      elevation: muted ? 0 : 2,
      shadowColor: AppColors.violeta.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 7,
              color: muted ? AppColors.success : AppColors.violeta,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 18 : 24,
              compact ? 16 : 28,
              compact ? 8 : 16,
              compact ? 14 : 22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: compact ? 42 : 56,
                      height: compact ? 42 : 56,
                      decoration: BoxDecoration(
                        color: (muted ? AppColors.success : AppColors.lavanda)
                            .withValues(alpha: muted ? 0.18 : 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        muted
                            ? Icons.check_rounded
                            : Icons.card_giftcard_rounded,
                        color: muted ? AppColors.success : AppColors.violeta,
                        size: compact ? 25 : 32,
                      ),
                    ),
                    SizedBox(width: compact ? 13 : 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            muted ? 'CUPÓN CANJEADO' : 'VALE POR',
                            style: TextStyle(
                              color: muted
                                  ? AppColors.success
                                  : AppColors.violeta,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gift.nombre,
                            maxLines: compact ? 2 : 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 18 : 25,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              decoration: muted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Opciones del cupón',
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ],
                ),
                if (gift.descripcion.isNotEmpty) ...[
                  SizedBox(height: compact ? 12 : 22),
                  Text(
                    gift.descripcion,
                    maxLines: compact ? 2 : 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.64),
                      fontSize: compact ? 14 : 16,
                      height: 1.4,
                    ),
                  ),
                ],
                SizedBox(height: compact ? 12 : 24),
                const Divider(height: 1),
                SizedBox(height: compact ? 8 : 14),
                SizedBox(
                  width: double.infinity,
                  child: muted
                      ? OutlinedButton.icon(
                          onPressed: onRedeem,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Marcar disponible'),
                        )
                      : FilledButton.icon(
                          onPressed: onRedeem,
                          icon: const Icon(Icons.redeem_rounded),
                          label: const Text('Canjear regalo'),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedCouponEntry extends StatefulWidget {
  const _AnimatedCouponEntry({
    super.key,
    required this.delay,
    required this.child,
  });

  final Duration delay;
  final Widget child;

  @override
  State<_AnimatedCouponEntry> createState() => _AnimatedCouponEntryState();
}

class _AnimatedCouponEntryState extends State<_AnimatedCouponEntry> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      offset: _visible ? Offset.zero : const Offset(0, 0.12),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        opacity: _visible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _SurpriseDialog extends StatefulWidget {
  const _SurpriseDialog({required this.gift, required this.onRedeem});

  final CouponGift gift;
  final VoidCallback onRedeem;

  @override
  State<_SurpriseDialog> createState() => _SurpriseDialogState();
}

class _SurpriseDialogState extends State<_SurpriseDialog> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: math.min(MediaQuery.sizeOf(context).width - 40, 390),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.letterBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lavanda, width: 2),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _revealed ? _buildReveal() : _buildWrappedGift(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWrappedGift() {
    return Column(
      key: const ValueKey('wrapped'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.card_giftcard_rounded,
          color: AppColors.violeta,
          size: 92,
        ),
        const SizedBox(height: 18),
        const Text(
          'Elegimos una sorpresa para ti',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          '¿Listos para descubrir el regalo?',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => setState(() => _revealed = true),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Descubrir'),
        ),
      ],
    );
  }

  Widget _buildReveal() {
    return Column(
      key: const ValueKey('revealed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.redeem_rounded, color: AppColors.violeta, size: 54),
        const SizedBox(height: 12),
        const Text(
          '¡El regalo es!',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.gift.nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        if (widget.gift.descripcion.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(widget.gift.descripcion, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Guardar'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: widget.onRedeem,
                child: const Text('Canjear'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}