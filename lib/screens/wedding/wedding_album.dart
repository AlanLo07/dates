// lib/screens/wedding/wedding_album.dart
import 'package:flutter/material.dart';
import 'models/wedding_models.dart';

const Color _rose = Color(0xFFE91E63);
const Color _roseLight = Color(0xFFFCE4EC);

class WeddingAlbumScreen extends StatefulWidget {
  const WeddingAlbumScreen({super.key});

  @override
  State<WeddingAlbumScreen> createState() => _WeddingAlbumScreenState();
}

class _WeddingAlbumScreenState extends State<WeddingAlbumScreen> {
  late List<FotoBoda> _fotos;
  String _filtroSeleccionado = 'Todas';

  @override
  void initState() {
    super.initState();
    _fotos = [
      FotoBoda(
        id: '1',
        url: 'https://via.placeholder.com/300',
        titulo: 'Ceremonia - Entrada de la novia',
        descripcion: 'Momento especial de la ceremonia',
        fechaTomada: DateTime.now(),
        camarogrfo: 'Juan (Fotógrafo)',
        esDestacada: true,
        tags: ['ceremonia', 'entrada'],
      ),
      FotoBoda(
        id: '2',
        url: 'https://via.placeholder.com/300',
        titulo: 'Primer beso',
        descripcion: 'El primer beso como casados',
        fechaTomada: DateTime.now(),
        camarogrfo: 'Juan (Fotógrafo)',
        esDestacada: true,
        tags: ['ceremonia', 'beso'],
      ),
      FotoBoda(
        id: '3',
        url: 'https://via.placeholder.com/300',
        titulo: 'Fiesta - Primer baile',
        descripcion: 'Nuestro primer baile como pareja casada',
        fechaTomada: DateTime.now(),
        camarogrfo: 'Juan (Fotógrafo)',
        tags: ['fiesta', 'baile'],
      ),
    ];
  }

  List<String> get _tags => _fotos.expand((f) => f.tags).toSet().toList();

  List<FotoBoda> get _fotosFiltradas {
    if (_filtroSeleccionado == 'Destacadas') {
      return _fotos.where((f) => f.esDestacada).toList();
    }
    if (_filtroSeleccionado == 'Todas') {
      return _fotos;
    }
    return _fotos.where((f) => f.tags.contains(_filtroSeleccionado)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _roseLight,
      appBar: AppBar(
        title: const Text('📸 Álbum de Fotos', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: _rose),
            onPressed: () => _mostrarAgregarFoto(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🟢 Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildFilterChip('Todas'),
                _buildFilterChip('Destacadas'),
                ..._tags.map(_buildFilterChip),
              ],
            ),
          ),

          // 🟢 Grid de fotos
          Expanded(
            child: _fotosFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No hay fotos en esta categoría',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: _fotosFiltradas.length,
                    itemBuilder: (_, i) => _buildFotoCard(_fotosFiltradas[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filtroSeleccionado == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filtroSeleccionado = label),
        selectedColor: _rose,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildFotoCard(FotoBoda foto) {
    return GestureDetector(
      onTap: () => _mostrarFotoDetalle(foto),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 🟢 Imagen
            Container(
              color: Colors.grey[200],
              child: Image.network(
                foto.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey[400]),
                ),
              ),
            ),

            // 🟢 Degradado con título
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      foto.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (foto.esDestacada)
                      const Text(
                        '⭐ Destacada',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 🟢 Botón de opciones
            Positioned(
              top: 4,
              right: 4,
              child: PopupMenuButton(
                color: Colors.white,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    onTap: () => _marcarDestacada(foto),
                    child: Text(foto.esDestacada ? '⭐ Desmarcar' : '☆ Marcar como destacada'),
                  ),
                  const PopupMenuItem(child: Text('✏️ Editar')),
                  const PopupMenuItem(child: Text('🔗 Compartir')),
                  const PopupMenuItem(
                    child: Text('🗑️ Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFotoDetalle(FotoBoda foto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              foto.url,
              height: 400,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foto.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (foto.descripcion != null)
                    Text(foto.descripcion!),
                  const SizedBox(height: 8),
                  Text(
                    '📷 ${foto.camarogrfo ?? 'Desconocido'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Wrap(
                    spacing: 4,
                    children: foto.tags
                        .map((tag) => Chip(label: Text(tag), visualDensity: VisualDensity.compact))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _marcarDestacada(FotoBoda foto) {
    setState(() {
      final index = _fotos.indexWhere((f) => f.id == foto.id);
      if (index != -1) {
        _fotos[index] = FotoBoda(
          id: foto.id,
          url: foto.url,
          titulo: foto.titulo,
          descripcion: foto.descripcion,
          fechaTomada: foto.fechaTomada,
          camarogrfo: foto.camarogrfo,
          esDestacada: !foto.esDestacada,
          tags: foto.tags,
        );
      }
    });
  }

  void _mostrarAgregarFoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar foto'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(decoration: InputDecoration(hintText: 'URL de la foto')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Título')),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(hintText: 'Descripción')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
