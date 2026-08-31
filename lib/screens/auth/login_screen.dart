import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/colors.dart';

enum _AuthMode { login, signup, confirm }

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final AuthService _authService = AuthService.instance;

  _AuthMode _mode = _AuthMode.login;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      switch (_mode) {
        case _AuthMode.login:
          await _authService.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
          widget.onLoginSuccess?.call();
          break;
        case _AuthMode.signup:
          final result = await _authService.signUp(
            email: _emailController.text,
            password: _passwordController.text,
            name: _nameController.text,
          );
          if (!mounted) return;
          if (result.confirmed) {
            _setMode(_AuthMode.login);
          } else {
            _setMode(_AuthMode.confirm);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message)),
          );
          break;
        case _AuthMode.confirm:
          await _authService.confirmAccount(
            email: _emailController.text,
            code: _codeController.text,
          );
          if (!mounted) return;
          _setMode(_AuthMode.login);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta confirmada. Inicia sesión.')),
          );
          break;
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Escribe el correo de la cuenta');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _authService.resendConfirmationCode(_emailController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavanda,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 52,
                      color: AppColors.violeta,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _mode == _AuthMode.confirm
                          ? 'Confirma tu correo'
                          : 'Nuestras fechas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.violeta,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_mode != _AuthMode.confirm)
                      SegmentedButton<_AuthMode>(
                        segments: const [
                          ButtonSegment(
                            value: _AuthMode.login,
                            icon: Icon(Icons.login),
                            label: Text('Ingresar'),
                          ),
                          ButtonSegment(
                            value: _AuthMode.signup,
                            icon: Icon(Icons.person_add_outlined),
                            label: Text('Crear cuenta'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (selection) =>
                            _setMode(selection.first),
                      ),
                    if (_mode == _AuthMode.confirm)
                      Text(
                        'Escribe el código enviado a ${_emailController.text.trim()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    const SizedBox(height: 24),
                    if (_mode == _AuthMode.signup) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Escribe tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_mode != _AuthMode.confirm)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Escribe un correo válido';
                          }
                          return null;
                        },
                      ),
                    if (_mode != _AuthMode.confirm) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.length < 8
                            ? 'Usa al menos 8 caracteres'
                            : null,
                      ),
                    ] else
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Código de confirmación',
                          prefixIcon: Icon(Icons.verified_user_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Escribe el código'
                            : null,
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _mode == _AuthMode.login
                                  ? Icons.login
                                  : _mode == _AuthMode.signup
                                  ? Icons.person_add_outlined
                                  : Icons.verified_outlined,
                            ),
                      label: Text(
                        _isLoading
                            ? 'Procesando...'
                            : _mode == _AuthMode.login
                            ? 'Iniciar sesión'
                            : _mode == _AuthMode.signup
                            ? 'Crear cuenta'
                            : 'Confirmar cuenta',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.violeta,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    if (_mode == _AuthMode.confirm) ...[
                      TextButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: const Text('Reenviar código'),
                      ),
                      TextButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _setMode(_AuthMode.login),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver al inicio de sesión'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
