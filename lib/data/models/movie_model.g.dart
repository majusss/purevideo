// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'movie_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceMovieModelAdapter extends TypeAdapter<ServiceMovieModel> {
  @override
  final int typeId = 6;

  @override
  ServiceMovieModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceMovieModel(
      service: fields[0] as SupportedService,
      url: fields[1] as String,
      title: fields[2] as String,
      imageUrl: fields[3] as String,
      category: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceMovieModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.service)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMovieModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MovieModelAdapter extends TypeAdapter<MovieModel> {
  @override
  final int typeId = 0;

  @override
  MovieModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovieModel(
      services: (fields[0] as List).cast<ServiceMovieModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, MovieModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.services);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EpisodeModelAdapter extends TypeAdapter<EpisodeModel> {
  @override
  final int typeId = 1;

  @override
  EpisodeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpisodeModel(
      title: fields[2] as String,
      number: fields[1] as int,
      url: fields[0] as String,
      videoUrls: (fields[3] as List?)?.cast<HostLink>(),
      directUrls: (fields[4] as List?)?.cast<VideoSource>(),
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.videoUrls)
      ..writeByte(4)
      ..write(obj.directUrls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SeasonModelAdapter extends TypeAdapter<SeasonModel> {
  @override
  final int typeId = 4;

  @override
  SeasonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SeasonModel(
      name: fields[0] as String,
      number: fields[1] as int,
      episodes: (fields[2] as List).cast<EpisodeModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, SeasonModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.number)
      ..writeByte(2)
      ..write(obj.episodes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeasonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ServiceMovieDetailsModelAdapter
    extends TypeAdapter<ServiceMovieDetailsModel> {
  @override
  final int typeId = 7;

  @override
  ServiceMovieDetailsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceMovieDetailsModel(
      service: fields[0] as SupportedService,
      url: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      imageUrl: fields[4] as String,
      isSeries: fields[10] as bool,
      videoUrls: (fields[5] as List?)?.cast<HostLink>(),
      seasons: (fields[11] as List?)?.cast<SeasonModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ServiceMovieDetailsModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.service)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.videoUrls)
      ..writeByte(10)
      ..write(obj.isSeries)
      ..writeByte(11)
      ..write(obj.seasons);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceMovieDetailsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MovieDetailsModelAdapter extends TypeAdapter<MovieDetailsModel> {
  @override
  final int typeId = 5;

  @override
  MovieDetailsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MovieDetailsModel(
      services: (fields[0] as List).cast<ServiceMovieDetailsModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, MovieDetailsModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.services);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MovieDetailsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
