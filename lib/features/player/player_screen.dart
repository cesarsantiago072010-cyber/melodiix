import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:just_audio/just_audio.dart'; // ← agrega esta
import '../../core/providers/providers.dart';
import '../../core/providers/background_audio_provider.dart';
import '../../core/theme/glass_theme.dart';
import '../lyrics/lyrics_view.dart';
import '../../models/track.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  Color _dominantColor = const Color(0xFF1A1A2E);
  bool  _loadingStream = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrack());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final player = ref.read(audioPlayerProvider);
      player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _playRelated();
        }
      });
    });
  }

  Future<void> _loadTrack() async {
    final track = ref.read(currentTrackProvider);
    if (track == null) return;

    setState(() => _loadingStream = true);
    try {
      final dio    = ref.read(dioProvider);
      final player = ref.read(audioPlayerProvider);
      final resp   = await dio.get('/stream/${track.id}');
      final url    = resp.data['url'] as String;
      await playWithMetadata(player: player, track: track, streamUrl: url);

      if (track.thumbnailUrl.isNotEmpty) {
        final gen = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider(track.thumbnailUrl),
          size: const Size(200, 200),
        );
        if (mounted) {
          setState(() {
            _dominantColor = gen.dominantColor?.color ?? const Color(0xFF1A1A2E);
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loadingStream = false);
    }
  }

  Future<void> _playRelated() async {
    final track = ref.read(currentTrackProvider);
    if (track == null) return;
    final dio = ref.read(dioProvider);
    try {
      final resp = await dio.get('/related/${track.id}');
      final tracks = (resp.data['tracks'] as List)
          .map((t) => Track.fromJson(t as Map<String, dynamic>))
          .toList();
      final filtered = tracks.where((t) => t.id != track.id).toList();
      if (filtered.isNotEmpty) {
        final next = filtered.first;
        final streamResp = await dio.get('/stream/${next.id}');
        final url = streamResp.data['url'] as String;
        if (mounted) {
          ref.read(currentTrackProvider.notifier).state = next;
          await playWithMetadata(
            player: ref.read(audioPlayerProvider),
            track: next,
            streamUrl: url,
          );
          if (next.thumbnailUrl.isNotEmpty) {
            final gen = await PaletteGenerator.fromImageProvider(
              CachedNetworkImageProvider(next.thumbnailUrl),
              size: const Size(200, 200),
            );
            if (mounted) {
              setState(() {
                _dominantColor = gen.dominantColor?.color ?? const Color(0xFF1A1A2E);
              });
            }
          }
        }
      }
    } catch (e) {
      print('Autoplay error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final track  = ref.watch(currentTrackProvider);
    final player = ref.watch(audioPlayerProvider);
    if (track == null) return const SizedBox.shrink();

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [_dominantColor.withOpacity(0.9), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Top bar
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text('Reproduciendo', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 32),
                // Album art
                GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CachedNetworkImage(
                      imageUrl: track.thumbnailUrl,
                      width: 280, height: 280,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(width: 280, height: 280, color: Colors.black26),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Track info
                Text(track.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(track.artist,
                    style: TextStyle(color: Colors.white.withOpacity(0.6))),
                const SizedBox(height: 24),
                // Progress
                if (_loadingStream)
                  const LinearProgressIndicator()
                else
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (_, snap) {
                      final pos      = snap.data ?? Duration.zero;
                      final duration = player.duration ?? Duration.zero;
                      return Column(
                        children: [
                          Slider(
                            value: pos.inMilliseconds.toDouble().clamp(
                                0, duration.inMilliseconds.toDouble()),
                            max: duration.inMilliseconds.toDouble(),
                            onChanged: (v) =>
                                player.seek(Duration(milliseconds: v.toInt())),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos),
                                    style: const TextStyle(fontSize: 12)),
                                Text(_fmt(duration),
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 16),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.skip_previous, size: 36),
                        onPressed: () {}),
                    StreamBuilder<bool>(
                      stream: player.playingStream,
                      builder: (_, snap) {
                        final playing = snap.data ?? false;
                        return IconButton(
                          icon: Icon(
                              playing ? Icons.pause_circle : Icons.play_circle,
                              size: 64),
                          onPressed: () =>
                          playing ? player.pause() : player.play(),
                        );
                      },
                    ),
                    IconButton(
                        icon: const Icon(Icons.skip_next, size: 36),
                        onPressed: () {}),
                  ],
                ),
                const SizedBox(height: 24),
                // Lyrics button
                OutlinedButton.icon(
                  icon: const Icon(Icons.lyrics_outlined),
                  label: const Text('Ver letra'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => LyricsView(track: track, player: player),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}