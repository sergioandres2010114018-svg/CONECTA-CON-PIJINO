import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import '../widgets/contenido_card.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<Usuario?>()?.favoritos ?? <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Mis favoritos')),
      body: StreamBuilder<List<Contenido>>(
        stream: DbService.todosLosContenidos(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snap.data!.where((c) => favs.contains(c.id)).toList();
          if (lista.isEmpty) {
            return const Vacio(
              icono: Icons.favorite_border,
              texto: 'Toque el corazón en cualquier publicación para guardarla aquí.',
            );
          }
          return ListView(children: lista.map((c) => ContenidoTile(c)).toList());
        },
      ),
    );
  }
}
