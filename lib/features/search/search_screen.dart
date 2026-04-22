import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/providers/providers.dart';
import '../../models/track.dart';
import '../player/player_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.family<List<Track>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final dio = ref.read(dioProvider);
  final resp = await dio.get('/search/', queryParameters: {'q': query});
  return (resp.data['tracks'] as List)
      .map((t) => Track.fromJson(t as Map<String, dynamic>))
      .toList();
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_ctrl.text == value) {
        ref.read(searchQueryProvider.notifier).state = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query   = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('Melodix')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Buscar en SoundCloud...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Error: $e')),
              data:    (tracks) => ListView.builder(
                itemCount: tracks.length,
                itemBuilder: (ctx, i) {
                  final t = tracks[i];
                  return ListTile(
                    leading: t.thumbnailUrl.isNotEmpty
                        ? Image.network(t.thumbnailUrl,
                            width: 48, height: 48, fit: BoxFit.cover)
                        : const Icon(Icons.music_note),
                    title:    Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(t.artist),
                    onTap: () {
                      ref.read(currentTrackProvider.notifier).state = t;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlayerScreen()),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
