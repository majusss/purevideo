import 'package:hive_flutter/adapters.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/watched_model.dart';

class WatchedService {
  late final Box<WatchedMovieModel> box;

  Future<void> init() async {
    box = await Hive.openBox<WatchedMovieModel>('watched');
  }

  List<WatchedMovieModel> getAll() {
    return box.values.toList();
  }

  WatchedMovieModel? getByMovie(MovieDetailsModel movie) {
    return box.get(movie.url);
  }

  WatchedEpisodeModel? getByEpisode(
      MovieDetailsModel movie, EpisodeModel episode) {
    final watchedMovie = box.get(movie.url);
    return watchedMovie?.getEpisodeByUrl(episode.url);
  }

  void watchMovie(MovieDetailsModel movie, int watchedTime) {
    final watchedMovie = WatchedMovieModel(
      movie: movie,
      watchedTime: watchedTime,
      watchedAt: DateTime.now(),
    );
    box.put(movie.url, watchedMovie);
  }

  void watchEpisode(
    MovieDetailsModel movie,
    EpisodeModel episode,
    int watchedTime,
  ) {
    var watchedMovie = box.get(movie.url) ??
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

    watchedMovie.episodes!.add(watchedEpisode);

    box.put(movie.url, watchedMovie);
  }
}
