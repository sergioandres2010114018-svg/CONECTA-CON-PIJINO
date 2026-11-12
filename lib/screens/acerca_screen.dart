import 'package:flutter/material.dart';

import '../config.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Identidad corporativa y créditos del proyecto.
class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  static const List<(String, String)> _valores = <(String, String)>[
    ('Responsabilidad', 'Publicamos información verificada y respetamos a quienes aportan sus historias, fotografías y saberes.'),
    ('Sostenibilidad', 'Promovemos el cuidado del río, las ciénagas, la fauna y la flora del municipio.'),
    ('Compromiso social', 'Trabajamos para el beneficio de la comunidad y de sus emprendedores.'),
    ('Identidad cultural', 'Valoramos y difundimos las raíces, costumbres y tradiciones de Pijiño del Carmen.'),
    ('Trabajo en equipo', 'Sumamos los aportes de aprendices, instructor, institución y comunidad.'),
    ('Creatividad', 'Buscamos formas atractivas y modernas de contar nuestra historia.'),
    ('Respeto', 'Reconocemos la diversidad de personas, creencias y expresiones culturales.'),
  ];

  static const List<String> _aprendices = <String>[
    'Valentina López Guzmán',
    'María Ángel Machado López',
    'Lorena Patricia Lope López',
    'Luis Fernando Julio Palmera',
    'Carlos Yair Oliveros Palomino',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(
            child: ClipOval(child: Image.asset('assets/images/logo.png', width: 150, height: 150, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 12),
          Text('APP-${AppConfig.appName}',
              textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('“${AppConfig.slogan}”',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.naranja, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Versión 1.0.0', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const _Bloque(
            titulo: 'Misión',
            texto:
                'Dar a conocer de forma cercana y sencilla la historia, la cultura, la gastronomía y los sitios turísticos '
                'de Pijiño del Carmen, promoviendo el orgullo por sus raíces y el interés por valorar y cuidar nuestro municipio.',
          ),
          const _Bloque(
            titulo: 'Visión',
            texto:
                'Para el año 2030, lograr que Pijiño del Carmen sea reconocido como un destino cultural y turístico destacado, '
                'donde su historia, sus tradiciones y su gastronomía sean valoradas y contribuyan al desarrollo y bienestar de su comunidad.',
          ),
          const SizedBox(height: 8),
          Text('Valores', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final v in _valores)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: AppColors.naranja),
              title: Text(v.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(v.$2),
            ),
          const SizedBox(height: 12),
          Text('Equipo del proyecto', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.school),
            title: Text('Sergio Andrés Caro Arrieta'),
            subtitle: Text('Instructor responsable – SENA, Centro Acuícola y Agroindustrial de Gaira'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.account_balance),
            title: Text('Prisciliano Lara Mendoza'),
            subtitle: Text('Rector – IEDT Pijiño del Carmen'),
          ),
          for (final a in _aprendices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code),
              title: Text(a),
              subtitle: const Text('Aprendiz – Programación de Aplicaciones para Dispositivos Móviles'),
            ),
          const SizedBox(height: 8),
          const Text('Grupo de caracterización 3321831', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/images/organigrama.jpg'),
          ),
          const SizedBox(height: 8),
          const CreditosFooter(),
        ],
      ),
    );
  }
}

class _Bloque extends StatelessWidget {
  final String titulo;
  final String texto;
  const _Bloque({required this.titulo, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(texto, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }
}
