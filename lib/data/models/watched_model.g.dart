// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watched_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchedEpisodeModelAdapter extends TypeAdapter<WatchedEpisodeModel> {
  @override
  final int typeId = 9;

  @override
  WatchedEpisodeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchedEpisodeModel(
      episode: fields[0] as EpisodeModel,
      watchedTime: fields[1] as int,
      watchedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WatchedEpisodeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.episode)
      ..writeByte(1)
      ..write(obj.watchedTime)
      ..writeByte(2)
      ..write(obj.watchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchedEpisodeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WatchedMovieModelAdapter extends TypeAdapter<WatchedMovieModel> {
  @override
  final int typeId = 10;

  @override
  WatchedMovieModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchedMovieModel(
      movie: fields[0] as MovieDetailsModel,
      watchedTime: fields[2] as int,
      watchedAt: fields[3] as DateTime,
      episodes: (fields[1] as List?)?.cast<WatchedEpisodeModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, WatchedMovieModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.movie)
      ..writeByte(1)
      ..write(obj.episodes)
      ..writeByte(2)
      ..write(obj.watchedTime)
      ..writeByte(3)
      ..write(obj.watchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchedMovieModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
