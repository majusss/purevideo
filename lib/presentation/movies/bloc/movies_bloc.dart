import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/services/merg_service.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/movies/bloc/movies_event.dart';
import 'package:purevideo/presentation/movies/bloc/movies_state.dart';

class MoviesBloc extends Bloc<MoviesEvent, MoviesState> {
  final Map<SupportedService, MovieRepository> _repositories = getIt();
  final Map<SupportedService, AuthRepository> _authRepositories = getIt();
  final WatchedService _watchedService = getIt();
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
    if (state is MoviesLoading) return;
    try {
      emit(MoviesLoading());
      _movies.clear();

      bool hasLoggedInUser = false;
      for (final entry in _authRepositories.entries) {
        final account = entry.value.getAccount();
        if (account != null) {
          hasLoggedInUser = true;
          break;
        }
      }

      if (!hasLoggedInUser) {
        emit(const MoviesError('Zaloguj się aby zobaczyć filmy'));
        return;
      }
      // need combine here
      _movies.addAll(_watchedService
          .getAll()
          .sorted(
            (a, b) => b.watchedAt.compareTo(a.watchedAt),
          )
          .map((watched) => MovieModel(
                services: watched.movie.services
                    .map((e) => ServiceMovieModel(
                        service: e.service,
                        url: e.url,
                        title: e.title,
                        imageUrl: e.imageUrl))
                    .toList(),
              )));

      final merge = getIt<MergeService>();

      for (final entry in _repositories.entries) {
        final service = entry.key;
        final repository = entry.value;
        final authRepo = _authRepositories[service];
        final account = authRepo?.getAccount();

        if (account != null) {
          final movies = await repository.getMovies();
          await merge.addFromService(movies);
        }
      }

      _movies.addAll(getIt<MergeService>().getMovies);

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
