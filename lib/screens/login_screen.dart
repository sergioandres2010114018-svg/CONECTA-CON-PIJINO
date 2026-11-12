import 'package:flutter/material.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await AuthService.iniciarSesion(_email.text, _pass.text);
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _recuperar() async {
    final ctrl = TextEditingController(text: _email.text);
    final email = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Enviar')),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty) return;
    try {
      await AuthService.recuperarPassword(email);
      if (mounted) mostrarMensaje(context, 'Le enviamos un enlace a $email para cambiar la contraseña.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fondo: foto del malecón de Pijiño con un degradado para que el texto se lea bien.
        decoration: const BoxDecoration(
          color: AppColors.cafe,
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_login.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Color(0x99000000), Color(0x33000000), Color(0xCC3A1F0D)],
              stops: <double>[0, 0.45, 1],
            ),
          ),
          child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.png', width: 130, height: 130, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(AppConfig.appName,
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('“${AppConfig.slogan}”',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Text('Iniciar sesión',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const <String>[AutofillHints.email],
                              decoration: const InputDecoration(
                                  labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
                              validator: (v) => (v == null || !v.contains('@')) ? 'Ingrese un correo válido' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _pass,
                              obscureText: _ocultar,
                              autofillHints: const <String>[AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _ocultar = !_ocultar),
                                ),
                              ),
                              onFieldSubmitted: (_) => _entrar(),
                              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: _recuperar, child: const Text('¿Olvidó su contraseña?')),
                            ),
                            FilledButton(
                              onPressed: _cargando ? null : _entrar,
                              child: _cargando
                                  ? const SizedBox(
                                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                                  : const Text('Entrar'),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                              onPressed: () => Navigator.push(
                                  context, MaterialPageRoute<void>(builder: (_) => const RegisterScreen())),
                              child: const Text('Crear una cuenta nueva'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const CreditosFooter(claro: true),
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
