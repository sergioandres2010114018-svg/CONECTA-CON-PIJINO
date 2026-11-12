import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../services/seed_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/contenido_card.dart';
import 'acerca_screen.dart';
import 'categoria_screen.dart';
import 'contacto_screen.dart';
import 'detalle_screen.dart';
import 'directorio_screen.dart';
import 'home_shell.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int) onIrA;
  const HomeScreen({super.key, required this.onIrA});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<Usuario?>();
    final nombre = (usuario?.nombre ?? '').split(' ').first;
    final admin = esAdmin(context);

    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: 210,
          pinned: true,
          backgroundColor: AppColors.cafe,
          foregroundColor: Colors.white,
          title: const Text(AppConfig.appName, style: TextStyle(color: Colors.white)),
          actions: <Widget>[
            IconButton(
              tooltip: 'Acerca de',
              icon: const Icon(Icons.info_outline),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AcercaScreen())),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[AppColors.naranja, AppColors.cafe],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(nombre.isEmpty ? '¡Bienvenido(a)!' : '¡Hola, $nombre!',
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 6),
                            const Text('“${AppConfig.slogan}”',
                                style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: ClipOval(
                            child: Image.asset('assets/images/logo.png', width: 84, height: 84, fit: BoxFit.cover)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Accesos a las categorías
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Text('Conoce Pijiño', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.92,
            children: <Widget>[
              for (final c in Categoria.todas)
                _Acceso(
                  icono: c.icono,
                  texto: c.nombre,
                  color: c.color,
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute<void>(builder: (_) => CategoriaScreen(categoria: c))),
                ),
              _Acceso(icono: Icons.photo_library, texto: 'Galería', color: const Color(0xFF8E44AD), onTap: () => onIrA(2)),
              _Acceso(icono: Icons.map, texto: 'Mapa', color: const Color(0xFF2B7A9B), onTap: () => onIrA(3)),
              _Acceso(
                icono: Icons.storefront,
                texto: 'Directorio',
                color: const Color(0xFF1F6F8B),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const DirectorioScreen())),
              ),
              _Acceso(
                icono: Icons.forum,
                texto: 'Contacto',
                color: const Color(0xFF34495E),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ContactoScreen())),
              ),
              _Acceso(
                icono: Icons.info,
                texto: 'Acerca de',
                color: AppColors.cafe,
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AcercaScreen())),
              ),
            ],
          ),
        ),

        // Destacados
        SliverToBoxAdapter(
          child: StreamBuilder<List<Contenido>>(
            stream: DbService.contenidosPorCategoria('turismo'),
            builder: (context, snap) {
              final lista = snap.data ?? <Contenido>[];
              if (snap.connectionState == ConnectionState.waiting && lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (lista.isEmpty) return _BaseVacia(admin: admin);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _Titulo('Lugares para visitar'),
                  SizedBox(
                    height: 190,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: lista.map((c) => ContenidoCardGrande(c)).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Próximos eventos
        SliverToBoxAdapter(
          child: StreamBuilder<List<Contenido>>(
            stream: DbService.proximosEventos(),
            builder: (context, snap) {
              final hoy = DateTime.now().subtract(const Duration(days: 1));
              final lista = (snap.data ?? <Contenido>[])
                  .where((e) => e.fecha == null || e.fecha!.isAfter(hoy))
                  .take(3)
                  .toList();
              if (lista.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _Titulo('Próximos eventos'),
                  for (final e in lista) _EventoTile(e),
                ],
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        const SliverToBoxAdapter(child: CreditosFooter()),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  final String texto;
  const _Titulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Text(texto,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      );
}

class _Acceso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback onTap;
  const _Acceso({required this.icono, required this.texto, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(radius: 24, backgroundColor: color, child: Icon(icono, color: Colors.white)),
              const SizedBox(height: 8),
              Text(texto,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  final Contenido e;
  const _EventoTile(this.e);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: ListTile(
        onTap: () =>
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DetalleScreen(contenido: e))),
        leading: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: AppColors.naranja, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(e.fecha == null ? '--' : '${e.fecha!.day}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              Text(e.fecha == null ? '' : mesCorto(e.fecha!),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        title: Text(e.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(e.lugar.isEmpty ? e.resumen : e.lugar, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _BaseVacia extends StatefulWidget {
  final bool admin;
  const _BaseVacia({required this.admin});

  @override
  State<_BaseVacia> createState() => _BaseVaciaState();
}

class _BaseVaciaState extends State<_BaseVacia> {
  bool _cargando = false;

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final n = await SeedData.cargar();
      if (mounted) mostrarMensaje(context, 'Se cargaron $n registros en la base de datos.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo cargar: $e', error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            const Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.naranja),
            const SizedBox(height: 10),
            const Text('La base de datos aún no tiene contenido.',
                textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              widget.admin
                  ? 'Como administrador puede cargar el contenido inicial de Pijiño del Carmen.'
                  : 'Pronto el equipo publicará la información del municipio.',
              textAlign: TextAlign.center,
            ),
            if (widget.admin) ...<Widget>[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _cargando ? null : _cargar,
                icon: const Icon(Icons.download),
                label: Text(_cargando ? 'Cargando…' : 'Cargar contenido inicial'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
