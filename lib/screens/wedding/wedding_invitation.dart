import 'package:flutter/material.dart';
import '../../services/wedding_service.dart';

const Color _rose = Color(0xFFE91E63);

class WeddingInvitationScreen extends StatefulWidget {
  const WeddingInvitationScreen({super.key});

  @override
  State<WeddingInvitationScreen> createState() => _WeddingInvitationScreenState();
}

class _WeddingInvitationScreenState extends State<WeddingInvitationScreen> {
  final WeddingService _service = WeddingService();
  WeddingMeta? _meta;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final meta = await _service.getPrimaryWedding();
      if (!mounted) return;
      setState(() {
        _meta = meta;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final nombre = meta?.nombre ?? 'Nuestra boda';
    final fecha = meta?.fechaEvento ?? 'Por definir';
    final lugar = meta?.lugar ?? 'Por definir';
    final direccion = meta?.direccion ?? 'Por definir';
    final contacto = meta?.contacto ?? 'Sin contacto';
    final dressCode = meta?.dressCode ?? 'Por definir';
    final hashtag = meta?.instagramHashtag ?? '#NuestraBoda';

    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Invitación', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _rose),
            onPressed: _loadInvitation,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _rose))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: _rose, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar la invitación',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadInvitation,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('💍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              nombre,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _rose,
                fontFamily: 'Serif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _meta?.mensajeBienvenida ?? 'Tienen el honor de invitarte\na su boda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF880E4F),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              Icons.calendar_today,
              'Fecha',
              fecha,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.location_on, 'Lugar', lugar),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.map_outlined, 'Dirección', direccion),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.checkroom_outlined, 'Dress code', dressCode),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.phone_outlined, 'Contacto', contacto),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              hashtag,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: _rose, size: 22),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _rose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
