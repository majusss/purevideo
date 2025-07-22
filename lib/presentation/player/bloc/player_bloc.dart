import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/player/bloc/player_event.dart';
import 'package:purevideo/presentation/player/bloc/player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final WatchedService watchedService = getIt();

  late final Player _player;
  late final VideoController _controller;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<bool> _playingSubscription;
  late StreamSubscription<bool> _bufferingSubscription;

  Timer? _hideControlsTimer;
  Timer? _seekingTimer;

  final VideoSourceRepository _videoSourceRepository =
      getIt<VideoSourceRepository>();
  late MovieRepository _movieRepository;

  MovieDetailsModel? _movie;
  int? _seasonIndex;
  int? _episodeIndex;

  PlayerBloc() : super(const PlayerState()) {
    on<InitializePlayer>(_onInitializePlayer);
    on<LoadVideoSources>(_onLoadVideoSources);
    on<InitializeVideoPlayer>(_onInitializeVideoPlayer);
    on<PlayPause>(_onPlayPause);
    on<SeekTo>(_onSeekTo);
    on<SeekWithDirection>(_onSeekWithDirection);
    on<ChangeVideoSource>(_onChangeVideoSource);
    on<ToggleControlsVisibility>(_onToggleControlsVisibility);
    on<ShowControls>(_onShowControls);
    on<HideControls>(_onHideControls);
    on<HideSeekingIndicator>(_onHideSeekingIndicator);
    on<UpdatePosition>(_onUpdatePosition);
    on<UpdateDuration>(_onUpdateDuration);
    on<UpdatePlayingState>(_onUpdatePlayingState);
    on<UpdateBufferingState>(_onUpdateBufferingState);
    on<PlayerError>(_onPlayerError);
    on<DisposePlayer>(_onDisposePlayer);
    on<ToggleImmersiveMode>(_onToggleImmersiveMode);
  }

  @override
  Future<void> close() {
    _disposeMediaKit();
    _hideControlsTimer?.cancel();
    _seekingTimer?.cancel();
    return super.close();
  }

  void _initMediaKit() {
    _player = Player();
    _controller = VideoController(_player);

    _positionSubscription = _player.stream.position.listen((position) {
      add(UpdatePosition(position: position));
    });

    _durationSubscription = _player.stream.duration.listen((duration) {
      add(UpdateDuration(duration: duration));
    });

    _playingSubscription = _player.stream.playing.listen((playing) {
      add(UpdatePlayingState(isPlaying: playing));
    });

    _bufferingSubscription = _player.stream.buffering.listen((buffering) {
      add(UpdateBufferingState(isBuffering: buffering));
    });
  }

  void _disposeMediaKit() {
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    _player.dispose();
  }

  Future<void> _onInitializePlayer(
    InitializePlayer event,
    Emitter<PlayerState> emit,
  ) async {
    _movie = event.movie;
    _seasonIndex = event.seasonIndex;
    _episodeIndex = event.episodeIndex;

    _movieRepository =
        getIt<Map<SupportedService, MovieRepository>>()[event.movie.service]!;

    _initMediaKit();

    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
    ));

    add(const LoadVideoSources());
  }

  Future<void> _onLoadVideoSources(
    LoadVideoSources event,
    Emitter<PlayerState> emit,
  ) async {
    if (_movie == null) return;

    emit(state.copyWith(
      isLoading: true,
      errorMessage: null,
    ));

    try {
      MovieDetailsModel movieDetails;

      if (_seasonIndex != null && _episodeIndex != null) {
        final episode =
            _movie!.seasons![_seasonIndex!].episodes[_episodeIndex!];
        final episodeWithHosts =
            await _movieRepository.getEpisodeHosts(episode);

        final tempModel = MovieDetailsModel(
          service: _movie!.service,
          url: episode.url,
          title: episode.title,
          description: '',
          imageUrl: _movie!.imageUrl,
          year: _movie!.year,
          genres: _movie!.genres,
          countries: _movie!.countries,
          isSeries: true,
          videoUrls: episodeWithHosts.videoUrls,
        );

        movieDetails = await _videoSourceRepository.scrapeVideoUrls(tempModel);
      } else {
        movieDetails = await _videoSourceRepository.scrapeVideoUrls(_movie!);
      }

      if (movieDetails.directUrls != null &&
          movieDetails.directUrls!.isNotEmpty) {
        // TODO: lepsze wybieranie i sprawdzanie źródeł
        final selectedSource = movieDetails.directUrls!.first;

        emit(state.copyWith(
          videoSources: movieDetails.directUrls,
          selectedSource: selectedSource,
          isLoading: false,
        ));

        add(InitializeVideoPlayer(source: selectedSource));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Nie znaleziono źródeł odtwarzania',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Wystąpił błąd: $e',
      ));
    }
  }

  Future<void> _onInitializeVideoPlayer(
    InitializeVideoPlayer event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(
      displayState: 'Przygotowywanie odtwarzacza...',
      isBuffering: true,
    ));

    try {
      final Map<String, String> headers = event.source.headers ?? {};

      int? watchedPosition;

      if (_seasonIndex != null && _episodeIndex != null) {
        final episode =
            _movie!.seasons![_seasonIndex!].episodes[_episodeIndex!];
        final watchedEpisode = watchedService.getByEpisode(_movie!, episode);
        watchedPosition = watchedEpisode?.watchedTime;
      } else {
        final watchedMovie = watchedService.getByMovie(_movie!);
        watchedPosition = watchedMovie?.watchedTime;
      }

      await _player.open(
        Media(event.source.url,
            httpHeaders: headers,
            start: Duration(seconds: watchedPosition ?? 0)),
        play: true,
      );

      emit(state.copyWith(
        isBuffering: false,
        isPlaying: true,
        selectedSource: event.source,
        displayState: '',
      ));
    } catch (e) {
      emit(state.copyWith(
        isBuffering: false,
        errorMessage: 'Błąd inicjalizacji odtwarzacza: $e',
      ));
    }
  }

  Future<void> _onPlayPause(
    PlayPause event,
    Emitter<PlayerState> emit,
  ) async {
    _player.playOrPause();

    if (state.isOverlayVisible) {
      _resetHideControlsTimer();
    }
  }

  Future<void> _onSeekTo(
    SeekTo event,
    Emitter<PlayerState> emit,
  ) async {
    final position = Duration(
      milliseconds: (event.position * state.duration.inMilliseconds).round(),
    );
    _player.seek(position);
  }

  Future<void> _onSeekWithDirection(
    SeekWithDirection event,
    Emitter<PlayerState> emit,
  ) async {
    final direction =
        event.isForward ? SeekDirection.forward : SeekDirection.backward;

    emit(state.copyWith(
      seekDirection: direction,
      isSeeking: true,
      isOverlayVisible: false,
    ));

    _seekingTimer?.cancel();
    _seekingTimer = Timer(const Duration(milliseconds: 400), () {
      add(const HideSeekingIndicator());
    });

    int newPositionSeconds = state.position.inSeconds;

    if (direction == SeekDirection.backward) {
      newPositionSeconds = max(0, newPositionSeconds - 10);
    } else {
      newPositionSeconds =
          min(newPositionSeconds + 10, state.duration.inSeconds);
    }

    _player.seek(Duration(seconds: newPositionSeconds));
  }

  Future<void> _onChangeVideoSource(
    ChangeVideoSource event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(selectedSource: event.source));
    add(InitializeVideoPlayer(source: event.source));
  }

  Future<void> _onToggleControlsVisibility(
    ToggleControlsVisibility event,
    Emitter<PlayerState> emit,
  ) async {
    if (state.isOverlayVisible) {
      emit(state.copyWith(isOverlayVisible: false));
      _hideControlsTimer?.cancel();
    } else {
      emit(state.copyWith(isOverlayVisible: true));
      _resetHideControlsTimer();
    }
  }

  Future<void> _onShowControls(
    ShowControls event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isOverlayVisible: true));
    _resetHideControlsTimer();
  }

  Future<void> _onHideControls(
    HideControls event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isOverlayVisible: false));
  }

  Future<void> _onHideSeekingIndicator(
    HideSeekingIndicator event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isSeeking: false));
  }

  Future<void> _onUpdatePosition(
    UpdatePosition event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(position: event.position));
  }

  Future<void> _onUpdateDuration(
    UpdateDuration event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(duration: event.duration));
  }

  Future<void> _onUpdatePlayingState(
    UpdatePlayingState event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isPlaying: event.isPlaying));
  }

  Future<void> _onUpdateBufferingState(
    UpdateBufferingState event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isBuffering: event.isBuffering));
  }

  Future<void> _onPlayerError(
    PlayerError event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(
      isBuffering: false,
      errorMessage: event.message,
    ));
  }

  Future<void> _onDisposePlayer(
    DisposePlayer event,
    Emitter<PlayerState> emit,
  ) async {
    if (_movie != null) {
      if (_movie!.isSeries) {
        watchedService.watchEpisode(
            _movie!,
            _movie!.seasons![_seasonIndex!],
            _movie!.seasons![_seasonIndex!].episodes[_episodeIndex!],
            state.position.inSeconds);
      } else {
        watchedService.watchMovie(_movie!, state.position.inSeconds);
      }
    }
    _disposeMediaKit();
    _hideControlsTimer?.cancel();
    _seekingTimer?.cancel();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed && state.isPlaying) {
        add(const HideControls());
      }
    });
  }

  Future<void> _onToggleImmersiveMode(
    ToggleImmersiveMode event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isImersive: !state.isImersive));
  }

  VideoController get controller => _controller;
}
