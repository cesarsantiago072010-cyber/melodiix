import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:dio/dio.dart';
import '../../models/track.dart';

// ------- Networking -------
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: 'http://192.168.1.70:8000', // Emulador Android
    // Dispositivo físico → cambia por tu IP local: 'http://192.168.1.X:8000'
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
});

// ------- Audio -------
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(() => player.dispose());
  return player;
});

// ------- Estado global -------
final currentTrackProvider = StateProvider<Track?>((ref) => null);

final queueProvider = StateNotifierProvider<QueueNotifier, List<Track>>(
  (ref) => QueueNotifier(),
);

class QueueNotifier extends StateNotifier<List<Track>> {
  QueueNotifier() : super([]);

  void add(Track t) => state = [...state, t];
  void addAll(List<Track> tracks) => state = [...state, ...tracks];
  void clear() => state = [];
  void remove(String id) => state = state.where((t) => t.id != id).toList();
  Track? get next => state.isNotEmpty ? state.first : null;
}
