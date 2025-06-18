import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:collection/collection.dart';

part 'watched_model.g.dart';

@HiveType(typeId: 9)
class WatchedEpisodeModel {
  @HiveField(0)
  final EpisodeModel episode;

  @HiveField(1)
  final int watchedTime;

  @HiveField(2)
  final DateTime? watchedAt;

  WatchedEpisodeModel(
      {required this.episode, required this.watchedTime, this.watchedAt});
}

@HiveType(typeId: 10)
class WatchedMovieModel {
  @HiveField(0)
  final MovieDetailsModel movie;

  @HiveField(1)
  final List<WatchedEpisodeModel>? episodes;

  @HiveField(2)
  final int watchedTime;

  @HiveField(3)
  final DateTime watchedAt;

  WatchedMovieModel(
      {required this.movie,
      required this.watchedTime,
      required this.watchedAt,
      this.episodes});

  WatchedEpisodeModel? getEpisodeByUrl(String url) {
    return episodes?.firstWhereOrNull(
      (episode) => episode.episode.url == url,
    );
  }
}
