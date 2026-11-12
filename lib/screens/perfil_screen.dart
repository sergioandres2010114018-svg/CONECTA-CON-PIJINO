import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/settings.dart';
import '../widgets/common.dart';
import 'acerca_screen.dart';
import 'admin_screen.dart';
import 'contacto_screen.dart';
import 'favoritos_screen.dart';
import 'home_shell.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = context.watch<Usuario?>();
    final settings = context.watch<AppSettings>();
    final admin = esAdmin(context);
    final scheme = Theme.of(context).colorScheme;
    final nombre = u?.nombre ?? AuthService.usuarioActual?.displayName ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        children: <Widget>[
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: scheme.primary,
              child: Text(nombre.isEmpty ? '?' : nombre[0].toUpperCase(),
                  style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 10),
          Text(nombre,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(u?.email ?? AuthService.usuarioActual?.email ?? '',
              textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Center(
            child: Wrap(
              spacing: 6,
              children: <Widget>[
                if ((u?.tipoUsuario ?? '').isNotEmpty) Chip(label: Text(u!.tipoUsuario)),
                if (admin)
                  Chip(
                    avatar: const Icon(Icons.admin_panel_settings, size: 18),
                    label: const Text('Administrador'),
                    backgroundColor: scheme.primaryContainer,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Seccion('Mi cuenta'),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar mis datos'),
            onTap: u == null ? null : () => _editarPerfil(context, u),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Mis favoritos'),
            trailing: Text('${u?.favoritos.length ?? 0}'),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FavoritosScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.forum_outlined),
            title: const Text('Contacto y participación'),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ContactoScreen())),
          ),
          if (admin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Panel de administración'),
              subtitle: const Text('Contenidos, aprobaciones, usuarios y mensajes'),
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AdminScreen())),
            ),
          _Seccion('Accesibilidad'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                const Icon(Icons.text_fields),
                const SizedBox(width: 16),
                const Text('Tamaño de texto'),
                Expanded(
                  child: Slider(
                    value: settings.textScale,
                    min: 0.9,
                    max: 1.5,
                    divisions: 6,
                    label: '${(settings.textScale * 100).round()} %',
                    onChanged: settings.setTextScale,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                ButtonSegment<ThemeMode>(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
                ButtonSegment<ThemeMode>(value: ThemeMode.system, label: Text('Sistema')),
              ],
              selected: <ThemeMode>{settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          _Seccion('Información'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de Conecta con Pijiño'),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AcercaScreen())),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: scheme.error),
            title: Text('Cerrar sesión', style: TextStyle(color: scheme.error)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('¿Cerrar sesión?'),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cerrar sesión')),
                  ],
                ),
              );
              if (ok == true) await AuthService.cerrarSesion();
            },
          ),
          const CreditosFooter(),
        ],
      ),
    );
  }

  Future<void> _editarPerfil(BuildContext context, Usuario u) async {
    final nombre = TextEditingController(text: u.nombre);
    final tel = TextEditingController(text: u.telefono);
    String tipo = AppConfig.tiposUsuario.contains(u.tipoUsuario) ? u.tipoUsuario : AppConfig.tiposUsuario.first;
    final guardar = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(c).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Editar mis datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre completo')),
              const SizedBox(height: 10),
              TextField(
                  controller: tel,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Celular')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: tipo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Yo soy…'),
                items: AppConfig.tiposUsuario
                    .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setS(() => tipo = v ?? tipo),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
            ],
          ),
        ),
      ),
    );
    if (guardar != true) return;
    try {
      await DbService.actualizarPerfil(u.uid, <String, dynamic>{
        'nombre': nombre.text.trim(),
        'telefono': tel.text.trim(),
        'tipoUsuario': tipo,
      });
      await AuthService.usuarioActual?.updateDisplayName(nombre.text.trim());
      if (context.mounted) mostrarMensaje(context, 'Datos actualizados.');
    } catch (e) {
      if (context.mounted) mostrarMensaje(context, AuthService.mensajeError(e), error: true);
    }
  }
}

class _Seccion extends StatelessWidget {
  final String texto;
  const _Seccion(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Text(texto.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary)),
      );
}
