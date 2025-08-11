import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/search_repository.dart';
import 'package:purevideo/presentation/search/bloc/search_event.dart';
import 'package:purevideo/presentation/search/bloc/search_state.dart';
import 'package:purevideo/di/injection_container.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final Map<SupportedService, AuthRepository> _authRepositories = getIt();
  final Map<SupportedService, SearchRepository> _searchRepositories = getIt();

  SearchBloc() : super(const SearchInitial()) {
    on<SearchRequested>(_onSearchRequested);
    on<SearchCleared>(_onSearchCleared);
  }

  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());

    try {
      bool hasLoggedInUser = false;
      for (final entry in _authRepositories.entries) {
        final account = entry.value.getAccount();
        if (account != null) {
          hasLoggedInUser = true;
          break;
        }
      }

      if (!hasLoggedInUser) {
        emit(const SearchError('Zaloguj się aby zobaczyć filmy'));
        return;
      }

      final results = <MovieModel>[];

      for (final entry in _searchRepositories.entries) {
        try {
          final account = _authRepositories[entry.key]?.getAccount();
          if (account == null) {
            continue;
          }
          final repositoryResults = await entry.value.searchMovies(event.query);
          results.addAll(repositoryResults);
        } catch (e) {
          continue;
        }
      }

      emit(SearchLoaded(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchInitial());
  }
}
