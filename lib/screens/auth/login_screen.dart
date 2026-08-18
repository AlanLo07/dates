import 'package:flutter/material.dart';
import '../../utils/colors.dart';

/// Login deshabilitado: placeholder para evitar referencias rotas.
class LoginScreen extends StatelessWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Login deshabilitado', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
