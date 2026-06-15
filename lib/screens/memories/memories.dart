// lib/screens/memories/memories.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/animations.dart';
import '../../utils/colors.dart';
import '../../models/cita.dart';
import '../../services/cita_service.dart';
import '../../services/upload_service.dart';
import '../plans/checklist.dart';
import 'location_picker.dart';

class ExperienceMenuScreen extends StatefulWidget {
  const ExperienceMenuScreen({super.key});

  @override
  State<ExperienceMenuScreen> createState() => _ExperienceMenuScreenState();
}

class _ExperienceMenuScreenState extends State<ExperienceMenuScreen> {
  static const List<Map<String, dynamic>> _categorias = [
    {
      'nombre': 'Parques',
      'icono': Icons.forest,
      'tipo': 'parque',
      'emoji': '🌳',
      'color': Color(0xFF66BB6A),
    },
    {
      'nombre': 'Museos',
      'icono': Icons.museum,
      'tipo': 'museo',
      'emoji': '🏛️',
      'color': Color(0xFF5C6BC0),
    },
    {
      'nombre': 'Conciertos',
      'icono': Icons.confirmation_number,
      'tipo': 'concierto',
      'emoji': '🎵',
      'color': Color(0xFFE91E63),
    },
    {
      'nombre': 'Pueblos',
      'icono': Icons.holiday_village,
      'tipo': 'pueblo',
      'emoji': '🏘️',
      'color': Color(0xFFFF7043),
    },
    {
      'nombre': 'Países',
      'icono': Icons.public,
      'tipo': 'pais',
      'emoji': '✈️',
      'color': Color(0xFF26C6DA),
    },
    {
      'nombre': 'Restaurantes',
      'icono': Icons.restaurant,
      'tipo': 'restaurante',
      'emoji': '🍽️',
      'color': Color(0xFFFFCA28),
    },
  ];

  List<Cita>? _citas;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCitas();
  }

  Future<void> _loadCitas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final citas = await ApiService().getCitas();
      setState(() {
        _citas = citas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _abrirFormularioNuevaCita() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NuevaCitaSheet(
        onCreada: (nuevaCita) {
          setState(() {
            _citas = [...(_citas ?? []), nuevaCita];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ "${nuevaCita.nombre}" agregada'),
              backgroundColor: AppColors.violeta,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      appBar: AppBar(
        title: const Text(
          'Nuestras Aventuras',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.violeta),
            onPressed: _loadCitas,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioNuevaCita,
        backgroundColor: AppColors.violeta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'Nueva Cita',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.violeta),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCitas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final citas = _citas!;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final cat = _categorias[index];
        final Color color = cat['color'] as Color;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            createRoute(
              AdventureListScreen(
                cita: Cita(
                  nombre: 'nombre',
                  descripcion: 'descripcion',
                  categoria: 'categoria',
                  presupuesto: 'presupuesto',
                  tiempo: 0,
                  link: 'link',
                  typeLocation: cat['tipo'] as String,
                ),
                citas: citas,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      cat['emoji'] as String,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  cat['nombre'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${citas.where((c) => c.typeLocation == cat['tipo']).length} lugares',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0,
                        end: () {
                          final total = citas
                              .where((c) => c.typeLocation == cat['tipo'])
                              .length;
                          if (total == 0) return 0.0;
                          return citas
                                  .where(
                                    (c) =>
                                        c.typeLocation == cat['tipo'] &&
                                        c.isVisited,
                                  )
                                  .length /
                              total;
                        }(),
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: AppColors.lavanda,
                        valueColor: AlwaysStoppedAnimation<Color>(() {
                          final total = citas
                              .where((c) => c.typeLocation == cat['tipo'])
                              .length;
                          final visitados = citas
                              .where(
                                (c) =>
                                    c.typeLocation == cat['tipo'] &&
                                    c.isVisited,
                              )
                              .length;
                          return total > 0 && visitados == total
                              ? const Color(0xFF4CAF50)
                              : AppColors.violeta;
                        }()),
                      ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet: Formulario Nueva Cita
// Con selector de ubicación (mapa) y upload de imagen a S3
// ─────────────────────────────────────────────────────────────────────────────
class _NuevaCitaSheet extends StatefulWidget {
  final void Function(Cita) onCreada;
  const _NuevaCitaSheet({required this.onCreada});

  @override
  State<_NuevaCitaSheet> createState() => _NuevaCitaSheetState();
}

class _NuevaCitaSheetState extends State<_NuevaCitaSheet> {
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();

  String _categoria = 'Romántico';
  String _presupuesto = 'Medio';
  String _typeLocation = 'restaurante';
  double _tiempo = 2;
  bool _isLoading = false;

  // ── Imagen ─────────────────────────────────────────────────────────────────
  String? _imageUrl; // URL pública en S3 después del upload
  dynamic _imageFile;
  bool _isUploadingImage = false;
  String? _imageError;
  String? _uploadLog; // mensaje de etapa actual (visible en UI y consola)

  static const List<String> _categorias = [
    'Romántico',
    'Aventura',
    'Relajante',
    'Compras',
    'Comida',
  ];

  static const List<String> _presupuestos = ['Bajo', 'Medio', 'Alto'];

  static const List<Map<String, String>> _tiposLugar = [
    {'tipo': 'parque', 'emoji': '🌳', 'label': 'Parque'},
    {'tipo': 'museo', 'emoji': '🏛️', 'label': 'Museo'},
    {'tipo': 'concierto', 'emoji': '🎵', 'label': 'Concierto'},
    {'tipo': 'pueblo', 'emoji': '🏘️', 'label': 'Pueblo'},
    {'tipo': 'pais', 'emoji': '✈️', 'label': 'País'},
    {'tipo': 'restaurante', 'emoji': '🍽️', 'label': 'Restaurante'},
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  // ── Seleccionar ubicación con mapa ─────────────────────────────────────────
  Future<void> _seleccionarUbicacion() async {
    // Cerramos el teclado antes de abrir el mapa
    FocusScope.of(context).unfocus();

    final url = await showLocationPicker(context);
    if (url != null && mounted) {
      setState(() => _linkCtrl.text = url);
    }
  }

  // ── Seleccionar imagen y subir a S3 ───────────────────────────────────────
  Future<void> _seleccionarImagen() async {
    debugPrint('📷 [memories] Iniciando selección de imagen...');

    setState(() {
      _imageUrl = null;
      _imageFile = null;
      _imageError = null;
      _isUploadingImage = true;
      _uploadLog = 'Abriendo galería...';
    });

    try {
      // UploadService maneja web (dart:html) y móvil (image_picker) automáticamente
      if (mounted) setState(() => _uploadLog = 'Subiendo imagen...');

      final publicUrl = await UploadService().pickAndUpload();

      if (publicUrl == null) {
        // Usuario canceló
        debugPrint('ℹ️ [memories] Selección cancelada');
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
            _uploadLog = null;
          });
        }
        return;
      }

      debugPrint('✅ [memories] URL recibida: $publicUrl');
      if (mounted) {
        setState(() {
          _imageUrl = publicUrl;
          _isUploadingImage = false;
          _uploadLog = null;
        });
      }
    } catch (e, st) {
      debugPrint('❌ [memories] Error: $e\n$st');
      if (mounted) {
        setState(() {
          _imageError = e.toString();
          _isUploadingImage = false;
          _uploadLog = null;
        });
      }
    }
  }

  void _quitarImagen() {
    setState(() {
      _imageUrl = null;
      _imageError = null;
    });
  }

  // ── Guardar ────────────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();

    if (nombre.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y descripción son obligatorios')),
      );
      return;
    }

    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Espera a que termine de subir la imagen'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final nuevaCita = Cita(
      nombre: nombre,
      descripcion: descripcion,
      categoria: _categoria,
      presupuesto: _presupuesto,
      tiempo: _tiempo.round(),
      link: _linkCtrl.text.trim(),
      imagenUrl: _imageUrl ?? '',
      typeLocation: _typeLocation,
      isVisited: false,
      rating: 0.0,
    );

    try {
      final creada = await ApiService().createCita(nuevaCita);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreada(creada);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.violeta.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: AppColors.violeta,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nueva Cita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nombre
            _buildTextField(
              controller: _nombreCtrl,
              label: 'Nombre *',
              hint: 'Ej: Museo Soumaya',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),

            // Descripción
            _buildTextField(
              controller: _descripcionCtrl,
              label: 'Descripción *',
              hint: 'Ej: Vamos a ver la expo de arte moderno',
              icon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Categoría
            _buildLabel('Categoría'),
            const SizedBox(height: 8),
            _buildChipRow(
              options: _categorias,
              selected: _categoria,
              onSelected: (v) => setState(() => _categoria = v),
            ),
            const SizedBox(height: 16),

            // Presupuesto
            _buildLabel('Presupuesto'),
            const SizedBox(height: 8),
            _buildChipRow(
              options: _presupuestos,
              selected: _presupuesto,
              onSelected: (v) => setState(() => _presupuesto = v),
              emojiMap: {'Bajo': '🪙', 'Medio': '💳', 'Alto': '💎'},
            ),
            const SizedBox(height: 16),

            // Tipo de lugar
            _buildLabel('Tipo de lugar'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tiposLugar.map((t) {
                final isSelected = _typeLocation == t['tipo'];
                return GestureDetector(
                  onTap: () => setState(() => _typeLocation = t['tipo']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.violeta
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.violeta
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t['emoji']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          t['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tiempo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Duración estimada'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.violeta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_tiempo.round()} horas',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.violeta,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.violeta,
                inactiveTrackColor: AppColors.violeta.withOpacity(0.15),
                thumbColor: AppColors.violeta,
                overlayColor: AppColors.violeta.withOpacity(0.1),
                trackHeight: 4,
              ),
              child: Slider(
                value: _tiempo,
                min: 1,
                max: 48,
                divisions: 47,
                onChanged: (v) => setState(() => _tiempo = v),
              ),
            ),
            const SizedBox(height: 8),

            // ── Selector de ubicación (mapa) ──────────────────────────────
            _buildLabel('Ubicación'),
            const SizedBox(height: 8),
            _buildLocationField(),
            const SizedBox(height: 16),

            // ── Selector de imagen ────────────────────────────────────────
            _buildLabel('Foto del lugar (opcional)'),
            const SizedBox(height: 8),
            _buildImagePicker(),
            const SizedBox(height: 24),

            // Botón guardar
            ElevatedButton.icon(
              onPressed: (_isLoading || _isUploadingImage) ? null : _guardar,
              icon: (_isLoading || _isUploadingImage)
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _isUploadingImage
                    ? 'Subiendo imagen...'
                    : _isLoading
                    ? 'Guardando...'
                    : 'Guardar Cita',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Campo de ubicación ─────────────────────────────────────────────────────
  Widget _buildLocationField() {
    final hasLink = _linkCtrl.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: _seleccionarUbicacion,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasLink
              ? AppColors.violeta.withOpacity(0.06)
              : Colors.grey.shade50,
          border: Border.all(
            color: hasLink ? AppColors.violeta : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.map_outlined,
              color: hasLink ? AppColors.violeta : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasLink
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación seleccionada ✓',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.violeta,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _linkCtrl.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Toca para abrir el mapa',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
            ),
            // Botón limpiar
            if (hasLink)
              GestureDetector(
                onTap: () => setState(() => _linkCtrl.clear()),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // ── Selector de imagen ─────────────────────────────────────────────────────
  Widget _buildImagePicker() {
    // Estado: imagen cargada y subida con éxito
    if (_imageUrl != null && !_isUploadingImage) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Usamos la URL pública de S3 para el preview (funciona en web y móvil)
            child: Image.network(
              _imageUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      height: 160,
                      color: AppColors.lavanda,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.violeta,
                        ),
                      ),
                    ),
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: AppColors.lavanda,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.violeta,
                  ),
                ),
              ),
            ),
          ),
          // Overlay verde de "subida correcta"
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Subida',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón quitar
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: _quitarImagen,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Estado: subiendo — muestra etapa actual en pantalla
    if (_isUploadingImage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.violeta.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.violeta.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.violeta,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _uploadLog ?? 'Preparando...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.violeta.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Revisa la consola para más detalles',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    // Estado: error al subir — mensaje completo visible y scrollable
    if (_imageError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Error al subir imagen',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Contenedor scrollable para el mensaje completo
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      _imageError!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade900,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Revisa también la consola del navegador (F12 → Console)',
                  style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildPickerButton(label: 'Intentar con otra imagen', isRetry: true),
        ],
      );
    }

    // Estado: vacío — botón para elegir
    return _buildPickerButton();
  }

  Widget _buildPickerButton({String? label, bool isRetry = false}) {
    return GestureDetector(
      onTap: _seleccionarImagen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isRetry
              ? Colors.red.shade50
              : AppColors.violeta.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRetry
                ? Colors.red.shade200
                : AppColors.violeta.withOpacity(0.25),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRetry
                  ? Icons.refresh_rounded
                  : Icons.add_photo_alternate_outlined,
              size: 32,
              color: isRetry
                  ? Colors.red.shade400
                  : AppColors.violeta.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              label ?? 'Agregar foto del lugar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isRetry
                    ? Colors.red.shade600
                    : AppColors.violeta.withOpacity(0.7),
              ),
            ),
            if (!isRetry) ...[
              const SizedBox(height: 3),
              Text(
                'Desde tu galería · Se sube automáticamente',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Widgets helpers ────────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.violeta,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.violeta, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.violeta, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildChipRow({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
    Map<String, String>? emojiMap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelected(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.violeta : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.violeta : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emojiMap != null && emojiMap[opt] != null) ...[
                  Text(emojiMap[opt]!, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                ],
                Text(
                  opt,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
