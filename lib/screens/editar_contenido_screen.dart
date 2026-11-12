import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';

/// Formulario de administración para crear o editar contenidos.
class EditarContenidoScreen extends StatefulWidget {
  final Contenido? contenido;
  final String? categoriaInicial;
  const EditarContenidoScreen({super.key, this.contenido, this.categoriaInicial});

  @override
  State<EditarContenidoScreen> createState() => _EditarContenidoScreenState();
}

class _EditarContenidoScreenState extends State<EditarContenidoScreen> {
  final _form = GlobalKey<FormState>();
  late final Contenido? c = widget.contenido;
  late String _categoria = c?.categoria ?? widget.categoriaInicial ?? Categoria.todas.first.id;
  late final _titulo = TextEditingController(text: c?.titulo ?? '');
  late final _resumen = TextEditingController(text: c?.resumen ?? '');
  late final _cuerpo = TextEditingController(text: c?.cuerpo ?? '');
  late final _imagen = TextEditingController(text: c?.imagenUrl ?? '');
  late final _video = TextEditingController(text: c?.videoUrl ?? '');
  late final _lugar = TextEditingController(text: c?.lugar ?? '');
  late final _lat = TextEditingController(text: c?.lat?.toString() ?? '');
  late final _lng = TextEditingController(text: c?.lng?.toString() ?? '');
  late final _orden = TextEditingController(text: (c?.orden ?? 0).toString());
  late final _fuente = TextEditingController(text: c?.fuente ?? '');
  late final _fuenteUrl = TextEditingController(text: c?.fuenteUrl ?? '');
  late final _imagenes = TextEditingController(text: (c?.imagenes ?? const <String>[]).join('\n'));
  late DateTime? _fecha = c?.fecha;
  late bool _validado = c?.validado ?? false;
  bool _guardando = false;
  bool _subiendoImg = false;

  @override
  void dispose() {
    for (final t in <TextEditingController>[
      _titulo, _resumen, _cuerpo, _imagen, _video, _lugar, _lat, _lng, _orden, _fuente, _fuenteUrl, _imagenes
    ]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _subirImagen() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1800);
    if (x == null) return;
    setState(() => _subiendoImg = true);
    try {
      final ref = FirebaseStorage.instance.ref('contenidos/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(x.path), SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      setState(() => _imagen.text = url);
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _subiendoImg = false);
    }
  }

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final h = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha ?? DateTime(2000, 1, 1, 8)),
    );
    setState(() => _fecha = DateTime(d.year, d.month, d.day, h?.hour ?? 8, h?.minute ?? 0));
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await DbService.guardarContenido(Contenido(
        id: c?.id ?? '',
        categoria: _categoria,
        titulo: _titulo.text.trim(),
        resumen: _resumen.text.trim(),
        cuerpo: _cuerpo.text.trim(),
        imagenUrl: _imagen.text.trim(),
        videoUrl: _video.text.trim(),
        lugar: _lugar.text.trim(),
        fecha: _fecha,
        lat: double.tryParse(_lat.text.replaceAll(',', '.')),
        lng: double.tryParse(_lng.text.replaceAll(',', '.')),
        orden: int.tryParse(_orden.text) ?? 0,
        validado: _validado,
        fuente: _fuente.text.trim(),
        fuenteUrl: _fuenteUrl.text.trim(),
        imagenes: _imagenes.text
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
      ));
      if (!mounted) return;
      mostrarMensaje(context, 'Publicación guardada.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _validarCoord(String? v, double max) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.replaceAll(',', '.'));
    return (n == null || n.abs() > max) ? 'Valor no válido' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(c == null ? 'Nueva publicación' : 'Editar publicación')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: Categoria.todas
                  .map((k) => DropdownMenuItem<String>(value: k.id, child: Text(k.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _resumen,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Resumen (una línea)'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cuerpo,
              minLines: 6,
              maxLines: 20,
              decoration: const InputDecoration(labelText: 'Texto completo', alignLabelWithHint: true),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _imagen,
                    decoration: const InputDecoration(labelText: 'URL de imagen'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Subir imagen',
                  onPressed: _subiendoImg ? null : _subirImagen,
                  icon: _subiendoImg
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload),
                ),
              ],
            ),
            if (_imagen.text.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(height: 140, child: NetImage(_imagen.text)),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _imagenes,
              minLines: 2,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'Fotos adicionales (una URL por línea)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _video,
              decoration: const InputDecoration(labelText: 'URL de video (YouTube o MP4, opcional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _lugar, decoration: const InputDecoration(labelText: 'Lugar')),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitud'),
                    validator: (v) => _validarCoord(v, 90),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitud'),
                    validator: (v) => _validarCoord(v, 180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(_fecha == null ? 'Sin fecha' : formatoFecha(_fecha!, hora: true)),
              subtitle: const Text('Para eventos y fiestas'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_fecha != null)
                    IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _fecha = null)),
                  TextButton(onPressed: _elegirFecha, child: const Text('Elegir')),
                ],
              ),
            ),
            TextFormField(
              controller: _orden,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Orden en la lista'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _fuente, decoration: const InputDecoration(labelText: 'Fuente')),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fuenteUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Enlace de la fuente (opcional)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _validado,
              onChanged: (v) => setState(() => _validado = v),
              title: const Text('Contenido validado con la comunidad'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(_guardando ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
