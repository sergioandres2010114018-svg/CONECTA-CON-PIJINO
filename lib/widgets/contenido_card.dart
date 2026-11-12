import 'package:flutter/material.dart';

import '../config.dart';
import '../models/models.dart';
import '../screens/detalle_screen.dart';
import 'common.dart';

/// Tarjeta horizontal de contenido (lista).
class ContenidoTile extends StatelessWidget {
  final Contenido contenido;
  const ContenidoTile(this.contenido, {super.key});

  @override
  Widget build(BuildContext context) {
    final cat = Categoria.porId(contenido.categoria);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute<void>(builder: (_) => DetalleScreen(contenido: contenido))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 104,
              height: 104,
              child: Hero(
                tag: 'img-${contenido.id}',
                child: NetImage(contenido.imagenUrl, iconoVacio: cat.icono, colorVacio: cat.color),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(contenido.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(contenido.resumen,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        EtiquetaValidacion(contenido.validado),
                        if (contenido.fecha != null) ...<Widget>[
                          const SizedBox(width: 8),
                          Icon(Icons.event, size: 14, color: scheme.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(formatoFecha(contenido.fecha!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: scheme.primary)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta grande para carruseles.
class ContenidoCardGrande extends StatelessWidget {
  final Contenido contenido;
  const ContenidoCardGrande(this.contenido, {super.key});

  @override
  Widget build(BuildContext context) {
    final cat = Categoria.porId(contenido.categoria);
    return SizedBox(
      width: 240,
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        child: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute<void>(builder: (_) => DetalleScreen(contenido: contenido))),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              NetImage(contenido.imagenUrl, iconoVacio: cat.icono, colorVacio: cat.color),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0xCC000000)],
                    stops: <double>[0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(cat.nombre.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(contenido.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.15)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
