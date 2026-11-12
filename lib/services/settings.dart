import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de accesibilidad: tamaño de texto y tema claro/oscuro.
class AppSettings extends ChangeNotifier {
  double _textScale = 1.0;
  ThemeMode _themeMode = ThemeMode.light;

  double get textScale => _textScale;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _textScale = p.getDouble('textScale') ?? 1.0;
      final t = p.getString('themeMode') ?? 'light';
      _themeMode = t == 'dark'
          ? ThemeMode.dark
          : (t == 'system' ? ThemeMode.system : ThemeMode.light);
    } catch (_) {
      // Si falla, se usan los valores por defecto.
    }
  }

  Future<void> setTextScale(double v) async {
    _textScale = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble('textScale', v);
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'themeMode', m == ThemeMode.dark ? 'dark' : (m == ThemeMode.system ? 'system' : 'light'));
  }
}
