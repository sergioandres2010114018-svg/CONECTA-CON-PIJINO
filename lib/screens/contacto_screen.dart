import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';

/// Mecanismo de participación: sugerencias, aportes, correcciones y registro de negocios.
class ContactoScreen extends StatefulWidget {
  final String? tipoInicial;
  final String? textoInicial;
  const ContactoScreen({super.key, this.tipoInicial, this.textoInicial});

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  static const List<String> tipos = <String>[
    'Sugerencia',
    'Aporte de historia o tradición',
    'Corrección de contenido',
    'Registrar mi negocio',
    'Reportar un problema en la app',
    'Mis datos personales',
  ];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _msg = TextEditingController(text: widget.textoInicial ?? '');
  late String _tipo = tipos.contains(widget.tipoInicial) ? widget.tipoInicial! : tipos.first;
  bool _enviando = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await DbService.enviarMensaje(tipo: _tipo, mensaje: _msg.text.trim());
      if (!mounted) return;
      mostrarMensaje(context, '¡Mensaje enviado! Gracias por participar.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacto y participación')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              'Esta app se construye con la comunidad. Cuéntenos historias, recetas, fiestas, correcciones '
              'o ideas para mejorar Conecta con Pijiño.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Tipo de mensaje'),
              items: tipos.map((t) => DropdownMenuItem<String>(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _msg,
              minLines: 6,
              maxLines: 12,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Mensaje', alignLabelWithHint: true),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Escriba al menos 10 caracteres' : null,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.send),
              label: Text(_enviando ? 'Enviando…' : 'Enviar'),
            ),
            const SizedBox(height: 24),
            const Card(
              child: ListTile(
                leading: Icon(Icons.school_outlined),
                title: Text('IEDT Pijiño del Carmen'),
                subtitle: Text('Programa Técnico en Programación de Aplicaciones para Dispositivos Móviles – SENA'),
              ),
            ),
            const CreditosFooter(),
          ],
        ),
      ),
    );
  }
}
