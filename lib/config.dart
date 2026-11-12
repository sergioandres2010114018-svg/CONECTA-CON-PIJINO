import 'package:flutter/material.dart';

/// Configuración general de la aplicación.
class AppConfig {
  static const String appName = 'Conecta con Pijiño';
  static const String slogan = 'El corazón de Pijiño en cada atarraya';
  static const String creditos =
      'Creado por Grupo de Estudiantes Conecta con Pijiño, '
      'del Proyecto Senatic e IEDT Pijiño del Carmen';

  /// Correos con permisos de administrador (pueden publicar contenido,
  /// aprobar fotos/videos y cargar el contenido inicial).
  /// IMPORTANTE: si cambia esta lista, actualice también firestore.rules
  /// y storage.rules.
  static const List<String> adminEmails = <String>[
    'sergioandres2010114018@gmail.com',
  ];

  /// Centro aproximado del casco urbano (9°20′N 74°27′O).
  static const double latCentro = 9.3333;
  static const double lngCentro = -74.4500;

  /// Tamaño máximo de archivos subidos (MB).
  static const int maxMbFoto = 10;
  static const int maxMbVideo = 50;

  static const List<String> tiposUsuario = <String>[
    'Habitante de Pijiño',
    'Visitante / turista',
    'Estudiante',
    'Docente / investigador',
    'Comerciante / emprendedor',
    'Gestor cultural',
    'Pijiñero que vive fuera',
  ];
}

/// Categorías de contenido definidas en el documento del proyecto.
class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final IconData icono;
  final Color color;

  const Categoria(this.id, this.nombre, this.descripcion, this.icono, this.color);

  static const List<Categoria> todas = <Categoria>[
    Categoria('historia', 'Historia', 'Orígenes y evolución del municipio',
        Icons.history_edu, Color(0xFF6B3E1F)),
    Categoria('cultura', 'Cultura y tradiciones', 'Bailes, música, oficios y tradición oral',
        Icons.music_note, Color(0xFFB4541A)),
    Categoria('personajes', 'Personajes', 'Escritores, músicos y artistas pijiñeros',
        Icons.groups, Color(0xFF7B4B94)),
    Categoria('gastronomia', 'Gastronomía', 'Sabores típicos de la ciénaga y el río',
        Icons.restaurant, Color(0xFFE07A1F)),
    Categoria('turismo', 'Sitios turísticos', 'Lugares para conocer y disfrutar',
        Icons.place, Color(0xFF2E7D6B)),
    Categoria('eventos', 'Fiestas y eventos', 'Celebraciones y agenda del pueblo',
        Icons.celebration, Color(0xFFC0392B)),
    Categoria('ambiente', 'Medio ambiente', 'Cuidado de la ciénaga, la fauna y la flora',
        Icons.eco, Color(0xFF4E7D2E)),
  ];

  static Categoria porId(String id) =>
      todas.firstWhere((c) => c.id == id, orElse: () => todas.first);
}
