import 'dart:async';
import 'package:collection/collection.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/watched_model.dart';

class WatchedService {
  late final Box<WatchedMovieModel> box;
  final StreamController<List<WatchedMovieModel>> _watchedController =
      StreamController<List<WatchedMovieModel>>.broadcast();

  Stream<List<WatchedMovieModel>> get watchedStream =>
      _watchedController.stream;

  Future<void> init() async {
    try {
      box = await Hive.openBox<WatchedMovieModel>('watched');
    } catch (e) {
      await Hive.deleteBoxFromDisk('watched');
      box = await Hive.openBox<WatchedMovieModel>('watched');
    }
    _notifyListeners();
  }

  void _notifyListeners() {
    _watchedController.add(getAll());
  }

  void dispose() {
    _watchedController.close();
  }

  List<WatchedMovieModel> getAll() {
    return box.values.toList();
  }

  WatchedMovieModel? getByMovie(MovieDetailsModel movie) {
    final movieServiceUrls =
        movie.services.map((service) => service.url).toSet();
    return box.values.firstWhereOrNull((boxElement) {
      final boxServiceUrls =
          boxElement.movie.services.map((service) => service.url).toSet();
      return movieServiceUrls.intersection(boxServiceUrls).isNotEmpty;
    });
  }

  WatchedEpisodeModel? getByEpisode(
      MovieDetailsModel movie, EpisodeModel episode) {
    final watchedMovie = getByMovie(movie);
    return watchedMovie?.getEpisodeByUrl(episode.url);
  }

  void watchMovie(MovieDetailsModel movie, int watchedTime) {
    final watchedMovie = WatchedMovieModel(
      movie: movie,
      watchedTime: watchedTime,
      watchedAt: DateTime.now(),
    );
    box.add(watchedMovie);
    _notifyListeners();
  }

  void watchEpisode(
    MovieDetailsModel movie,
    SeasonModel season,
    EpisodeModel episode,
    int watchedTime,
  ) {
    var watchedMovie = getByMovie(movie)?.copyWith(
          watchedAt: DateTime.now(),
        ) ??
        WatchedMovieModel(
          movie: movie,
          watchedTime: 0,
          watchedAt: DateTime.now(),
          episodes: [],
        );

    final watchedEpisode = WatchedEpisodeModel(
      episode: episode,
      watchedTime: watchedTime,
      watchedAt: DateTime.now(),
    );

    watchedMovie.episodes!.add(
        WatchedSeasonEpisode(season: season, watchedEpisode: watchedEpisode));

    box.add(watchedMovie);
    _notifyListeners();
  }
}
