import 'package:equatable/equatable.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/watched_model.dart';

class MovieDetailsState extends Equatable {
  final MovieDetailsModel? movie;
  final WatchedMovieModel? watched;
  final String? errorMessage;
  final int selectedSeasonIndex;
  final List<String> directUrls;
  final bool isLoaded;

  List<SeasonModel> get seasons => movie?.seasons ?? [];

  SeasonModel? get currentSeason =>
      seasons.isNotEmpty && selectedSeasonIndex < seasons.length
          ? seasons[selectedSeasonIndex]
          : null;

  List<EpisodeModel> get episodes => currentSeason?.episodes ?? [];

  bool get isSeries => movie?.isSeries ?? false;

  const MovieDetailsState({
    this.movie,
    this.watched,
    this.errorMessage,
    this.selectedSeasonIndex = 0,
    this.directUrls = const [],
    this.isLoaded = false,
  });

  MovieDetailsState copyWith({
    MovieDetailsModel? movie,
    WatchedMovieModel? watched,
    String? errorMessage,
    int? selectedSeasonIndex,
    List<String>? directUrls,
    int? currentLoadingEpisodeIndex,
    bool? isLoaded,
  }) {
    return MovieDetailsState(
      movie: movie ?? this.movie,
      watched: watched ?? this.watched,
      errorMessage: errorMessage,
      selectedSeasonIndex: selectedSeasonIndex ?? this.selectedSeasonIndex,
      directUrls: directUrls ?? this.directUrls,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => [
        movie,
        watched,
        errorMessage,
        selectedSeasonIndex,
        directUrls,
        isLoaded,
      ];
}
