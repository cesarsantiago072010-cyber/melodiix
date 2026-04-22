import 'package:freezed_annotation/freezed_annotation.dart';

part 'track.freezed.dart';
part 'track.g.dart';

@freezed
class Track with _$Track {
  const factory Track({
    required String id,
    required String title,
    required String artist,
    @Default('') String album,
    @JsonKey(name: 'thumbnail') @Default('') String thumbnailUrl,
    @Default(0) int durationMs,
    @Default(false) bool isDownloaded,
    String? localPath,
    @Default('') String streamUrl,  // URL de stream de SoundCloud
  }) = _Track;

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);
}
