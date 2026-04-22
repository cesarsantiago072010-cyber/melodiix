import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/providers/providers.dart';
import '../../models/track.dart';

Map<Duration, String> parseLrc(String lrc) {
  final map   = <Duration, String>{};
  final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
  for (final line in lrc.split('\n')) {
    final m = regex.firstMatch(line);
    if (m != null) {
      final d = Duration(
        minutes:      int.parse(m.group(1)!),
        seconds:      int.parse(m.group(2)!),
        milliseconds: int.parse(m.group(3)!.padRight(3, '0')),
      );
      map[d] = m.group(4)!.trim();
    }
  }
  return map;
}

class LyricsView extends ConsumerWidget {
  final Track       track;
  final AudioPlayer player;

  const LyricsView({super.key, required this.track, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dio = ref.read(dioProvider);
    return FutureBuilder(
      future: dio.get('/lyrics/',
          queryParameters: {'artist': track.artist, 'title': track.title}),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError || snap.data == null) {
          return const SizedBox(
              height: 200,
              child: Center(child: Text('No se encontraron letras.')));
        }
        final data   = snap.data!.data as Map<String, dynamic>;
        final synced = data['synced'] as String?;
        final plain  = data['plain']  as String?;

        if (synced != null) {
          final lrcMap = parseLrc(synced);
          final keys   = lrcMap.keys.toList()..sort();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            builder: (_, ctrl) => StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (_, posSnap) {
                final pos = posSnap.data ?? Duration.zero;
                Duration? activeKey;
                for (final k in keys) {
                  if (pos >= k) activeKey = k;
                }
                return ListView.builder(
                  controller: ctrl,
                  itemCount: keys.length,
                  itemBuilder: (_, i) {
                    final k      = keys[i];
                    final active = k == activeKey;
                    return AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize:   active ? 22 : 17,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color:      active ? Colors.white : Colors.white54,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 6),
                        child: Text(lrcMap[k] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }

        // Sin LRC — mostrar letra plana
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, ctrl) => SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            child: Text(plain ?? 'Sin letra disponible.',
                style: const TextStyle(fontSize: 16, height: 1.8)),
          ),
        );
      },
    );
  }
}
