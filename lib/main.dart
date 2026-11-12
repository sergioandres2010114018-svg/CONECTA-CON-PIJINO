import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/settings.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings();
  await settings.load();

  String? error;
  try {
    final opciones = DefaultFirebaseOptions.currentPlatform;
    if (opciones.apiKey.startsWith('TU_')) {
      error = 'Falta configurar Firebase en lib/firebase_options.dart.';
    } else {
      await Firebase.initializeApp(options: opciones);
    }
  } catch (e) {
    error = e.toString();
  }

  runApp(ChangeNotifierProvider<AppSettings>.value(
    value: settings,
    child: ConectaApp(errorFirebase: error),
  ));
}

class ConectaApp extends StatelessWidget {
  final String? errorFirebase;
  const ConectaApp({super.key, this.errorFirebase});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final app = MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro(),
      darkTheme: AppTheme.oscuro(),
      themeMode: settings.themeMode,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(settings.textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: errorFirebase == null ? const AuthGate() : ConfigFaltanteScreen(error: errorFirebase!),
    );

    if (errorFirebase != null) return app;

    // El perfil del usuario actual queda disponible en toda la app.
    return StreamProvider<Usuario?>.value(
      initialData: null,
      value: AuthService.cambios.asyncExpand(
        (u) => u == null ? Stream<Usuario?>.value(null) : DbService.perfil(u.uid),
      ),
      child: app,
    );
  }
}

/// Decide si mostrar el login o la app según la sesión.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.cambios,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snap.data == null) return const LoginScreen();
        return const HomeShell();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipOval(child: Image.asset('assets/images/logo.png', width: 160, height: 160, fit: BoxFit.cover)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Se muestra si Firebase aún no está configurado.
class ConfigFaltanteScreen extends StatelessWidget {
  final String error;
  const ConfigFaltanteScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const SizedBox(height: 24),
            Center(child: Image.asset('assets/images/logo.png', height: 140)),
            const SizedBox(height: 24),
            const Text('Configuración pendiente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'La app necesita conectarse a la base de datos de Firebase. '
              'Siga los pasos del archivo README.md (sección "Configurar Firebase") '
              'y vuelva a compilar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(error, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
            const CreditosFooter(),
          ],
        ),
      ),
    );
  }
}
