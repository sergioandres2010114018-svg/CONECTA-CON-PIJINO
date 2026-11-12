import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import 'explorar_screen.dart';
import 'galeria_screen.dart';
import 'home_screen.dart';
import 'mapa_screen.dart';
import 'perfil_screen.dart';

/// ¿El usuario actual es administrador?
bool esAdmin(BuildContext context) {
  final u = context.watch<Usuario?>();
  return (u?.esAdmin ?? false) || AuthService.esCorreoAdmin(AuthService.usuarioActual?.email);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  void irA(int i) => setState(() => _indice = i);

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      HomeScreen(onIrA: irA),
      const ExplorarScreen(),
      const GaleriaScreen(),
      const MapaScreen(),
      const PerfilScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: irA,
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explorar'),
          NavigationDestination(
              icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Galería'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
