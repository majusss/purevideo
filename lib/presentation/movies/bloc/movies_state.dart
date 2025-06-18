import 'package:purevideo/data/models/movie_model.dart';

abstract class MoviesState {
  const MoviesState();
}

class MoviesInitial extends MoviesState {}

class MoviesLoading extends MoviesState {}

class MoviesLoaded extends MoviesState {
  final List<MovieModel> movies;

  const MoviesLoaded(this.movies);
}

class MoviesError extends MoviesState {
  final String message;

  const MoviesError(this.message);
}
