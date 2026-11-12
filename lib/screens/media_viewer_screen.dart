import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/models.dart';
import '../widgets/common.dart';

/// Visor de foto (con zoom) o reproductor de video.
class MediaViewerScreen extends StatelessWidget {
  final MediaItem item;
  const MediaViewerScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.titulo, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: item.esVideo
                ? _Reproductor(url: item.url)
                : InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: Hero(
                        tag: 'media-${item.id}',
                        child: NetImage(item.url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
          ),
          if (item.descripcion.isNotEmpty || item.autorNombre.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFF111111),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (item.descripcion.isNotEmpty)
                      Text(item.descripcion, style: const TextStyle(color: Colors.white, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(
                      'Compartido por ${item.autorNombre}'
                      '${item.creadoEn != null ? ' · ${formatoFecha(item.creadoEn!)}' : ''}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Reproductor extends StatefulWidget {
  final String url;
  const _Reproductor({required this.url});

  @override
  State<_Reproductor> createState() => _ReproductorState();
}

class _ReproductorState extends State<_Reproductor> {
  late final VideoPlayerController _ctrl;
  bool _listo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _ctrl.initialize().then((_) {
      if (!mounted) return;
      setState(() => _listo = true);
      _ctrl.play();
    }).catchError((Object e) {
      if (mounted) setState(() => _error = 'No se pudo reproducir el video.');
    });
    _ctrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _tiempo(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white)));
    }
    if (!_listo) return const Center(child: CircularProgressIndicator());
    final v = _ctrl.value;
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () => v.isPlaying ? _ctrl.pause() : _ctrl.play(),
            child: Center(
              child: AspectRatio(
                aspectRatio: v.aspectRatio == 0 ? 16 / 9 : v.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    VideoPlayer(_ctrl),
                    if (!v.isPlaying)
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Color(0x88000000),
                        child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              IconButton(
                color: Colors.white,
                icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => v.isPlaying ? _ctrl.pause() : _ctrl.play(),
              ),
              Text(_tiempo(v.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: VideoProgressIndicator(
                  _ctrl,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(playedColor: Color(0xFFE07A1F)),
                ),
              ),
              const SizedBox(width: 8),
              Text(_tiempo(v.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
