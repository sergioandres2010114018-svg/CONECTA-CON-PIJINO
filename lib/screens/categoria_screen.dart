import 'package:flutter/material.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import '../widgets/contenido_card.dart';
import 'editar_contenido_screen.dart';
import 'home_shell.dart';

class CategoriaScreen extends StatelessWidget {
  final Categoria categoria;
  const CategoriaScreen({super.key, required this.categoria});

  @override
  Widget build(BuildContext context) {
    final admin = esAdmin(context);
    final stream = categoria.id == 'eventos'
        ? DbService.proximosEventos()
        : DbService.contenidosPorCategoria(categoria.id);

    return Scaffold(
      appBar: AppBar(title: Text(categoria.nombre)),
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => EditarContenidoScreen(categoriaInicial: categoria.id),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            )
          : null,
      body: StreamBuilder<List<Contenido>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Vacio(icono: Icons.cloud_off, texto: 'No se pudo cargar el contenido.\n${snap.error}');
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snap.data!;
          return ListView(
            padding: const EdgeInsets.only(bottom: 90),
            children: <Widget>[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: categoria.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                        radius: 26,
                        backgroundColor: categoria.color,
                        child: Icon(categoria.icono, color: Colors.white)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(categoria.descripcion, style: const TextStyle(fontSize: 15))),
                  ],
                ),
              ),
              if (lista.isEmpty)
                const Vacio(icono: Icons.inbox_outlined, texto: 'Aún no hay publicaciones en esta sección.')
              else
                ...lista.map((c) => ContenidoTile(c)),
            ],
          );
        },
      ),
    );
  }
}
