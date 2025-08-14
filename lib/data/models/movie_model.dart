import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/di/injection_container.dart';

part 'movie_model.g.dart';

@HiveType(typeId: 6)
class ServiceMovieModel {
  @HiveField(0)
  final SupportedService service;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String? category;

  const ServiceMovieModel({
    required this.service,
    required this.url,
    required this.title,
    required this.imageUrl,
    this.category,
  });
}

@HiveType(typeId: 0)
class MovieModel {
  @HiveField(0)
  final List<ServiceMovieModel> services;

  get title => services.first.title;

  get imageUrl => services.first.imageUrl;

  Map<String, String> get imageHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
        'Cookie': getIt<Map<SupportedService, AuthRepository>>()[
                    services.first.service]
                ?.getAccount()
                ?.cookies
                .join('; ') ??
            '',
      };

  const MovieModel({
    required this.services,
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
  final int number;

  @HiveField(1)
  final List<EpisodeModel> episodes;

  SeasonModel({required this.number, required this.episodes});
}

@HiveType(typeId: 7)
class ServiceMovieDetailsModel {
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

  @HiveField(10)
  final bool isSeries;

  @HiveField(11)
  final List<SeasonModel>? seasons;

  const ServiceMovieDetailsModel({
    required this.service,
    required this.url,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isSeries,
    this.videoUrls,
    this.seasons,
  });

  ServiceMovieDetailsModel copyWith({
    SupportedService? service,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    List<HostLink>? videoUrls,
    String? year,
    List<String>? genres,
    List<String>? countries,
    bool? isSeries,
    List<SeasonModel>? seasons,
  }) {
    return ServiceMovieDetailsModel(
      service: service ?? this.service,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrls: videoUrls ?? this.videoUrls,
      isSeries: isSeries ?? this.isSeries,
      seasons: seasons ?? this.seasons,
    );
  }

  @override
  String toString() {
    return 'ServiceMovieDetailsModel(service: $service, url: $url, title: $title, description: $description, imageUrl: $imageUrl, videoUrls: $videoUrls, isSeries: $isSeries, seasons: $seasons)';
  }
}

@HiveType(typeId: 5)
class MovieDetailsModel {
  @HiveField(0)
  final List<ServiceMovieDetailsModel> services;

  String get title => services.first.title;

  String get description => services.first.description;

  Map<String, String> get imageHeaders => {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
        'Cookie': getIt<Map<SupportedService, AuthRepository>>()[
                    services.first.service]
                ?.getAccount()
                ?.cookies
                .join('; ') ??
            '',
      };

  String get imageUrl => services.first.imageUrl;

  List<HostLink>? get videoUrls =>
      services.expand((e) => e.videoUrls as Iterable<HostLink>).toList();

  final List<VideoSource>? directUrls;

  bool get isSeries => services.first.isSeries;

  final List<SeasonModel>? seasons;

  static List<SeasonModel> _combineSeasons(
      List<ServiceMovieDetailsModel> services) {
    final Map<int, SeasonModel> combinedSeasons = {};

    for (final service in services) {
      if (service.seasons != null) {
        for (final season in service.seasons!) {
          if (combinedSeasons.containsKey(season.number)) {
            final existingSeason = combinedSeasons[season.number]!;
            final allEpisodes = <EpisodeModel>[
              ...existingSeason.episodes,
              ...season.episodes,
            ];

            final Map<int, EpisodeModel> uniqueEpisodes = {};
            for (final episode in allEpisodes) {
              uniqueEpisodes[episode.number] = episode;
            }

            combinedSeasons[season.number] = SeasonModel(
              number: season.number,
              episodes: uniqueEpisodes.values.toList()
                ..sort((a, b) => a.number.compareTo(b.number)),
            );
          } else {
            combinedSeasons[season.number] = SeasonModel(
              number: season.number,
              episodes: season.episodes,
            );
          }
        }
      }
    }

    return combinedSeasons.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  MovieDetailsModel({required this.services, this.directUrls})
      : seasons = _combineSeasons(services);

  MovieDetailsModel copyWith({
    List<ServiceMovieDetailsModel>? services,
    List<VideoSource>? directUrls,
  }) {
    return MovieDetailsModel(
      services: services ?? this.services,
      directUrls: directUrls ?? this.directUrls,
    );
  }

  @override
  String toString() {
    return 'MovieDetailsModel(services: $services, title: $title, description: $description, imageUrl: $imageUrl, videoUrls: $videoUrls, directUrls: $directUrls, isSeries: $isSeries, seasons: $seasons)';
  }
}
