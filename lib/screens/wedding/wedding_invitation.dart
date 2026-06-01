import 'package:flutter/material.dart';
import 'wedding.dart'; // kWeddingDate

const Color _rose = Color(0xFFE91E63);

class WeddingInvitationScreen extends StatelessWidget {
  const WeddingInvitationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE4EC),
      appBar: AppBar(
        title: const Text('Invitación', style: TextStyle(color: _rose)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: _rose),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text('💍', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Nati & Alan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _rose,
                fontFamily: 'Serif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tienen el honor de invitarte\na su boda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF880E4F),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              Icons.calendar_today,
              'Fecha',
              '14 de Febrero, 2027',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.access_time, 'Hora', '17:00 hrs'),
            const SizedBox(height: 12),
            _buildInfoCard(Icons.location_on, 'Lugar', 'Por definir'),
            const SizedBox(height: 12),
            _buildInfoCard(
              Icons.restaurant,
              'Recepción',
              'Inmediatamente después',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Confirma tu asistencia antes del\n31 de Enero, 2027',
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
