import 'package:flutter/material.dart';

import '../../models/coupon.dart';
import '../../services/coupons_service.dart';
import '../../utils/colors.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final CouponsService _service = CouponsService();
  List<CouponGift> _gifts = [];
  bool _loading = true;
  bool _hasCoupon = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGifts();
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
      });
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
        title: const Text('Cupones'),
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Cupón', style: TextStyle(color: Colors.white)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.violeta));
    if (_error != null) {
      return Center(child: FilledButton(onPressed: _loadGifts, child: const Text('Reintentar')));
    }
    if (_gifts.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Aún no hay cupones.\nCrea un regalo canjeable para empezar.', textAlign: TextAlign.center)));
    }
    return RefreshIndicator(
      onRefresh: _loadGifts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _gifts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final gift = _gifts[index];
          return Card(
            child: ListTile(
              leading: Icon(gift.canjeado ? Icons.redeem_rounded : Icons.card_giftcard_rounded, color: gift.canjeado ? AppColors.success : AppColors.violeta),
              title: Text(gift.nombre, style: TextStyle(decoration: gift.canjeado ? TextDecoration.lineThrough : null)),
              subtitle: gift.descripcion.isEmpty ? null : Text(gift.descripcion),
              onTap: () => _toggleRedeemed(gift, !gift.canjeado),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') _editGift(gift);
                  if (value == 'delete') _deleteGift(gift);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}