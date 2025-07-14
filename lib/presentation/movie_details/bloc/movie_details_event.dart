import 'package:equatable/equatable.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/watched_model.dart';

abstract class MovieDetailsEvent extends Equatable {
  const MovieDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMovieDetails extends MovieDetailsEvent {
  final SupportedService service;
  final String url;

  const LoadMovieDetails({
    required this.service,
    required this.url,
  });

  @override
  List<Object> get props => [service, url];
}

class ScrapeVideoUrls extends MovieDetailsEvent {
  final MovieDetailsModel movie;
  final SupportedService service;

  const ScrapeVideoUrls({required this.movie, required this.service});

  @override
  List<Object> get props => [movie, service];
}

class SelectSeason extends MovieDetailsEvent {
  final int seasonIndex;

  const SelectSeason({required this.seasonIndex});

  @override
  List<Object> get props => [seasonIndex];
}

class ScrapeEpisode extends MovieDetailsEvent {
  final SupportedService service;
  final int seasonIndex;
  final int episodeIndex;

  const ScrapeEpisode({
    required this.service,
    required this.seasonIndex,
    required this.episodeIndex,
  });

  @override
  List<Object> get props => [service, seasonIndex, episodeIndex];
}

class ContinueScrapingEpisodes extends MovieDetailsEvent {
  final SupportedService? service;
  final int? seasonIndex;
  final int? lastScrapedEpisodeIndex;

  const ContinueScrapingEpisodes({
    this.service,
    this.seasonIndex,
    this.lastScrapedEpisodeIndex,
  });

  @override
  List<Object?> get props => [service, seasonIndex, lastScrapedEpisodeIndex];
}

class StopScrapingEpisodes extends MovieDetailsEvent {
  const StopScrapingEpisodes();
}

class ScrapeCurrentSeasonEpisodes extends MovieDetailsEvent {
  final SupportedService service;

  const ScrapeCurrentSeasonEpisodes({required this.service});

  @override
  List<Object> get props => [service];
}

class UpdateWatchedStatus extends MovieDetailsEvent {
  final WatchedMovieModel? watched;

  const UpdateWatchedStatus({required this.watched});

  @override
  List<Object?> get props => [watched];
}
