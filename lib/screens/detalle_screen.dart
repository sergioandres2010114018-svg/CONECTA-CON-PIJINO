import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import 'contacto_screen.dart';
import 'editar_contenido_screen.dart';
import 'home_shell.dart';
import 'media_viewer_screen.dart';

class DetalleScreen extends StatelessWidget {
  final Contenido contenido;
  const DetalleScreen({super.key, required this.contenido});

  @override
  Widget build(BuildContext context) {
    // Se escucha el documento para reflejar ediciones en tiempo real.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: contenido.id.isEmpty ? null : DbService.contenidos.doc(contenido.id).snapshots(),
      builder: (context, snap) {
        final data = snap.data;
        final c = (data != null && data.exists) ? Contenido.fromDoc(data) : contenido;
        return _construir(context, c);
      },
    );
  }

  Widget _construir(BuildContext context, Contenido c) {
    final cat = Categoria.porId(c.categoria);
    final usuario = context.watch<Usuario?>();
    final favorito = usuario?.favoritos.contains(c.id) ?? false;
    final admin = esAdmin(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            foregroundColor: Colors.white,
            backgroundColor: cat.color,
            actions: <Widget>[
              IconButton(
                tooltip: favorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
                icon: Icon(favorito ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  final uid = AuthService.usuarioActual?.uid;
                  if (uid == null) return;
                  DbService.alternarFavorito(uid, c.id, !favorito);
                },
              ),
              if (admin)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'editar') {
                      Navigator.push(context,
                          MaterialPageRoute<void>(builder: (_) => EditarContenidoScreen(contenido: c)));
                    } else if (v == 'eliminar') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          title: const Text('¿Eliminar publicación?'),
                          content: Text('Se eliminará "${c.titulo}" de la base de datos.'),
                          actions: <Widget>[
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
                            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Eliminar')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await DbService.eliminarContenido(c.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'editar', child: Text('Editar')),
                    PopupMenuItem<String>(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Hero(
                    tag: 'img-${c.id}',
                    child: NetImage(c.imagenUrl, iconoVacio: cat.icono, colorVacio: cat.color),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x66000000), Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(cat.icono, size: 16, color: cat.color),
                      const SizedBox(width: 6),
                      Text(cat.nombre.toUpperCase(),
                          style: TextStyle(
                              color: cat.color, fontWeight: FontWeight.w800, letterSpacing: 1.1, fontSize: 12)),
                      const Spacer(),
                      EtiquetaValidacion(c.validado),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(c.titulo,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(c.resumen, style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  if (c.fecha != null)
                    _Dato(icono: Icons.event, texto: formatoFecha(c.fecha!, hora: true)),
                  if (c.lugar.isNotEmpty) _Dato(icono: Icons.place_outlined, texto: c.lugar),
                  if (c.imagenes.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 96,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: c.imagenes.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final url = c.imagenes[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => MediaViewerScreen(
                                  item: MediaItem(
                                    id: '${c.id}-foto-$i',
                                    tipo: 'foto',
                                    url: url,
                                    titulo: c.titulo,
                                    descripcion: c.fuente,
                                    autorUid: '',
                                    autorNombre: 'Conecta con Pijiño',
                                    aprobado: true,
                                  ),
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(width: 120, child: NetImage(url)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const Divider(height: 28),
                  SelectableText(c.cuerpo, style: const TextStyle(fontSize: 16, height: 1.55)),
                  const SizedBox(height: 18),
                  if (c.videoUrl.isNotEmpty)
                    FilledButton.icon(
                      icon: const Icon(Icons.play_circle),
                      label: const Text('Ver video'),
                      onPressed: () {
                        final m = MediaItem(
                          id: c.id,
                          tipo: 'video',
                          url: c.videoUrl,
                          titulo: c.titulo,
                          descripcion: c.resumen,
                          autorUid: '',
                          autorNombre: 'Conecta con Pijiño',
                          aprobado: true,
                        );
                        if (m.esYoutube) {
                          abrirEnlace(context, m.url);
                        } else {
                          Navigator.push(
                              context, MaterialPageRoute<void>(builder: (_) => MediaViewerScreen(item: m)));
                        }
                      },
                    ),
                  if (c.lugar.isNotEmpty || c.tieneUbicacion) ...<Widget>[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.directions),
                      label: const Text('Cómo llegar'),
                      onPressed: () {
                        final destino = c.tieneUbicacion
                            ? '${c.lat},${c.lng}'
                            : Uri.encodeComponent('${c.lugar}, Pijiño del Carmen, Magdalena');
                        abrirEnlace(context, 'https://www.google.com/maps/search/?api=1&query=$destino');
                      },
                    ),
                  ],
                  if (c.fuente.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Text('Fuente: ${c.fuente}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                  ],
                  if (c.fuenteUrl.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Ver fuente'),
                        onPressed: () => abrirEnlace(context, c.fuenteUrl),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('¿Conoce más o hay un error? Cuéntenos'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ContactoScreen(
                          tipoInicial: 'Corrección de contenido',
                          textoInicial: 'Sobre "${c.titulo}": ',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: CreditosFooter()),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final IconData icono;
  final String texto;
  const _Dato({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: <Widget>[
            Icon(icono, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
