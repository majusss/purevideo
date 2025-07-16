import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/link_model.dart';

part 'movie_model.g.dart';

@HiveType(typeId: 0)
class MovieModel {
  @HiveField(0)
  final SupportedService service;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final String url;

  @HiveField(4)
  final String? category;

  const MovieModel({
    required this.service,
    required this.title,
    required this.imageUrl,
    required this.url,
    this.category,
  });
}

@HiveType(typeId: 1)
class EpisodeModel {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final int number;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final List<HostLink>? videoUrls;

  @HiveField(4)
  final List<VideoSource>? directUrls;

  EpisodeModel(
      {required this.title,
      required this.number,
      required this.url,
      required this.videoUrls,
      this.directUrls});

  EpisodeModel copyWith({
    String? url,
    int? number,
    String? title,
    List<HostLink>? videoUrls,
    List<VideoSource>? directUrls,
  }) {
    return EpisodeModel(
        url: url ?? this.url,
        number: number ?? this.number,
        title: title ?? this.title,
        videoUrls: videoUrls ?? this.videoUrls,
        directUrls: directUrls ?? this.directUrls);
  }
}

@HiveType(typeId: 4)
class SeasonModel {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int number;

  @HiveField(2)
  final List<EpisodeModel> episodes;

  SeasonModel(
      {required this.name, required this.number, required this.episodes});
}

@HiveType(typeId: 5)
class MovieDetailsModel {
  @HiveField(0)
  final SupportedService service;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final List<HostLink>? videoUrls;

  @HiveField(6)
  final List<VideoSource>? directUrls;

  @HiveField(7)
  final String year;

  @HiveField(8)
  final List<String> genres;

  @HiveField(9)
  final List<String> countries;

  @HiveField(10)
  final bool isSeries;

  @HiveField(11)
  final List<SeasonModel>? seasons;

  const MovieDetailsModel(
      {required this.service,
      required this.url,
      required this.title,
      required this.description,
      required this.imageUrl,
      required this.year,
      required this.genres,
      required this.countries,
      required this.isSeries,
      this.videoUrls,
      this.seasons,
      this.directUrls});

  MovieDetailsModel copyWith({
    SupportedService? service,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    List<HostLink>? videoUrls,
    List<VideoSource>? directUrls,
    String? year,
    List<String>? genres,
    List<String>? countries,
    bool? isSeries,
    List<SeasonModel>? seasons,
  }) {
    return MovieDetailsModel(
      service: service ?? this.service,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrls: videoUrls ?? this.videoUrls,
      directUrls: directUrls ?? this.directUrls,
      year: year ?? this.year,
      genres: genres ?? this.genres,
      countries: countries ?? this.countries,
      isSeries: isSeries ?? this.isSeries,
      seasons: seasons ?? this.seasons,
    );
  }

  @override
  String toString() {
    return 'MovieDetailsModel(service: $service, url: $url, title: $title, description: $description, imageUrl: $imageUrl, videoUrls: $videoUrls, directUrls: $directUrls, year: $year, genres: $genres, countries: $countries, isSeries: $isSeries, seasons: $seasons)';
  }
}

@HiveType(typeId: 6)
class Season {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<Episode> episodes;

  const Season({
    required this.name,
    required this.episodes,
  });
}

@HiveType(typeId: 7)
class Episode {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String description;

  const Episode({
    required this.title,
    required this.url,
    required this.description,
  });
}
