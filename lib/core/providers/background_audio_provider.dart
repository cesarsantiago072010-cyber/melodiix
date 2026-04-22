import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/track.dart';

Future<void> playWithMetadata({
  required AudioPlayer player,
  required Track track,
  required String streamUrl,
}) async {
  final audioSource = AudioSource.uri(
    Uri.parse(streamUrl),
    tag: MediaItem(
      id:       track.id,
      title:    track.title,
      artist:   track.artist,
      album:    track.album,
      artUri:   track.thumbnailUrl.isNotEmpty
                    ? Uri.parse(track.thumbnailUrl)
                    : null,
      duration: Duration(milliseconds: track.durationMs),
    ),
  );
  await player.setAudioSource(audioSource);
  await player.play();
}
