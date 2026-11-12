import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import 'media_viewer_screen.dart';
import 'subir_media_screen.dart';

/// Galería multimedia: fotos y videos de Pijiño guardados en la base de datos.
class GaleriaScreen extends StatefulWidget {
  const GaleriaScreen({super.key});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  String _filtro = 'todo'; // todo | foto | video | mios

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.usuarioActual?.uid ?? '';
    final stream = _filtro == 'mios' ? DbService.misAportes(uid) : DbService.galeriaAprobada();

    return Scaffold(
      appBar: AppBar(title: const Text('Galería')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SubirMediaScreen())),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Compartir'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<String>>[
                ButtonSegment<String>(value: 'todo', label: Text('Todo')),
                ButtonSegment<String>(value: 'foto', label: Text('Fotos'), icon: Icon(Icons.photo, size: 16)),
                ButtonSegment<String>(value: 'video', label: Text('Videos'), icon: Icon(Icons.videocam, size: 16)),
                ButtonSegment<String>(value: 'mios', label: Text('Míos')),
              ],
              selected: <String>{_filtro},
              onSelectionChanged: (s) => setState(() => _filtro = s.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MediaItem>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Vacio(icono: Icons.cloud_off, texto: 'No se pudo cargar la galería.\n${snap.error}');
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                var lista = snap.data!;
                if (_filtro == 'foto' || _filtro == 'video') {
                  lista = lista.where((m) => m.tipo == _filtro).toList();
                }
                if (lista.isEmpty) {
                  return Vacio(
                    icono: Icons.photo_library_outlined,
                    texto: _filtro == 'mios'
                        ? 'Aún no ha compartido fotos o videos.\n¡Sea el primero en aportar!'
                        : 'Todavía no hay elementos en la galería.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: lista.length,
                  itemBuilder: (_, i) => _MediaCard(lista[i], mostrarEstado: _filtro == 'mios'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem item;
  final bool mostrarEstado;
  const _MediaCard(this.item, {this.mostrarEstado = false});

  @override
  Widget build(BuildContext context) {
    final miniatura = item.esVideo ? (item.miniaturaYoutube ?? '') : item.url;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (item.esYoutube) {
            abrirEnlace(context, item.url);
          } else {
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => MediaViewerScreen(item: item)));
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Hero(
                    tag: 'media-${item.id}',
                    child: NetImage(miniatura, iconoVacio: item.esVideo ? Icons.videocam : Icons.image),
                  ),
                  if (item.esVideo)
                    const Center(
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0x99000000),
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
                      ),
                    ),
                  if (mostrarEstado)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.aprobado ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(item.aprobado ? 'Publicado' : 'En revisión',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Por ${item.autorNombre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
