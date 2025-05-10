import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/blocs/movies/movies_event.dart';
import 'package:purevideo/presentation/blocs/movies/movies_state.dart';

class MoviesBloc extends Bloc<MoviesEvent, MoviesState> {
  final Map<SupportedService, MovieRepository> _repositories = getIt();
  final Map<SupportedService, AuthRepository> _authRepositories = getIt();
  final List<MovieModel> _movies = [];
  final List<StreamSubscription<AuthModel>> _authSubscriptions = [];

  MoviesBloc() : super(MoviesInitial()) {
    on<LoadMoviesRequested>(_onLoadMoviesRequested);
    _setupAuthListeners();
  }

  void _setupAuthListeners() {
    for (final authRepo in _authRepositories.values) {
      final subscription = authRepo.authStream.listen((auth) {
        add(LoadMoviesRequested());
      });
      _authSubscriptions.add(subscription);
    }
  }

  @override
  Future<void> close() {
    for (final subscription in _authSubscriptions) {
      subscription.cancel();
    }
    return super.close();
  }

  Future<void> _onLoadMoviesRequested(
    LoadMoviesRequested event,
    Emitter<MoviesState> emit,
  ) async {
    try {
      emit(MoviesLoading());
      _movies.clear();

      bool hasLoggedInUser = false;
      for (final entry in _authRepositories.entries) {
        final account = entry.value.getAccountForService(entry.key);
        if (account != null) {
          hasLoggedInUser = true;
          break;
        }
      }

      if (!hasLoggedInUser) {
        emit(const MoviesError('Zaloguj się aby zobaczyć filmy'));
        return;
      }

      for (final entry in _repositories.entries) {
        final service = entry.key;
        final repository = entry.value;
        final authRepo = _authRepositories[service];
        final account = authRepo?.getAccountForService(service);

        if (account != null) {
          _movies.addAll(await repository.getMovies());
        }
      }

      if (_movies.isEmpty) {
        emit(const MoviesError('Brak dostępnych filmów'));
      } else {
        emit(MoviesLoaded(_movies));
      }
    } catch (e) {
      emit(MoviesError(e.toString()));
    }
  }
}
