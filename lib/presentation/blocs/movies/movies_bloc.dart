import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/movies/movies_event.dart';
import 'package:purevideo/presentation/blocs/movies/movies_state.dart';

class MoviesBloc extends Bloc<MoviesEvent, MoviesState> {
  final Map<SupportedService, MovieRepository> _repositories = getIt();
  final List<MovieModel> _movies = [];

  MoviesBloc() : super(MoviesInitial()) {
    on<LoadMoviesRequested>(_onLoadMoviesRequested);
  }

  Future<void> _onLoadMoviesRequested(
    LoadMoviesRequested event,
    Emitter<MoviesState> emit,
  ) async {
    try {
      emit(MoviesLoading());
      for (final repository in _repositories.values) {
        _movies.addAll(await repository.getMovies());
      }
      emit(MoviesLoaded(_movies));
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }
}
