import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';
import 'editar_contenido_screen.dart';
import 'media_viewer_screen.dart';

/// Panel de administración: aprobaciones, usuarios registrados, mensajes y datos.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Administración'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: <Tab>[
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Aprobar'),
              Tab(icon: Icon(Icons.people_outline), text: 'Usuarios'),
              Tab(icon: Icon(Icons.mail_outline), text: 'Mensajes'),
              Tab(icon: Icon(Icons.storage_outlined), text: 'Datos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[_Aprobaciones(), _Usuarios(), _Mensajes(), _Datos()],
        ),
      ),
    );
  }
}

class _Aprobaciones extends StatelessWidget {
  const _Aprobaciones();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaItem>>(
      stream: DbService.galeriaPendiente(),
      builder: (context, snap) {
        if (snap.hasError) return Vacio(icono: Icons.error_outline, texto: '${snap.error}');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final l = snap.data!;
        if (l.isEmpty) return const Vacio(icono: Icons.done_all, texto: 'No hay aportes pendientes.');
        return ListView.builder(
          itemCount: l.length,
          itemBuilder: (_, i) {
            final m = l[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  InkWell(
                    onTap: () => m.esYoutube
                        ? abrirEnlace(context, m.url)
                        : Navigator.push(
                            context, MaterialPageRoute<void>(builder: (_) => MediaViewerScreen(item: m))),
                    child: SizedBox(
                      height: 180,
                      child: NetImage(m.esVideo ? (m.miniaturaYoutube ?? '') : m.url,
                          iconoVacio: m.esVideo ? Icons.videocam : Icons.image),
                    ),
                  ),
                  ListTile(
                    title: Text(m.titulo),
                    subtitle: Text('${m.autorNombre}\n${m.descripcion}'),
                    isThreeLine: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Rechazar'),
                            onPressed: () async {
                              await StorageService.eliminar(m.rutaStorage);
                              await DbService.eliminarMedia(m.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                            icon: const Icon(Icons.check),
                            label: const Text('Aprobar'),
                            onPressed: () => DbService.aprobarMedia(m.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Usuarios extends StatelessWidget {
  const _Usuarios();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Usuario>>(
      stream: DbService.todosLosUsuarios(),
      builder: (context, snap) {
        if (snap.hasError) return Vacio(icono: Icons.error_outline, texto: '${snap.error}');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final l = snap.data!;
        final miUid = AuthService.usuarioActual?.uid;
        return ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${l.length} usuarios registrados',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            for (final u in l)
              ListTile(
                leading: CircleAvatar(child: Text(u.nombre.isEmpty ? '?' : u.nombre[0].toUpperCase())),
                title: Text(u.nombre),
                subtitle: Text('${u.email}\n${u.tipoUsuario}'
                    '${u.creadoEn != null ? ' · ${formatoFecha(u.creadoEn!)}' : ''}'),
                isThreeLine: true,
                trailing: u.uid == miUid
                    ? const Chip(label: Text('Tú'))
                    : PopupMenuButton<String>(
                        icon: Icon(u.esAdmin ? Icons.admin_panel_settings : Icons.more_vert),
                        onSelected: (rol) => DbService.cambiarRol(u.uid, rol),
                        itemBuilder: (_) => <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                              value: u.esAdmin ? 'usuario' : 'admin',
                              child: Text(u.esAdmin ? 'Quitar administrador' : 'Hacer administrador')),
                        ],
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _Mensajes extends StatelessWidget {
  const _Mensajes();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Mensaje>>(
      stream: DbService.todosLosMensajes(),
      builder: (context, snap) {
        if (snap.hasError) return Vacio(icono: Icons.error_outline, texto: '${snap.error}');
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final l = snap.data!;
        if (l.isEmpty) return const Vacio(icono: Icons.mail_outline, texto: 'No hay mensajes.');
        return ListView.builder(
          itemCount: l.length,
          itemBuilder: (_, i) {
            final m = l[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ExpansionTile(
                leading: Icon(m.leido ? Icons.drafts_outlined : Icons.mark_email_unread,
                    color: m.leido ? null : Theme.of(context).colorScheme.primary),
                title: Text(m.tipo, style: TextStyle(fontWeight: m.leido ? FontWeight.normal : FontWeight.w800)),
                subtitle: Text('${m.nombre} · ${m.creadoEn != null ? formatoFecha(m.creadoEn!, hora: true) : ''}'),
                onExpansionChanged: (abierto) {
                  if (abierto && !m.leido) DbService.marcarLeido(m.id);
                },
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SelectableText(m.mensaje),
                  const SizedBox(height: 8),
                  if (m.email.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.reply),
                      label: Text('Responder a ${m.email}'),
                      onPressed: () => abrirEnlace(
                          context, 'mailto:${m.email}?subject=${Uri.encodeComponent('Conecta con Pijiño: ${m.tipo}')}'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Datos extends StatefulWidget {
  const _Datos();

  @override
  State<_Datos> createState() => _DatosState();
}

class _DatosState extends State<_Datos> {
  bool _cargando = false;

  Future<void> _seed(bool forzar) async {
    setState(() => _cargando = true);
    try {
      final n = await SeedData.cargar(forzar: forzar);
      if (mounted) {
        mostrarMensaje(context,
            n == 0 ? 'La base de datos ya tiene contenido. Use "Restaurar" para sobrescribir.' : 'Se cargaron $n registros.');
      }
    } catch (e) {
      if (mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: ListTile(
            leading: const Icon(Icons.post_add),
            title: const Text('Nueva publicación'),
            subtitle: const Text('Historia, cultura, gastronomía, turismo, eventos o ambiente'),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const EditarContenidoScreen())),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Cargar contenido inicial'),
            subtitle: const Text('Solo si la base de datos está vacía'),
            enabled: !_cargando,
            onTap: () => _seed(false),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restaurar contenido inicial'),
            subtitle: const Text('Sobrescribe los registros de ejemplo con su versión original'),
            enabled: !_cargando,
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('¿Restaurar?'),
                  content: const Text(
                      'Los registros iniciales que hayan sido editados volverán a su texto original. Las publicaciones nuevas no se tocan.'),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Restaurar')),
                  ],
                ),
              );
              if (ok == true) await _seed(true);
            },
          ),
        ),
        if (_cargando) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
      ],
    );
  }
}
