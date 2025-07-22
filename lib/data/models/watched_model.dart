import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/data/models/movie_model.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';

part 'watched_model.g.dart';

@HiveType(typeId: 11)
class WatchedSeasonEpisode {
  @HiveField(0)
  final SeasonModel season;

  @HiveField(1)
  final WatchedEpisodeModel watchedEpisode;

  WatchedSeasonEpisode({required this.season, required this.watchedEpisode});
}

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

  @override
  String toString() {
    return 'WatchedEpisodeModel(episode: $episode, watchedTime: $watchedTime, watchedAt: $watchedAt)';
  }
}

@HiveType(typeId: 10)
class WatchedMovieModel {
  @HiveField(0)
  final MovieDetailsModel movie;

  @HiveField(1)
  final List<WatchedSeasonEpisode>? episodes;

  @HiveField(2)
  final int watchedTime;

  @HiveField(3)
  final DateTime watchedAt;

  WatchedSeasonEpisode? get lastWatchedEpisode {
    if (episodes == null || episodes!.isEmpty) {
      return null;
    }

    return episodes!.reduce(
      (current, next) {
        final currentDate = current.watchedEpisode.watchedAt;
        final nextDate = next.watchedEpisode.watchedAt;

        if (currentDate == null && nextDate == null) {
          return current;
        }
        if (currentDate == null) {
          return next;
        }
        if (nextDate == null) {
          return current;
        }

        return currentDate.isAfter(nextDate) ? current : next;
      },
    );
  }

  WatchedMovieModel(
      {required this.movie,
      required this.watchedTime,
      required this.watchedAt,
      this.episodes});

  WatchedMovieModel copyWith({
    MovieDetailsModel? movie,
    List<WatchedSeasonEpisode>? episodes,
    int? watchedTime,
    DateTime? watchedAt,
  }) {
    return WatchedMovieModel(
      movie: movie ?? this.movie,
      episodes: episodes ?? this.episodes,
      watchedTime: watchedTime ?? this.watchedTime,
      watchedAt: watchedAt ?? this.watchedAt,
    );
  }

  WatchedEpisodeModel? getEpisodeByUrl(String url) {
    return episodes
        ?.firstWhereOrNull(
          (episode) => episode.watchedEpisode.episode.url == url,
        )
        ?.watchedEpisode;
  }

  @override
  String toString() {
    return 'WatchedMovieModel(movie: $movie, episodes: $episodes, watchedTime: $watchedTime, watchedAt: $watchedAt)';
  }
}
