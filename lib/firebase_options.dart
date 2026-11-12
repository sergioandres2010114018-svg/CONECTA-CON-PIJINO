// Configuración de Firebase para APP-Conecta con Pijiño.

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
    apiKey: 'AIzaSyBdY8ke9QXDfQsPsrFPjCH16vqDqn_nXA4',
    appId: '1:650666958466:android:11cd887f4b494336e09e9b',
    messagingSenderId: '650666958466',
    projectId: 'conecta-con-pijino',
    storageBucket: 'conecta-con-pijino.firebasestorage.app',
  );
}
