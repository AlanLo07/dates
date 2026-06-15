// lib/screens/plans/result.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cita.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import '../../services/cita_service.dart';
import '../../utils/colors.dart';
import '../memories/location_picker.dart';
import '../../services/upload_service.dart';

// ── Título con fade-in ────────────────────────────────────────────────────────
class FadingTitle extends StatefulWidget {
  final String title;
  const FadingTitle({required this.title, super.key});

  @override
  State<FadingTitle> createState() => _FadingTitleState();
}

class _FadingTitleState extends State<FadingTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        widget.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.violeta,
        ),
      ),
    );
  }
}

// ── Pantalla principal ────────────────────────────────────────────────────────
class ResultScreen extends StatefulWidget {
  final Cita cita;
  const ResultScreen({required this.cita, super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  // Usamos una copia mutable para reflejar ediciones sin romper el widget padre
  late Cita _cita;

  @override
  void initState() {
    super.initState();
    _cita = widget.cita;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('No se pudo abrir el enlace $url');
    }
  }

  Widget _buildMediaWidget() {
    if (_cita.imagenUrl.isEmpty) {
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.lavanda,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.favorite_rounded,
          size: 80,
          color: AppColors.violeta,
        ),
      );
    }
    if (_cita.imagenUrl.endsWith('.json')) {
      return Lottie.network(
        _cita.imagenUrl,
        width: 220,
        height: 220,
        repeat: true,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CachedNetworkImage(
        imageUrl: _cita.imagenUrl,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.violeta),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.image_not_supported_outlined,
          size: 60,
          color: AppColors.violeta,
        ),
      ),
    );
  }

  void _mostrarAgendarCita() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgendarCitaSheet(cita: _cita),
    );
  }

  void _mostrarEditarCita() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarCitaSheet(
        cita: _cita,
        onGuardado: (citaActualizada) {
          setState(() => _cita = citaActualizada);
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
          '🎉 ¡Su Plan!',
          style: TextStyle(
            color: AppColors.violeta,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.violeta),
        elevation: 1,
        actions: [
          // ── Botón de editar ──────────────────────────────────────────
          IconButton(
            onPressed: _mostrarEditarCita,
            icon: const Icon(Icons.edit_rounded),
            color: AppColors.violeta,
            tooltip: 'Editar cita',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Media ────────────────────────────────────────────────────
            Center(child: _buildMediaWidget()),
            const SizedBox(height: 24),

            // ── Nombre ───────────────────────────────────────────────────
            FadingTitle(title: _cita.nombre),
            const SizedBox(height: 12),

            // ── Descripción ──────────────────────────────────────────────
            Text(
              _cita.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Info chips ───────────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildInfoChip(Icons.attach_money_rounded, _cita.presupuesto),
                _buildInfoChip(Icons.access_time_rounded, '${_cita.tiempo}h'),
                _buildInfoChip(Icons.category_rounded, _cita.categoria),
                if (_cita.typeLocation.isNotEmpty)
                  _buildInfoChip(Icons.place_rounded, _cita.typeLocation),
              ],
            ),
            const SizedBox(height: 24),

            // ── Rating ───────────────────────────────────────────────────
            if (_cita.rating > 0) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violeta.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      return Icon(
                        i < _cita.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: i < _cita.rating
                            ? const Color(0xFFFFCA28)
                            : Colors.grey.shade300,
                        size: 26,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Botón Agendar ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _mostrarAgendarCita,
              icon: const Icon(Icons.backpack_outlined),
              label: const Text('Agendar esta Cita'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violeta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),

            // ── Botón editar (secundario inline) ─────────────────────────
            OutlinedButton.icon(
              onPressed: _mostrarEditarCita,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Editar información'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.violeta,
                side: const BorderSide(color: AppColors.violeta, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Botón Link ────────────────────────────────────────────────
            if (_cita.link.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _launchUrl(_cita.link),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ver Detalles / Mapa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.violeta,
                  side: const BorderSide(color: AppColors.violeta, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.violeta.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.violeta),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.violeta,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet: EDITAR cita
// ─────────────────────────────────────────────────────────────────────────────
class _EditarCitaSheet extends StatefulWidget {
  final Cita cita;
  final void Function(Cita) onGuardado;

  const _EditarCitaSheet({required this.cita, required this.onGuardado});

  @override
  State<_EditarCitaSheet> createState() => _EditarCitaSheetState();
}

class _EditarCitaSheetState extends State<_EditarCitaSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _imagenCtrl;

  late String _categoria;
  late String _presupuesto;
  late String _typeLocation;
  late double _tiempo;
  late double _rating;
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
    'Cualquiera',
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
  void initState() {
    super.initState();
    final c = widget.cita;
    _nombreCtrl = TextEditingController(text: c.nombre);
    _descripcionCtrl = TextEditingController(text: c.descripcion);
    _linkCtrl = TextEditingController(text: c.link);
    _imagenCtrl = TextEditingController(text: c.imagenUrl);
    _categoria = _categorias.contains(c.categoria) ? c.categoria : 'Cualquiera';
    _presupuesto = _presupuestos.contains(c.presupuesto)
        ? c.presupuesto
        : 'Medio';
    _typeLocation = c.typeLocation.isNotEmpty ? c.typeLocation : 'restaurante';
    _tiempo = c.tiempo.toDouble().clamp(1, 200);
    _rating = c.rating.clamp(0, 5);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _linkCtrl.dispose();
    _imagenCtrl.dispose();
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

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();

    if (nombre.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y descripción son obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Construimos la cita actualizada manteniendo campos que no se editan aquí
    final citaActualizada = Cita(
      nombre: nombre,
      descripcion: descripcion,
      categoria: _categoria,
      presupuesto: _presupuesto,
      tiempo: _tiempo.round(),
      link: _linkCtrl.text.trim(),
      imagenUrl: _imageUrl ?? '',
      typeLocation: _typeLocation,
      isVisited: widget.cita.isVisited,
      rating: _rating,
    );

    try {
      // syncLugares actualiza todos los campos via PUT
      await ApiService().syncLugares([citaActualizada]);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onGuardado(citaActualizada);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ "${citaActualizada.nombre}" actualizada'),
            backgroundColor: AppColors.violeta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
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

            // Header
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
                    Icons.edit_rounded,
                    color: AppColors.violeta,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Editar Cita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Nombre ────────────────────────────────────────────────────
            _buildTextField(
              controller: _nombreCtrl,
              label: 'Nombre *',
              hint: 'Ej: Museo Soumaya',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),

            // ── Descripción ───────────────────────────────────────────────
            _buildTextField(
              controller: _descripcionCtrl,
              label: 'Descripción *',
              hint: 'Ej: Vamos a ver la expo de arte moderno',
              icon: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // ── Categoría ─────────────────────────────────────────────────
            _buildLabel('Categoría'),
            const SizedBox(height: 8),
            _buildChipRow(
              options: _categorias,
              selected: _categoria,
              onSelected: (v) => setState(() => _categoria = v),
            ),
            const SizedBox(height: 16),

            // ── Presupuesto ───────────────────────────────────────────────
            _buildLabel('Presupuesto'),
            const SizedBox(height: 8),
            _buildChipRow(
              options: _presupuestos,
              selected: _presupuesto,
              emojiMap: {'Bajo': '🪙', 'Medio': '💳', 'Alto': '💎'},
              onSelected: (v) => setState(() => _presupuesto = v),
            ),
            const SizedBox(height: 16),

            // ── Tipo de lugar ─────────────────────────────────────────────
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

            // ── Duración ──────────────────────────────────────────────────
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
                max: 200,
                divisions: 199,
                onChanged: (v) => setState(() => _tiempo = v),
              ),
            ),
            const SizedBox(height: 4),

            // ── Calificación ──────────────────────────────────────────────
            _buildLabel('Tu calificación'),
            const SizedBox(height: 10),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i < _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: i < _rating
                          ? const Color(0xFFFFCA28)
                          : Colors.grey.shade300,
                      size: 34,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

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

            // ── Botón guardar ─────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _guardar,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar cambios'),
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

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet: AGENDAR cita (sin cambios respecto al original)
// ─────────────────────────────────────────────────────────────────────────────
class _AgendarCitaSheet extends StatefulWidget {
  final Cita cita;
  const _AgendarCitaSheet({required this.cita});

  @override
  State<_AgendarCitaSheet> createState() => _AgendarCitaSheetState();
}

class _AgendarCitaSheetState extends State<_AgendarCitaSheet> {
  DateTime? _fechaSeleccionada;
  bool _isLoading = false;

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.violeta,
            onPrimary: Colors.white,
            onSurface: AppColors.violeta,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  String _formatearFecha(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d-$m-${date.year}';
  }

  Future<void> _agendarCita() async {
    if (_fechaSeleccionada == null) return;
    setState(() => _isLoading = true);
    try {
      await ApiService().agendarCita(
        cita: widget.cita,
        fecha: _formatearFecha(_fechaSeleccionada!),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ¡Cita agendada para el ${_formatearFecha(_fechaSeleccionada!)}!',
            ),
            backgroundColor: AppColors.violeta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agendar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.backpack_outlined,
                color: AppColors.violeta,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Agendar: ${widget.cita.nombre}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.violeta,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.cita.descripcion,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _fechaSeleccionada != null
                      ? AppColors.violeta
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _fechaSeleccionada != null
                    ? const Color(0xFFEDE9F5)
                    : Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _fechaSeleccionada != null
                        ? AppColors.violeta
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _fechaSeleccionada != null
                        ? _formatearFecha(_fechaSeleccionada!)
                        : 'Selecciona una fecha',
                    style: TextStyle(
                      fontSize: 16,
                      color: _fechaSeleccionada != null
                          ? AppColors.violeta
                          : Colors.grey,
                      fontWeight: _fechaSeleccionada != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: (_fechaSeleccionada == null || _isLoading)
                ? null
                : _agendarCita,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(_isLoading ? 'Agendando...' : 'Confirmar Cita'),
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
    );
  }
}
