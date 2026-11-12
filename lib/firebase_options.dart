// ARCHIVO DE CONFIGURACIÓN DE FIREBASE
//
// Opción A (recomendada): ejecute en la carpeta del proyecto
//     dart pub global activate flutterfire_cli
//     flutterfire configure
// y este archivo se reemplazará automáticamente con los datos de su proyecto.
//
// Opción B: copie manualmente los valores desde
//     Consola de Firebase > Configuración del proyecto > Tus apps > App Android
// y reemplace los textos que empiezan por "TU_".

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Esta app está configurada solo para Android.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Esta app está configurada solo para Android.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY',
    appId: 'TU_APP_ID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.firebasestorage.app',
  );
}
