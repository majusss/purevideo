// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_host_scraper.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoSourceAdapter extends TypeAdapter<VideoSource> {
  @override
  final int typeId = 3;

  @override
  VideoSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoSource(
      url: fields[0] as String,
      lang: fields[1] as String,
      quality: fields[2] as String,
      host: fields[3] as String,
      headers: (fields[4] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VideoSource obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.lang)
      ..writeByte(2)
      ..write(obj.quality)
      ..writeByte(3)
      ..write(obj.host)
      ..writeByte(4)
      ..write(obj.headers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
