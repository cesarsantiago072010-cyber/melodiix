import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../models/track.dart';

class DownloadEntry {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String streamUrl;
  String status;
  int    progress;
  String? localPath;

  DownloadEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.streamUrl,
    this.status   = 'queued',
    this.progress = 0,
  });
}

class DownloadsNotifier extends StateNotifier<List<DownloadEntry>> {
  final Ref _ref;
  final Map<String, Timer> _pollers = {};

  DownloadsNotifier(this._ref) : super([]);

  Future<void> startDownload(Track track) async {
    if (state.any((d) => d.id == track.id)) return;
    final entry = DownloadEntry(
      id:           track.id,
      title:        track.title,
      artist:       track.artist,
      thumbnailUrl: track.thumbnailUrl,
      streamUrl:    track.streamUrl,
    );
    state = [...state, entry];
    final dio = _ref.read(dioProvider);
    await dio.post(
      '/downloads/${track.id}',
      queryParameters: {'stream_url': track.streamUrl},
    );
    _pollers[track.id] = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollStatus(track.id),
    );
  }

  Future<void> _pollStatus(String id) async {
    final dio  = _ref.read(dioProvider);
    final resp = await dio.get('/downloads/$id/status');
    final data = resp.data as Map<String, dynamic>;
    final status   = data['status']   as String;
    final progress = (data['progress'] as num?)?.toInt() ?? 0;
    String? localPath;
    if (status == 'complete') {
      final fr = await dio.get('/downloads/file/$id');
      localPath = fr.data['path'] as String?;
      _pollers[id]?.cancel();
    }
    state = state.map((d) {
      if (d.id == id) {
        d.status   = status;
        d.progress = progress;
        if (localPath != null) d.localPath = localPath;
      }
      return d;
    }).toList();
  }

  Future<void> deleteDownload(String id) async {
    await _ref.read(dioProvider).delete('/downloads/$id');
    _pollers[id]?.cancel();
    state = state.where((d) => d.id != id).toList();
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsNotifier, List<DownloadEntry>>(
  (ref) => DownloadsNotifier(ref),
);

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Descargas')),
      body: downloads.isEmpty
          ? const Center(child: Text('Sin descargas todavía.'))
          : ListView.builder(
              itemCount: downloads.length,
              itemBuilder: (_, i) {
                final d = downloads[i];
                return ListTile(
                  leading: d.thumbnailUrl.isNotEmpty
                      ? Image.network(d.thumbnailUrl,
                          width: 48, height: 48, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                  title:    Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.artist),
                      if (d.status == 'downloading')
                        LinearProgressIndicator(value: d.progress / 100),
                      if (d.status == 'complete')
                        const Text('✓ Descargado',
                            style: TextStyle(color: Colors.green)),
                      if (d.status == 'error')
                        const Text('✗ Error',
                            style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(downloadsProvider.notifier).deleteDownload(d.id),
                  ),
                );
              },
            ),
    );
  }
}
