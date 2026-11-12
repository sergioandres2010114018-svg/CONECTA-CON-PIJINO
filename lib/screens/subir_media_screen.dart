import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import 'home_shell.dart';

/// Permite a los usuarios compartir fotos y videos de Pijiño.
/// Los aportes quedan "en revisión" hasta que un administrador los aprueba.
class SubirMediaScreen extends StatefulWidget {
  const SubirMediaScreen({super.key});

  @override
  State<SubirMediaScreen> createState() => _SubirMediaScreenState();
}

class _SubirMediaScreenState extends State<SubirMediaScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _desc = TextEditingController();
  final _enlace = TextEditingController();
  final _picker = ImagePicker();

  bool _desdeEnlace = false;
  bool _esVideo = false;
  File? _archivo;
  double? _progreso;
  bool _autoriza = false;

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    _enlace.dispose();
    super.dispose();
  }

  Future<void> _elegir({required bool video, required ImageSource fuente}) async {
    final XFile? x = video
        ? await _picker.pickVideo(source: fuente, maxDuration: const Duration(minutes: 3))
        : await _picker.pickImage(source: fuente, imageQuality: 80, maxWidth: 2000);
    if (x == null) return;
    final f = File(x.path);
    final mb = (await f.length()) / (1024 * 1024);
    final limite = video ? AppConfig.maxMbVideo : AppConfig.maxMbFoto;
    if (mb > limite) {
      if (mounted) mostrarMensaje(context, 'El archivo supera $limite MB.', error: true);
      return;
    }
    setState(() {
      _archivo = f;
      _esVideo = video;
    });
  }

  Future<void> _enviar(bool admin) async {
    if (!_form.currentState!.validate()) return;
    if (!_desdeEnlace && _archivo == null) {
      mostrarMensaje(context, 'Seleccione una foto o un video.', error: true);
      return;
    }
    if (!_autoriza) {
      mostrarMensaje(context, 'Debe confirmar que tiene permiso para compartir este contenido.', error: true);
      return;
    }
    setState(() => _progreso = 0);
    try {
      String url;
      String ruta = '';
      String tipo;
      if (_desdeEnlace) {
        url = _enlace.text.trim();
        tipo = _esVideo ? 'video' : 'foto';
      } else {
        final r = await StorageService.subirArchivo(
          archivo: _archivo!,
          esVideo: _esVideo,
          onProgreso: (p) {
            if (mounted) setState(() => _progreso = p);
          },
        );
        url = r.$1;
        ruta = r.$2;
        tipo = _esVideo ? 'video' : 'foto';
      }
      await DbService.agregarMedia(
        tipo: tipo,
        url: url,
        titulo: _titulo.text.trim(),
        descripcion: _desc.text.trim(),
        aprobado: admin,
        rutaStorage: ruta,
      );
      if (!mounted) return;
      mostrarMensaje(
          context,
          admin
              ? 'Publicado en la galería.'
              : '¡Gracias por su aporte! Será publicado cuando el equipo lo revise.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _progreso = null);
        mostrarMensaje(context, AuthService.mensajeError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = esAdmin(context);
    final subiendo = _progreso != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir foto o video')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text('Desde el celular'), icon: Icon(Icons.phone_android)),
                ButtonSegment<bool>(value: true, label: Text('Enlace (YouTube, web)'), icon: Icon(Icons.link)),
              ],
              selected: <bool>{_desdeEnlace},
              onSelectionChanged: (s) => setState(() => _desdeEnlace = s.first),
            ),
            const SizedBox(height: 16),
            if (!_desdeEnlace) ...<Widget>[
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _archivo == null
                      ? const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 56))
                      : _esVideo
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.videocam, size: 56),
                                  Text('Video seleccionado'),
                                ],
                              ),
                            )
                          : Image.file(_archivo!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    avatar: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Foto de galería'),
                    onPressed: subiendo ? null : () => _elegir(video: false, fuente: ImageSource.gallery),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.photo_camera, size: 18),
                    label: const Text('Tomar foto'),
                    onPressed: subiendo ? null : () => _elegir(video: false, fuente: ImageSource.camera),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.video_library, size: 18),
                    label: const Text('Video de galería'),
                    onPressed: subiendo ? null : () => _elegir(video: true, fuente: ImageSource.gallery),
                  ),
                ],
              ),
            ] else ...<Widget>[
              TextFormField(
                controller: _enlace,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Enlace (https://…)',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) {
                  if (!_desdeEnlace) return null;
                  final u = Uri.tryParse(v?.trim() ?? '');
                  return (u == null || !u.hasScheme || !u.scheme.startsWith('http'))
                      ? 'Ingrese un enlace válido'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _esVideo,
                onChanged: (v) => setState(() => _esVideo = v),
                title: const Text('Es un video'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _titulo,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Título', hintText: 'Ej.: Atardecer en la ciénaga'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Escriba un título' : null,
            ),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              maxLength: 400,
              decoration: const InputDecoration(labelText: 'Descripción (lugar, fecha, personas…)'),
            ),
            CheckboxListTile(
              value: _autoriza,
              onChanged: (v) => setState(() => _autoriza = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Confirmo que tomé esta foto/video o tengo permiso de su autor, y que las personas que aparecen están de acuerdo con su publicación.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            if (subiendo) ...<Widget>[
              LinearProgressIndicator(value: _progreso == 0 ? null : _progreso),
              const SizedBox(height: 8),
              Text('Subiendo… ${((_progreso ?? 0) * 100).toStringAsFixed(0)} %', textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: subiendo ? null : () => _enviar(admin),
              icon: const Icon(Icons.cloud_upload),
              label: Text(admin ? 'Publicar' : 'Enviar para revisión'),
            ),
          ],
        ),
      ),
    );
  }
}
