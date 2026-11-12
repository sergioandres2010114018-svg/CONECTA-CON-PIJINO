import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../theme.dart';

/// Imagen que acepta URL de internet o `asset:ruta`.
class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final IconData iconoVacio;
  final Color? colorVacio;

  const NetImage(this.url,
      {super.key, this.fit = BoxFit.cover, this.iconoVacio = Icons.image_outlined, this.colorVacio});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _vacio(context);
    if (url.startsWith('asset:')) {
      return Image.asset(url.replaceFirst('asset:', ''), fit: fit,
          errorBuilder: (c, e, s) => _vacio(c));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (c, u) => Container(
        color: Theme.of(c).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (c, u, e) => _vacio(c),
    );
  }

  Widget _vacio(BuildContext context) {
    final base = colorVacio ?? AppColors.naranja;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[base.withValues(alpha: 0.85), AppColors.cafe],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(iconoVacio, color: Colors.white70, size: 40),
    );
  }
}

/// Pie con los créditos del proyecto.
class CreditosFooter extends StatelessWidget {
  final bool claro;
  const CreditosFooter({super.key, this.claro = false});

  @override
  Widget build(BuildContext context) {
    final color = claro ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: <Widget>[
          Icon(Icons.favorite, size: 16, color: claro ? Colors.white70 : AppColors.naranja),
          const SizedBox(height: 6),
          Text(
            AppConfig.creditos,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta "Por validar" para contenidos aún no confirmados con la comunidad.
class EtiquetaValidacion extends StatelessWidget {
  final bool validado;
  const EtiquetaValidacion(this.validado, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = validado ? const Color(0xFF2E7D32) : const Color(0xFFB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(validado ? Icons.verified : Icons.pending_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(validado ? 'Verificado' : 'Por validar',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class Vacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  const Vacio({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icono, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

Future<void> abrirEnlace(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  bool ok = false;
  if (uri != null) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
  }
}

void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texto),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    behavior: SnackBarBehavior.floating,
  ));
}

const List<String> _meses = <String>[
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
];

String formatoFecha(DateTime d, {bool hora = false}) {
  final base = '${d.day} ${_meses[d.month - 1]} ${d.year}';
  if (!hora) return base;
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$base · $h:$m';
}

String mesCorto(DateTime d) => _meses[d.month - 1].toUpperCase();
