import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import '../widgets/common.dart';
import 'detalle_screen.dart';

/// Mapa interactivo (OpenStreetMap) con los lugares que tienen coordenadas.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final _mapa = MapController();
  Contenido? _seleccionado;

  @override
  Widget build(BuildContext context) {
    const centro = LatLng(AppConfig.latCentro, AppConfig.lngCentro);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Pijiño'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Centrar',
            icon: const Icon(Icons.my_location),
            onPressed: () => _mapa.move(centro, 13),
          ),
        ],
      ),
      body: StreamBuilder<List<Contenido>>(
        stream: DbService.todosLosContenidos(),
        builder: (context, snap) {
          final lugares = (snap.data ?? <Contenido>[]).where((c) => c.tieneUbicacion).toList();
          return Stack(
            children: <Widget>[
              FlutterMap(
                mapController: _mapa,
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: 13,
                  onTap: (_, __) => setState(() => _seleccionado = null),
                ),
                children: <Widget>[
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'co.edu.iedtpijino.conecta_pijino',
                  ),
                  MarkerLayer(
                    markers: <Marker>[
                      for (final c in lugares)
                        Marker(
                          point: LatLng(c.lat!, c.lng!),
                          width: 46,
                          height: 46,
                          child: GestureDetector(
                            onTap: () => setState(() => _seleccionado = c),
                            child: Icon(
                              Icons.location_on,
                              size: 46,
                              color: Categoria.porId(c.categoria).color,
                              shadows: const <Shadow>[Shadow(blurRadius: 6, color: Colors.black38)],
                            ),
                          ),
                        ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: <SourceAttribution>[
                      TextSourceAttribution('© colaboradores de OpenStreetMap'),
                    ],
                  ),
                ],
              ),
              if (_seleccionado != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: NetImage(_seleccionado!.imagenUrl,
                              iconoVacio: Categoria.porId(_seleccionado!.categoria).icono),
                        ),
                      ),
                      title: Text(_seleccionado!.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_seleccionado!.resumen, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => DetalleScreen(contenido: _seleccionado!)),
                      ),
                    ),
                  ),
                )
              else if (snap.hasData && lugares.isEmpty)
                const Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                          'Aún no hay lugares con coordenadas. Un administrador puede agregarlas al editar cada sitio.'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
