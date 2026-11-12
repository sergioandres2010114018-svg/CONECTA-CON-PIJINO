import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import 'contacto_screen.dart';
import 'home_shell.dart';

/// Directorio de comercios, emprendimientos y entidades.
class DirectorioScreen extends StatelessWidget {
  const DirectorioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = esAdmin(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Directorio local')),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(admin ? Icons.add_business : Icons.storefront),
        label: Text(admin ? 'Agregar' : 'Registrar mi negocio'),
        onPressed: () {
          if (admin) {
            _editar(context, null);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ContactoScreen(
                  tipoInicial: 'Registrar mi negocio',
                  textoInicial: 'Nombre del negocio:\nTipo:\nTeléfono:\nDirección:\nDescripción:',
                ),
              ),
            );
          }
        },
      ),
      body: StreamBuilder<List<Negocio>>(
        stream: DbService.directorio(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final lista = snap.data!;
          if (lista.isEmpty) {
            return const Vacio(icono: Icons.storefront_outlined, texto: 'Aún no hay negocios registrados.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
            itemCount: lista.length,
            itemBuilder: (_, i) {
              final n = lista[i];
              return Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(n.nombre.isEmpty ? '?' : n.nombre[0].toUpperCase()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(n.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text(n.tipo, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                              ],
                            ),
                          ),
                          if (admin)
                            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editar(context, n)),
                        ],
                      ),
                      if (n.descripcion.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(n.descripcion),
                      ],
                      if (n.direccion.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6),
                        Row(children: <Widget>[
                          const Icon(Icons.place_outlined, size: 16),
                          const SizedBox(width: 4),
                          Expanded(child: Text(n.direccion, style: const TextStyle(fontSize: 13))),
                        ]),
                      ],
                      if (n.enlace.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => abrirEnlace(context, n.enlace),
                          icon: Icon(
                              n.enlace.contains('facebook.com') || n.enlace.contains('instagram.com')
                                  ? Icons.groups
                                  : Icons.language,
                              size: 18),
                          label: Text(n.enlace.contains('facebook.com')
                              ? 'Ver en Facebook'
                              : n.enlace.contains('instagram.com')
                                  ? 'Ver en Instagram'
                                  : 'Abrir sitio web'),
                        ),
                      ],
                      if (n.telefono.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, children: <Widget>[
                          FilledButton.tonalIcon(
                            onPressed: () => abrirEnlace(context, 'tel:${n.telefono}'),
                            icon: const Icon(Icons.call, size: 18),
                            label: Text(n.telefono),
                          ),
                          if (n.telefono.length >= 10)
                            OutlinedButton.icon(
                              onPressed: () => abrirEnlace(
                                  context, 'https://wa.me/57${n.telefono.replaceAll(RegExp(r'[^0-9]'), '')}'),
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('WhatsApp'),
                            ),
                        ]),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editar(BuildContext context, Negocio? n) async {
    final nombre = TextEditingController(text: n?.nombre ?? '');
    final tipo = TextEditingController(text: n?.tipo ?? '');
    final desc = TextEditingController(text: n?.descripcion ?? '');
    final tel = TextEditingController(text: n?.telefono ?? '');
    final dir = TextEditingController(text: n?.direccion ?? '');
    final enlace = TextEditingController(text: n?.enlace ?? '');
    final accion = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(c).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(n == null ? 'Nuevo registro' : 'Editar registro',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              TextField(controller: tipo, decoration: const InputDecoration(labelText: 'Tipo (Restaurante, Tienda…)')),
              const SizedBox(height: 8),
              TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 8),
              TextField(
                  controller: tel,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 8),
              TextField(controller: dir, decoration: const InputDecoration(labelText: 'Dirección')),
              const SizedBox(height: 8),
              TextField(
                  controller: enlace,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Sitio web o red social (opcional)')),
              const SizedBox(height: 14),
              Row(children: <Widget>[
                if (n != null)
                  TextButton(onPressed: () => Navigator.pop(c, 'eliminar'), child: const Text('Eliminar')),
                const Spacer(),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(120, 48)),
                  onPressed: () => Navigator.pop(c, 'guardar'),
                  child: const Text('Guardar'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    try {
      if (accion == 'guardar' && nombre.text.trim().isNotEmpty) {
        await DbService.guardarNegocio(<String, dynamic>{
          'nombre': nombre.text.trim(),
          'tipo': tipo.text.trim(),
          'descripcion': desc.text.trim(),
          'telefono': tel.text.trim(),
          'direccion': dir.text.trim(),
          'enlace': enlace.text.trim(),
        }, id: n?.id);
      } else if (accion == 'eliminar' && n != null) {
        await DbService.eliminarNegocio(n.id);
      }
    } catch (e) {
      if (context.mounted) mostrarMensaje(context, 'Error: $e', error: true);
    }
  }
}
