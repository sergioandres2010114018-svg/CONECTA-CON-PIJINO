import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

/// Acceso a la base de datos Cloud Firestore.
///
/// Colecciones:
///  - usuarios   : perfiles de los usuarios registrados
///  - contenidos : historia, cultura, gastronomía, turismo, eventos, ambiente
///  - galeria    : fotos y videos (aportes de la comunidad, con aprobación)
///  - negocios   : directorio de comercios y entidades
///  - mensajes   : contacto y participación
class DbService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get usuarios => db.collection('usuarios');
  static CollectionReference<Map<String, dynamic>> get contenidos => db.collection('contenidos');
  static CollectionReference<Map<String, dynamic>> get galeria => db.collection('galeria');
  static CollectionReference<Map<String, dynamic>> get negocios => db.collection('negocios');
  static CollectionReference<Map<String, dynamic>> get mensajes => db.collection('mensajes');

  // ---------------- Usuarios ----------------
  static Stream<Usuario?> perfil(String uid) => usuarios
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? Usuario.fromDoc(d) : null);

  static Stream<List<Usuario>> todosLosUsuarios() => usuarios
      .orderBy('creadoEn', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Usuario.fromDoc).toList());

  static Future<void> actualizarPerfil(String uid, Map<String, dynamic> datos) =>
      usuarios.doc(uid).update(datos);

  static Future<void> cambiarRol(String uid, String rol) =>
      usuarios.doc(uid).update(<String, dynamic>{'rol': rol});

  static Future<void> alternarFavorito(String uid, String contenidoId, bool agregar) =>
      usuarios.doc(uid).update(<String, dynamic>{
        'favoritos': agregar
            ? FieldValue.arrayUnion(<String>[contenidoId])
            : FieldValue.arrayRemove(<String>[contenidoId]),
      });

  // ---------------- Contenidos ----------------
  static Stream<List<Contenido>> contenidosPorCategoria(String categoria) => contenidos
      .where('categoria', isEqualTo: categoria)
      .snapshots()
      .map((s) {
        final lista = s.docs.map(Contenido.fromDoc).toList();
        lista.sort((a, b) => a.orden.compareTo(b.orden));
        return lista;
      });

  static Stream<List<Contenido>> todosLosContenidos() =>
      contenidos.snapshots().map((s) => s.docs.map(Contenido.fromDoc).toList());

  static Stream<List<Contenido>> proximosEventos() => contenidos
      .where('categoria', isEqualTo: 'eventos')
      .snapshots()
      .map((s) {
        final lista = s.docs.map(Contenido.fromDoc).toList();
        lista.sort((a, b) {
          final fa = a.fecha ?? DateTime(2100);
          final fb = b.fecha ?? DateTime(2100);
          return fa.compareTo(fb);
        });
        return lista;
      });

  static Future<void> guardarContenido(Contenido c) {
    final data = c.toMap()..['actualizadoEn'] = FieldValue.serverTimestamp();
    if (c.id.isEmpty) {
      data['creadoEn'] = FieldValue.serverTimestamp();
      return contenidos.add(data);
    }
    return contenidos.doc(c.id).set(data, SetOptions(merge: true));
  }

  static Future<void> eliminarContenido(String id) => contenidos.doc(id).delete();

  // ---------------- Galería ----------------
  static Stream<List<MediaItem>> galeriaAprobada() => galeria
      .where('aprobado', isEqualTo: true)
      .snapshots()
      .map((s) => _ordenarMedia(s.docs.map(MediaItem.fromDoc).toList()));

  static Stream<List<MediaItem>> galeriaPendiente() => galeria
      .where('aprobado', isEqualTo: false)
      .snapshots()
      .map((s) => _ordenarMedia(s.docs.map(MediaItem.fromDoc).toList()));

  static Stream<List<MediaItem>> misAportes(String uid) => galeria
      .where('autorUid', isEqualTo: uid)
      .snapshots()
      .map((s) => _ordenarMedia(s.docs.map(MediaItem.fromDoc).toList()));

  static List<MediaItem> _ordenarMedia(List<MediaItem> l) {
    l.sort((a, b) => (b.creadoEn ?? DateTime(2000)).compareTo(a.creadoEn ?? DateTime(2000)));
    return l;
  }

  static Future<void> agregarMedia({
    required String tipo,
    required String url,
    required String titulo,
    required String descripcion,
    required bool aprobado,
    String rutaStorage = '',
  }) {
    final user = FirebaseAuth.instance.currentUser!;
    return galeria.add(<String, dynamic>{
      'tipo': tipo,
      'url': url,
      'titulo': titulo,
      'descripcion': descripcion,
      'autorUid': user.uid,
      'autorNombre': user.displayName ?? user.email ?? 'Usuario',
      'aprobado': aprobado,
      'rutaStorage': rutaStorage,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> aprobarMedia(String id) =>
      galeria.doc(id).update(<String, dynamic>{'aprobado': true});

  static Future<void> eliminarMedia(String id) => galeria.doc(id).delete();

  // ---------------- Directorio ----------------
  static Stream<List<Negocio>> directorio() => negocios.snapshots().map((s) {
        final l = s.docs.map(Negocio.fromDoc).toList();
        l.sort((a, b) => a.nombre.compareTo(b.nombre));
        return l;
      });

  static Future<void> guardarNegocio(Map<String, dynamic> data, {String? id}) =>
      id == null ? negocios.add(data) : negocios.doc(id).set(data, SetOptions(merge: true));

  static Future<void> eliminarNegocio(String id) => negocios.doc(id).delete();

  // ---------------- Mensajes ----------------
  static Future<void> enviarMensaje({required String tipo, required String mensaje}) {
    final user = FirebaseAuth.instance.currentUser!;
    return mensajes.add(<String, dynamic>{
      'uid': user.uid,
      'nombre': user.displayName ?? '',
      'email': user.email ?? '',
      'tipo': tipo,
      'mensaje': mensaje,
      'leido': false,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Mensaje>> todosLosMensajes() => mensajes
      .orderBy('creadoEn', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Mensaje.fromDoc).toList());

  static Future<void> marcarLeido(String id) =>
      mensajes.doc(id).update(<String, dynamic>{'leido': true});
}
