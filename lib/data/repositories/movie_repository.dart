import 'package:purevideo/data/models/movie_model.dart';

abstract class MovieRepository {
  Future<List<MovieModel>> getMovies();
  Future<MovieDetailsModel> getMovieDetails(String url);
}
