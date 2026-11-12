import 'package:cloud_firestore/cloud_firestore.dart';

double? _toDouble(dynamic v) => v is num ? v.toDouble() : null;
DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;
String _str(dynamic v) => v is String ? v : '';

/// Perfil de usuario guardado en la colección `usuarios`.
class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String telefono;
  final String tipoUsuario;
  final String rol; // 'usuario' | 'admin'
  final List<String> favoritos;
  final DateTime? creadoEn;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.tipoUsuario,
    required this.rol,
    required this.favoritos,
    this.creadoEn,
  });

  bool get esAdmin => rol == 'admin';

  factory Usuario.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return Usuario(
      uid: d.id,
      nombre: _str(m['nombre']),
      email: _str(m['email']),
      telefono: _str(m['telefono']),
      tipoUsuario: _str(m['tipoUsuario']),
      rol: m['rol'] == 'admin' ? 'admin' : 'usuario',
      favoritos: (m['favoritos'] is List)
          ? List<String>.from((m['favoritos'] as List).whereType<String>())
          : <String>[],
      creadoEn: _toDate(m['creadoEn']),
    );
  }
}

/// Contenido informativo (historia, cultura, gastronomía, turismo, eventos, ambiente).
class Contenido {
  final String id;
  final String categoria;
  final String titulo;
  final String resumen;
  final String cuerpo;
  final String imagenUrl;
  final String videoUrl;
  final String lugar;
  final DateTime? fecha;
  final double? lat;
  final double? lng;
  final int orden;
  final bool validado;
  final String fuente;
  final String fuenteUrl;
  final List<String> imagenes;

  Contenido({
    this.fuenteUrl = '',
    this.imagenes = const <String>[],
    required this.id,
    required this.categoria,
    required this.titulo,
    required this.resumen,
    required this.cuerpo,
    this.imagenUrl = '',
    this.videoUrl = '',
    this.lugar = '',
    this.fecha,
    this.lat,
    this.lng,
    this.orden = 0,
    this.validado = false,
    this.fuente = '',
  });

  bool get tieneUbicacion => lat != null && lng != null;

  factory Contenido.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return Contenido(
      id: d.id,
      categoria: _str(m['categoria']),
      titulo: _str(m['titulo']),
      resumen: _str(m['resumen']),
      cuerpo: _str(m['cuerpo']),
      imagenUrl: _str(m['imagenUrl']),
      videoUrl: _str(m['videoUrl']),
      lugar: _str(m['lugar']),
      fecha: _toDate(m['fecha']),
      lat: _toDouble(m['lat']),
      lng: _toDouble(m['lng']),
      orden: (m['orden'] is num) ? (m['orden'] as num).toInt() : 0,
      validado: m['validado'] == true,
      fuente: _str(m['fuente']),
      fuenteUrl: _str(m['fuenteUrl']),
      imagenes: (m['imagenes'] is List)
          ? List<String>.from((m['imagenes'] as List).whereType<String>())
          : const <String>[],
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'categoria': categoria,
        'titulo': titulo,
        'resumen': resumen,
        'cuerpo': cuerpo,
        'imagenUrl': imagenUrl,
        'videoUrl': videoUrl,
        'lugar': lugar,
        'fecha': fecha == null ? null : Timestamp.fromDate(fecha!),
        'lat': lat,
        'lng': lng,
        'orden': orden,
        'validado': validado,
        'fuente': fuente,
        'fuenteUrl': fuenteUrl,
        'imagenes': imagenes,
      };
}

/// Elemento de la galería multimedia (foto o video).
class MediaItem {
  final String id;
  final String tipo; // 'foto' | 'video'
  final String url; // https://..., o asset:assets/images/...
  final String titulo;
  final String descripcion;
  final String autorUid;
  final String autorNombre;
  final bool aprobado;
  final String rutaStorage;
  final DateTime? creadoEn;

  MediaItem({
    this.rutaStorage = '',
    required this.id,
    required this.tipo,
    required this.url,
    required this.titulo,
    required this.descripcion,
    required this.autorUid,
    required this.autorNombre,
    required this.aprobado,
    this.creadoEn,
  });

  bool get esVideo => tipo == 'video';
  bool get esAsset => url.startsWith('asset:');
  String get assetPath => url.replaceFirst('asset:', '');
  bool get esYoutube => url.contains('youtube.com') || url.contains('youtu.be');

  /// Miniatura de YouTube si aplica.
  String? get miniaturaYoutube {
    if (!esYoutube) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    String? id;
    if (uri.host.contains('youtu.be')) {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.pathSegments.contains('shorts')) {
      final i = uri.pathSegments.indexOf('shorts');
      id = i + 1 < uri.pathSegments.length ? uri.pathSegments[i + 1] : null;
    } else {
      id = uri.queryParameters['v'];
    }
    return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  factory MediaItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return MediaItem(
      id: d.id,
      tipo: m['tipo'] == 'video' ? 'video' : 'foto',
      url: _str(m['url']),
      titulo: _str(m['titulo']),
      descripcion: _str(m['descripcion']),
      autorUid: _str(m['autorUid']),
      autorNombre: _str(m['autorNombre']),
      aprobado: m['aprobado'] == true,
      rutaStorage: _str(m['rutaStorage']),
      creadoEn: _toDate(m['creadoEn']),
    );
  }
}

/// Negocio o entidad del directorio local.
class Negocio {
  final String id;
  final String nombre;
  final String tipo;
  final String descripcion;
  final String telefono;
  final String direccion;
  final String enlace;

  Negocio({
    this.enlace = '',
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.descripcion,
    required this.telefono,
    required this.direccion,
  });

  factory Negocio.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return Negocio(
      id: d.id,
      nombre: _str(m['nombre']),
      tipo: _str(m['tipo']),
      descripcion: _str(m['descripcion']),
      telefono: _str(m['telefono']),
      direccion: _str(m['direccion']),
      enlace: _str(m['enlace']),
    );
  }
}

/// Mensaje de participación (sugerencia, aporte, corrección, registro de negocio).
class Mensaje {
  final String id;
  final String nombre;
  final String email;
  final String tipo;
  final String mensaje;
  final bool leido;
  final DateTime? creadoEn;

  Mensaje({
    required this.id,
    required this.nombre,
    required this.email,
    required this.tipo,
    required this.mensaje,
    required this.leido,
    this.creadoEn,
  });

  factory Mensaje.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return Mensaje(
      id: d.id,
      nombre: _str(m['nombre']),
      email: _str(m['email']),
      tipo: _str(m['tipo']),
      mensaje: _str(m['mensaje']),
      leido: m['leido'] == true,
      creadoEn: _toDate(m['creadoEn']),
    );
  }
}
