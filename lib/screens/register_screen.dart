import 'package:flutter/material.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../widgets/common.dart';

/// Registro de usuarios. Los datos se guardan en Firebase Authentication
/// y en la colección `usuarios` de Cloud Firestore.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  String _tipo = AppConfig.tiposUsuario.first;
  bool _acepta = false;
  bool _ocultar = true;
  bool _cargando = false;

  @override
  void dispose() {
    for (final c in <TextEditingController>[_nombre, _email, _telefono, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    if (!_acepta) {
      mostrarMensaje(context, 'Debe aceptar la política de tratamiento de datos.', error: true);
      return;
    }
    setState(() => _cargando = true);
    try {
      await AuthService.registrar(
        nombre: _nombre.text,
        email: _email.text,
        password: _pass.text,
        telefono: _telefono.text,
        tipoUsuario: _tipo,
      );
      if (!mounted) return;
      mostrarMensaje(context, '¡Bienvenido(a) a Conecta con Pijiño!');
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _verPolitica() {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tratamiento de datos personales'),
        content: const SingleChildScrollView(
          child: Text(
            'En cumplimiento de la Ley 1581 de 2012 (Colombia), al registrarse usted autoriza al proyecto '
            'APP-Conecta con Pijiño (IEDT Pijiño del Carmen) a almacenar su nombre, correo, teléfono y tipo de usuario '
            'con el único fin de gestionar su cuenta, permitir su participación en la app y generar estadísticas '
            'anónimas de uso.\n\n'
            'Sus datos no serán vendidos ni compartidos con terceros. Puede solicitar la consulta, corrección o '
            'eliminación de sus datos desde la sección "Contacto y participación" de la aplicación.\n\n'
            'Las fotos y videos que usted comparta se publicarán con su nombre, después de ser revisados por el equipo.',
          ),
        ),
        actions: <Widget>[
          FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Entendido')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: <Widget>[
              const Text('Únete a la comunidad digital de Pijiño del Carmen.',
                  style: TextStyle(fontSize: 15)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Ingrese su nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.mail_outline)),
                validator: (v) {
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v?.trim() ?? '');
                  return ok ? null : 'Ingrese un correo válido';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Celular (opcional)', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return null;
                  return RegExp(r'^[0-9 +]{7,15}$').hasMatch(t) ? null : 'Número no válido';
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Yo soy…', prefixIcon: Icon(Icons.badge_outlined)),
                items: AppConfig.tiposUsuario
                    .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _tipo = v ?? _tipo),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass,
                obscureText: _ocultar,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pass2,
                obscureText: _ocultar,
                decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_reset)),
                validator: (v) => v != _pass.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _acepta,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _acepta = v ?? false),
                title: Wrap(
                  children: <Widget>[
                    const Text('Acepto la '),
                    GestureDetector(
                      onTap: _verPolitica,
                      child: Text('política de tratamiento de datos',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _cargando ? null : _registrar,
                child: _cargando
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Registrarme'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ya tengo cuenta, iniciar sesión'),
              ),
              const CreditosFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
