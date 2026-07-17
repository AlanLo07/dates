import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/boda.dart';
import 'wedding_service.dart';

class WeddingPdfExportService {
  WeddingPdfExportService({WeddingService? weddingService})
    : _weddingService = weddingService ?? WeddingService();

  final WeddingService _weddingService;
  final NumberFormat _currency = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );

  Future<void> exportWeddingPdf() async {
    final document = await _buildDocument();
    final bytes = await document.save();
    await Printing.sharePdf(bytes: bytes, filename: _buildFileName());
  }

  Future<Uint8List> buildWeddingPdfBytes() async {
    final document = await _buildDocument();
    return document.save();
  }

  Future<pw.Document> _buildDocument() async {
    final meta = await _weddingService.getPrimaryWedding();
    if (meta == null || meta.id.isEmpty) {
      throw Exception('No hay una boda activa para exportar.');
    }

    final invitados = await _safeFetch(() => _weddingService.getInvitados(meta.id));
    final tareas = await _safeFetch(() => _weddingService.getTareas(meta.id));
    final itinerario = await _safeFetch(() => _weddingService.getItinerario(meta.id));
    final gastos = await _safeFetch(() => _weddingService.getGastos(meta.id));
    final canciones = await _safeFetch(() => _weddingService.getCanciones(meta.id));
    final looks = await _safeFetch(() => _weddingService.getLooks(meta.id));
    final proveedores = await _safeFetch(() => _weddingService.getProveedores(meta.id));

    final document = pw.Document();
    final totalEstimado = gastos.fold<double>(0, (sum, item) => sum + item.estimado);
    final totalPagado = gastos.fold<double>(0, (sum, item) => sum + item.pagado);
    final totalConfirmados = invitados
        .where((item) => item.rsvp == RsvpStatus.confirmado)
        .fold<int>(0, (sum, item) => sum + item.personas);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          _buildHeader(meta),
          pw.SizedBox(height: 18),
          _buildSummary(meta, invitados.length, totalConfirmados, tareas, totalEstimado, totalPagado),
          pw.SizedBox(height: 18),
          _buildInvitationSection(meta),
          pw.SizedBox(height: 14),
          _buildChecklistSection(tareas),
          pw.SizedBox(height: 14),
          _buildTimelineSection(itinerario),
          pw.SizedBox(height: 14),
          _buildBudgetSection(gastos),
          pw.SizedBox(height: 14),
          _buildPlaylistSection(canciones),
          pw.SizedBox(height: 14),
          _buildLooksSection(looks),
          pw.SizedBox(height: 14),
          _buildProvidersSection(proveedores),
        ],
      ),
    );

    return document;
  }

  Future<List<T>> _safeFetch<T>(Future<List<T>> Function() loader) async {
    try {
      return await loader();
    } catch (_) {
      return <T>[];
    }
  }

  String _buildFileName() {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return 'resumen_boda_$stamp.pdf';
  }

  pw.Widget _buildHeader(WeddingMeta meta) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FCE4EC'),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            meta.nombre,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#AD1457'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Resumen general de planeacion de boda',
            style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#6D4C57')),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(
    WeddingMeta meta,
    int totalInvitados,
    int confirmados,
    List<TareaBoda> tareas,
    double totalEstimado,
    double totalPagado,
  ) {
    final tareasCompletadas = tareas.where((item) => item.completada).length;
    return pw.Row(
      children: [
        _buildMetricCard('Fecha', meta.fechaEvento ?? 'Pendiente'),
        _buildMetricCard('Invitados', '$totalInvitados registrados'),
        _buildMetricCard('Confirmados', '$confirmados asistentes'),
        _buildMetricCard('Checklist', '$tareasCompletadas/${tareas.length} listo'),
        _buildMetricCard('Presupuesto', _currency.format(totalEstimado)),
        _buildMetricCard('Pagado', _currency.format(totalPagado)),
      ],
    );
  }

  pw.Widget _buildMetricCard(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColor.fromHex('#F8BBD0')),
          borderRadius: pw.BorderRadius.circular(12),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildInvitationSection(WeddingMeta meta) {
    return _buildSection(
      title: 'Invitacion',
      children: [
        _buildKeyValue('Lugar', meta.lugar),
        _buildKeyValue('Fecha', meta.fechaEvento),
        _buildKeyValue('Direccion', meta.direccion),
        _buildKeyValue('Contacto', meta.contacto),
        _buildKeyValue('Dress code', meta.dressCode),
        _buildKeyValue('Hashtag', meta.instagramHashtag),
        _buildKeyValue('Mensaje', meta.mensajeBienvenida),
      ],
    );
  }

  pw.Widget _buildChecklistSection(List<TareaBoda> tareas) {
    final pendientes = tareas.where((item) => !item.completada).toList();
    final completadas = tareas.where((item) => item.completada).length;
    return _buildSection(
      title: 'Checklist',
      subtitle: '${tareas.length} tareas registradas, $completadas completadas',
      children: tareas.isEmpty
          ? [_buildEmpty('No hay tareas registradas.')]
          : pendientes.take(8).map((item) {
              final fecha = item.fechaLimite?.trim().isNotEmpty == true
                  ? ' · Limite ${item.fechaLimite}'
                  : '';
              return _buildBullet('${item.titulo} (${item.categoria})$fecha');
            }).toList(),
    );
  }

  pw.Widget _buildTimelineSection(List<PasoBoda> itinerario) {
    return _buildSection(
      title: 'Itinerario',
      children: itinerario.isEmpty
          ? [_buildEmpty('No hay pasos en el itinerario.')]
          : itinerario.take(10).map((item) {
              final nota = item.nota.trim().isNotEmpty ? ' · ${item.nota}' : '';
              return _buildBullet('${item.hora} - ${item.titulo}$nota');
            }).toList(),
    );
  }

  pw.Widget _buildBudgetSection(List<GastoBoda> gastos) {
    final totalEstimado = gastos.fold<double>(0, (sum, item) => sum + item.estimado);
    final totalPagado = gastos.fold<double>(0, (sum, item) => sum + item.pagado);
    return _buildSection(
      title: 'Presupuesto',
      subtitle:
          'Estimado ${_currency.format(totalEstimado)} · Pagado ${_currency.format(totalPagado)}',
      children: gastos.isEmpty
          ? [_buildEmpty('No hay gastos registrados.')]
          : gastos.take(10).map((item) {
              return _buildBullet(
                '${item.concepto} (${item.categoria}) · ${_currency.format(item.pagado)} de ${_currency.format(item.estimado)}',
              );
            }).toList(),
    );
  }

  pw.Widget _buildPlaylistSection(List<CancionBoda> canciones) {
    return _buildSection(
      title: 'Playlist',
      subtitle: '${canciones.length} canciones registradas',
      children: canciones.isEmpty
          ? [_buildEmpty('No hay canciones registradas.')]
          : canciones.take(10).map((item) {
              return _buildBullet('${item.titulo} · ${item.artista} (${item.momento})');
            }).toList(),
    );
  }

  pw.Widget _buildLooksSection(List<LookBoda> looks) {
    final comprados = looks.where((item) => item.comprado).length;
    return _buildSection(
      title: 'Look',
      subtitle: '${looks.length} piezas registradas, $comprados compradas',
      children: looks.isEmpty
          ? [_buildEmpty('No hay looks registrados.')]
          : looks.take(10).map((item) {
              final tienda = item.tienda.trim().isNotEmpty ? ' · ${item.tienda}' : '';
              return _buildBullet('${item.persona}: ${item.prenda}$tienda');
            }).toList(),
    );
  }

  pw.Widget _buildProvidersSection(List<ProveedorBoda> proveedores) {
    return _buildSection(
      title: 'Proveedores',
      subtitle: '${proveedores.length} proveedores registrados',
      children: proveedores.isEmpty
          ? [_buildEmpty('No hay proveedores registrados.')]
          : proveedores.take(10).map((item) {
              final contacto = item.contacto.trim().isNotEmpty ? ' · ${item.contacto}' : '';
              return _buildBullet(
                '${item.nombre} (${item.categoria}) · ${item.estado.label}$contacto',
              );
            }).toList(),
    );
  }

  pw.Widget _buildSection({
    required String title,
    String? subtitle,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#E1BEE7')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#6A1B9A'),
            ),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildKeyValue(String label, String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: normalized),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• '),
          pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 10.5))),
        ],
      ),
    );
  }

  pw.Widget _buildEmpty(String text) {
    return pw.Text(text, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700));
  }
}