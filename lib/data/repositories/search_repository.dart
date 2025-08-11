import 'package:purevideo/data/models/movie_model.dart';

abstract class SearchRepository {
  Future<List<ServiceMovieModel>> searchMovies(String query);
}
