// lib/screens/wedding/wedding_album.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/boda.dart';
import '../../services/upload_service.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);
const Color _purple = Color(0xFF9C27B0);
const Color _purpleLight = Color(0xFFF3E5F5);

class WeddingAlbumScreen extends StatefulWidget {
  const WeddingAlbumScreen({super.key});

  @override
  State<WeddingAlbumScreen> createState() => _WeddingAlbumScreenState();
}

class _WeddingAlbumScreenState extends State<WeddingAlbumScreen> {
  final WeddingService _service = WeddingService();
  final UploadService _uploader = UploadService();
  final List<AlbumFotoBoda> _fotos = [];

  String? _bodaId;
  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
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
      final items = await _service.getAlbumItems(bodaId);
      if (!mounted) return;
      setState(() {
        _bodaId = bodaId;
        _fotos
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _agregarFoto() async {
    final bodaId = _bodaId;
    if (bodaId == null) return;

    setState(() => _uploading = true);
    try {
      final url = await _uploader.pickAndUpload();
      if (url == null || !mounted) return;

      final nueva = AlbumFotoBoda(
        id: '',
        titulo: 'Foto de la boda',
        url: url,
        subidoPor: 'pareja',
      );
      final creada = await _service.createAlbumItem(bodaId, nueva);
      if (!mounted) return;
      setState(() => _fotos.add(creada));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir foto: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _uploading = false);
    }
  }

  void _verFoto(AlbumFotoBoda foto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: foto.url,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            if (foto.comentario.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 12,
                right: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    foto.comentario,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarFoto(AlbumFotoBoda foto) async {
    final bodaId = _bodaId;
    if (bodaId == null) return;

    final tituloCtrl = TextEditingController(text: foto.titulo);
    final comentCtrl = TextEditingController(text: foto.comentario);
    final subidoPorCtrl = TextEditingController(text: foto.subidoPor);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: comentCtrl,
              decoration: const InputDecoration(labelText: 'Comentario'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subidoPorCtrl,
              decoration: const InputDecoration(labelText: 'Subido por'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            child: const Text(
              'Guardar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      foto.titulo = tituloCtrl.text.trim();
      foto.comentario = comentCtrl.text.trim();
      foto.subidoPor = subidoPorCtrl.text.trim();
      final actualizado = await _service.updateAlbumItem(bodaId, foto);
      final idx = _fotos.indexWhere((f) => f.id == foto.id);
      if (idx != -1 && mounted) {
        setState(() => _fotos[idx] = actualizado);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purpleLight,
      appBar: AppBar(
        title: const Text(
          'Álbum de fotos',
          style: TextStyle(color: _purple, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _purple),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _purple),
            onPressed: _loadAlbum,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _agregarFoto,
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        icon: _uploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_a_photo_rounded),
        label: Text(_uploading ? 'Subiendo…' : 'Agregar foto'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _purple),
            )
          : _error != null
          ? _buildError()
          : _fotos.isEmpty
          ? _buildEmpty()
          : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _fotos.length,
      itemBuilder: (_, idx) {
        final foto = _fotos[idx];
        return GestureDetector(
          onTap: () => _verFoto(foto),
          onLongPress: () => _editarFoto(foto),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: foto.url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_rounded,
                      color: Colors.grey,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (foto.comentario.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        foto.comentario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_album_rounded,
            size: 72,
            color: _purple.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'El álbum está vacío',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _purple.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para agregar la primera foto',
            style: TextStyle(color: _purple.withValues(alpha: 0.5)),
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
            const Icon(Icons.error_outline, color: _rose, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _rose),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAlbum,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
            ),
          ],
        ),
      ),
    );
  }
}
