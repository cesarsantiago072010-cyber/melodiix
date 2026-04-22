// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrackImpl _$$TrackImplFromJson(Map<String, dynamic> json) => _$TrackImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String? ?? '',
      thumbnailUrl: json['thumbnail'] as String? ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localPath: json['localPath'] as String?,
      streamUrl: json['streamUrl'] as String? ?? '',
    );

Map<String, dynamic> _$$TrackImplToJson(_$TrackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'album': instance.album,
      'thumbnail': instance.thumbnailUrl,
      'durationMs': instance.durationMs,
      'isDownloaded': instance.isDownloaded,
      'localPath': instance.localPath,
      'streamUrl': instance.streamUrl,
    };
