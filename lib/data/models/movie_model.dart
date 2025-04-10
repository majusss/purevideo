import 'package:purevideo/core/utils/supported_enum.dart';

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
  final Future<String> description;
  final Future<List<String>> links;

  const EpisodeModel({
    required this.title,
    required this.url,
    required this.description,
    required this.links,
  });
}

class SeasonModel {
  final String name;
  final List<EpisodeModel> episodes;

  const SeasonModel({required this.name, required this.episodes});
}

class MovieDetailsModel {
  final SupportedService service;
  final String title;
  final String description;
  final String imageUrl;
  final String year;
  final List<String> genres;
  final List<String> countries;
  final bool isSeries;
  final bool isEpisode;
  final List<String>? links;
  final List<SeasonModel>? seasons;

  const MovieDetailsModel({
    required this.service,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.year,
    required this.genres,
    required this.countries,
    this.isSeries = false,
    this.isEpisode = false,
    this.seasons,
    this.links,
  });
}
