import 'package:purevideo/data/models/movie_model.dart';

abstract class MovieRepository {
  Future<List<ServiceMovieModel>> getMovies();
  Future<ServiceMovieDetailsModel> getMovieDetails(String url);
  Future<EpisodeModel> getEpisodeHosts(EpisodeModel episode);
}
