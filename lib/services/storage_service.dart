import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Subida de fotos y videos a Firebase Storage.
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube un archivo y devuelve (urlDescarga, rutaEnStorage).
  static Future<(String, String)> subirArchivo({
    required File archivo,
    required bool esVideo,
    void Function(double progreso)? onProgreso,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ext = archivo.path.contains('.') ? archivo.path.split('.').last.toLowerCase() : (esVideo ? 'mp4' : 'jpg');
    final nombre = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ruta = 'galeria/$uid/$nombre';
    final ref = _storage.ref(ruta);

    final contentType = esVideo
        ? (ext == 'mov' ? 'video/quicktime' : 'video/mp4')
        : (ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg'));

    final tarea = ref.putFile(archivo, SettableMetadata(contentType: contentType));
    tarea.snapshotEvents.listen((s) {
      if (s.totalBytes > 0 && onProgreso != null) {
        onProgreso(s.bytesTransferred / s.totalBytes);
      }
    });
    await tarea;
    final url = await ref.getDownloadURL();
    return (url, ruta);
  }

  static Future<void> eliminar(String ruta) async {
    if (ruta.isEmpty) return;
    try {
      await _storage.ref(ruta).delete();
    } catch (_) {
      // El archivo pudo haber sido borrado previamente.
    }
  }
}
