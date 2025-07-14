import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_event.dart';
import 'package:purevideo/presentation/movie_details/bloc/movie_details_state.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  final Map<SupportedService, MovieRepository> _movieRepositories = getIt();
  final VideoSourceRepository _videoSourceRepository = getIt();
  final WatchedService _watchedService = getIt();

  MovieDetailsBloc() : super(const MovieDetailsState()) {
    on<LoadMovieDetails>(_onLoadMovieDetails);
    on<ScrapeVideoUrls>(_onScrapeVideoUrls);
    on<SelectSeason>(_onSelectSeason);
    on<UpdateWatchedStatus>(_onUpdateWatchedStatus);
  }

  @override
  Future<void> close() {
    _stopScraping();
    return super.close();
  }

  void _stopScraping() {}

  Future<void> _onLoadMovieDetails(
      LoadMovieDetails event, Emitter<MovieDetailsState> emit) async {
    try {
      final movieRepository = _movieRepositories[event.service];
      if (movieRepository == null) {
        throw Exception('Brak obsługi serwisu ${event.service}');
      }

      final movie = await movieRepository.getMovieDetails(event.url);

      FirebaseAnalytics.instance
          .logSelectContent(contentType: 'video', itemId: movie.url);

      final watched = _watchedService.getByMovie(movie);

      emit(state.copyWith(watched: watched));

      if (movie.isSeries) {
        final lastWatchedSeason = watched?.lastWatchedEpisode?.episode.season;
        final selectedSeasonIndex = lastWatchedSeason != null
            ? movie.seasons
                ?.indexWhere((s) => s.number == lastWatchedSeason.number)
            : 0;
        emit(state.copyWith(
          movie: movie,
          selectedSeasonIndex: selectedSeasonIndex,
        ));
      } else {
        emit(state.copyWith(movie: movie));
      }

      if (!movie.isSeries) {
        add(ScrapeVideoUrls(movie: movie, service: event.service));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Nie udało się załadować szczegółów filmu: $e',
      ));
    }
  }

  Future<void> _onScrapeVideoUrls(
      ScrapeVideoUrls event, Emitter<MovieDetailsState> emit) async {
    try {
      if (!event.movie.isSeries) {
        final updatedMovie =
            await _videoSourceRepository.scrapeVideoUrls(event.movie);
        emit(state.copyWith(movie: updatedMovie));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectSeason(
      SelectSeason event, Emitter<MovieDetailsState> emit) async {
    emit(state.copyWith(
      selectedSeasonIndex: event.seasonIndex,
      isLoadingEpisode: false,
    ));
  }

  Future<void> _onUpdateWatchedStatus(
      UpdateWatchedStatus event, Emitter<MovieDetailsState> emit) async {
    emit(state.copyWith(watched: event.watched));
  }
}
