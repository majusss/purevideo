import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/link_model.dart';

class MovieModel {
  final SupportedService service;
  final String title;
  final String imageUrl;
  final String url;
  final String? category;

  const MovieModel({
    required this.service,
    required this.title,
    required this.imageUrl,
    required this.url,
    this.category,
  });
}

class EpisodeModel {
  final String url;
  final String title;
  final List<HostLink>? videoUrls;
  final List<VideoSource>? directUrls;

  const EpisodeModel(
      {required this.title,
      required this.url,
      required this.videoUrls,
      this.directUrls});

  EpisodeModel copyWith({
    String? url,
    String? title,
    List<HostLink>? videoUrls,
    List<VideoSource>? directUrls,
  }) {
    return EpisodeModel(
        url: url ?? this.url,
        title: title ?? this.title,
        videoUrls: videoUrls ?? this.videoUrls,
        directUrls: directUrls ?? this.directUrls);
  }
}

class SeasonModel {
  final String name;
  final List<EpisodeModel> episodes;

  const SeasonModel({required this.name, required this.episodes});

  SeasonModel copyWith({
    String? name,
    List<EpisodeModel>? episodes,
  }) {
    return SeasonModel(
        name: name ?? this.name, episodes: episodes ?? this.episodes);
  }
}

class MovieDetailsModel {
  final SupportedService service;
  final String url;
  final String title;
  final String description;
  final String imageUrl;
  final List<HostLink>? videoUrls;
  final List<VideoSource>? directUrls;
  final String year;
  final List<String> genres;
  final List<String> countries;
  final bool isSeries;
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

class Season {
  final String name;
  final List<Episode> episodes;

  const Season({
    required this.name,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      name: json['name'] as String,
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }
}

class Episode {
  final String title;
  final String url;
  final String description;
  final List<String> links;

  const Episode({
    required this.title,
    required this.url,
    required this.description,
    required this.links,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      title: json['title'] as String,
      url: json['url'] as String,
      description: json['description'] as String,
      links: (json['links'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'description': description,
      'links': links,
    };
  }
}
