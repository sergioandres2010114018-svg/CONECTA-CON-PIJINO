import 'package:flutter/material.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import '../widgets/contenido_card.dart';

/// Búsqueda y filtro por categoría en todo el contenido.
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final _busqueda = TextEditingController();
  String _texto = '';
  String? _categoria;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  String _normalizar(String s) {
    const de = 'áéíóúüÁÉÍÓÚÜ';
    const a = 'aeiouuAEIOUU';
    var r = s;
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], a[i]);
    }
    return r.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _busqueda,
              onChanged: (v) => setState(() => _texto = v),
              decoration: InputDecoration(
                hintText: 'Buscar: ciénaga, bocachico, fiestas…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _texto.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busqueda.clear();
                          setState(() => _texto = '');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('Todo'),
                    selected: _categoria == null,
                    onSelected: (_) => setState(() => _categoria = null),
                  ),
                ),
                for (final c in Categoria.todas)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      avatar: Icon(c.icono, size: 16),
                      label: Text(c.nombre),
                      selected: _categoria == c.id,
                      onSelected: (_) => setState(() => _categoria = c.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: StreamBuilder<List<Contenido>>(
              stream: DbService.todosLosContenidos(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final q = _normalizar(_texto.trim());
                final lista = snap.data!.where((c) {
                  if (_categoria != null && c.categoria != _categoria) return false;
                  if (q.isEmpty) return true;
                  return _normalizar('${c.titulo} ${c.resumen} ${c.cuerpo} ${c.lugar}').contains(q);
                }).toList()
                  ..sort((a, b) => a.titulo.compareTo(b.titulo));
                if (lista.isEmpty) {
                  return const Vacio(icono: Icons.search_off, texto: 'No encontramos resultados.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: lista.length,
                  itemBuilder: (_, i) => ContenidoTile(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
