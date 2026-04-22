import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/providers/providers.dart';
import '../../models/track.dart';

class CrossfadePlayer {
  final AudioPlayer _player;
  final Ref _ref;
  static const int crossfadeSec = 3;
  StreamSubscription? _positionSub;
  bool _crossfading = false;

  CrossfadePlayer(this._player, this._ref);

  void startMonitoring() {
    _positionSub = _player.positionStream.listen((position) async {
      final duration = _player.duration;
      if (duration == null || _crossfading) return;
      if ((duration - position).inSeconds <= crossfadeSec) {
        _crossfading = true;
        await _performCrossfade();
        _crossfading = false;
      }
    });
  }

  Future<void> _performCrossfade() async {
    final queue = _ref.read(queueProvider);
    if (queue.isEmpty) {
      await _fetchAutoMix();
      return;
    }
    // Fade out
    for (double v = 1.0; v >= 0.0; v -= 0.1) {
      await _player.setVolume(v);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final next = queue.first;
    _ref.read(queueProvider.notifier).remove(next.id);
    await _playTrack(next);
    // Fade in
    for (double v = 0.0; v <= 1.0; v += 0.1) {
      await _player.setVolume(v);
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _fetchAutoMix() async {
    final current = _ref.read(currentTrackProvider);
    if (current == null) return;
    final dio   = _ref.read(dioProvider);
    final resp  = await dio.get('/search/related',
        queryParameters: {'track_id': current.id});
    final tracks = (resp.data['tracks'] as List)
        .map((t) => Track.fromJson(t as Map<String, dynamic>))
        .toList();
    _ref.read(queueProvider.notifier).addAll(tracks);
    if (tracks.isNotEmpty) await _playTrack(tracks.first);
  }

  Future<void> _playTrack(Track track) async {
    _ref.read(currentTrackProvider.notifier).state = track;
    final dio  = _ref.read(dioProvider);
    final resp = await dio.get('/stream/${track.id}');
    await _player.setAudioSource(
        AudioSource.uri(Uri.parse(resp.data['url'] as String)));
    await _player.play();
  }

  void dispose() => _positionSub?.cancel();
}

final crossfadePlayerProvider = Provider<CrossfadePlayer>((ref) {
  final player = ref.watch(audioPlayerProvider);
  final cf     = CrossfadePlayer(player, ref);
  cf.startMonitoring();
  ref.onDispose(cf.dispose);
  return cf;
});
