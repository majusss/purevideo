import 'package:purevideo/data/models/movie_model.dart';

class MergeService {
  // final List<MovieDetailsModel> _movieDetails = [];
  final List<MovieModel> _movies = [];

  Future<void> addFromService(List<ServiceMovieModel> movies) async {
    if (movies.isEmpty) return;

    for (final movie in movies) {
      final normalizedTitle = _normalizeTitle(movie.title);

      final existingMovieIndex = _movies.indexWhere(
        (existingMovie) =>
            _normalizeTitle(existingMovie.services.first.title) ==
            normalizedTitle,
      );

      if (existingMovieIndex != -1) {
        final existingMovie = _movies[existingMovieIndex];
        final hasService = existingMovie.services.any(
          (service) => service.service == movie.service,
        );

        if (!hasService) {
          final updatedServices = [...existingMovie.services, movie];
          _movies[existingMovieIndex] = MovieModel(services: updatedServices);
        }
      } else {
        _movies.add(MovieModel(services: [movie]));
      }
    }
  }

  Future<List<MovieModel>> addFromServiceTemp(
      List<ServiceMovieModel> toAdd, List<MovieModel> existingMovies) async {
    if (toAdd.isEmpty) return [];

    for (final movie in toAdd) {
      final normalizedTitle = _normalizeTitle(movie.title);

      final existingMovieIndex = existingMovies.indexWhere(
        (existingMovie) =>
            _normalizeTitle(existingMovie.services.first.title) ==
            normalizedTitle,
      );

      if (existingMovieIndex != -1) {
        final existingMovie = existingMovies[existingMovieIndex];
        final hasService = existingMovie.services.any(
          (service) => service.service == movie.service,
        );

        if (!hasService) {
          final updatedServices = [...existingMovie.services, movie];
          existingMovies[existingMovieIndex] =
              MovieModel(services: updatedServices);
        }
      } else {
        existingMovies.add(MovieModel(services: [movie]));
      }
    }

    return existingMovies;
  }

  List<MovieModel> get getMovies => _movies;

  List<MovieModel> searchMovies(String query) {
    final normalizedQuery = _normalizeTitle(query);
    return _movies.where((movie) {
      final movieTitle = _normalizeTitle(movie.services.first.title);
      return movieTitle.contains(normalizedQuery);
    }).toList();
  }

  String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
