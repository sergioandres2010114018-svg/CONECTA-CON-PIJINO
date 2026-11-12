#!/usr/bin/env bash
# Ajusta la carpeta android/ generada por `flutter create` para esta app:
#  - permiso de INTERNET (necesario en la versión release)
#  - nombre visible "Conecta con Pijiño"
#  - consultas para abrir enlaces, llamadas, correo y WhatsApp
#  - minSdk 24 (requerido por Firebase)
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
GRADLE_KTS="android/app/build.gradle.kts"
GRADLE_GROOVY="android/app/build.gradle"

if [ ! -f "$MANIFEST" ]; then
  echo "No existe $MANIFEST. Ejecute primero: flutter create --platforms=android --org co.edu.iedtpijino ."
  exit 1
fi

# 1) Permiso de internet
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET"/>\n    <application|' "$MANIFEST"
fi

# 2) Nombre de la app
sed -i 's|android:label="[^"]*"|android:label="Conecta con Pijiño"|' "$MANIFEST"

# 3) Consultas de intents (url_launcher en Android 11+)
if ! grep -q "android.intent.action.DIAL" "$MANIFEST"; then
  sed -i 's|</manifest>|    <queries>\n        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>\n        <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>\n        <intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent>\n    </queries>\n</manifest>|' "$MANIFEST"
fi

# 4) minSdk 24
if [ -f "$GRADLE_KTS" ]; then
  sed -i -E 's|minSdk = .*|minSdk = 24|' "$GRADLE_KTS"
elif [ -f "$GRADLE_GROOVY" ]; then
  sed -i -E 's|minSdkVersion .*|minSdkVersion 24|' "$GRADLE_GROOVY"
fi

echo "Carpeta android/ configurada para Conecta con Pijiño."
grep -n "INTERNET\|android:label" "$MANIFEST" || true
grep -n "minSdk" "$GRADLE_KTS" "$GRADLE_GROOVY" 2>/dev/null || true
