import 'dart:async';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:purevideo/core/services/media_service.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/player/bloc/player_event.dart';
import 'package:purevideo/presentation/player/bloc/player_state.dart';
import 'package:flutter_cast_framework/cast.dart' hide PlayerState;
import 'package:pip/pip.dart';

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
  final Map<SupportedService, MovieRepository> _movieRepositories =
      getIt<Map<SupportedService, MovieRepository>>();
  final MediaService _mediaService = getIt<MediaService>();

  late final AudioSession _audioSession;

  MovieDetailsModel? _movie;
  int? _seasonIndex;
  int? _episodeIndex;

  PlayerBloc()
      : super(PlayerState(
            castFramework: getIt<FlutterCastFramework>(),
            pipFramework: Pip())) {
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
    on<CastVideo>(_onCastVideo);
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

    _initMediaKit();

    const options = PipOptions(
      autoEnterEnabled: true,
      aspectRatioX: 16,
      aspectRatioY: 9,
      sourceRectHintLeft: 0,
      sourceRectHintTop: 0,
      sourceRectHintRight: 1080,
      sourceRectHintBottom: 720,
      sourceContentView: 0,
      contentView: 0,
      preferredContentWidth: 480,
      preferredContentHeight: 270,
      controlStyle: 2,
    );

    await state.pipFramework.setup(options);

    await state.pipFramework
        .registerStateChangedObserver(PipStateChangedObserver(
      onPipStateChanged: (pipState, error) {
        switch (pipState) {
          case PipState.pipStateStarted:
            emit(state.copyWith(isOverlayVisible: false));
            _hideControlsTimer?.cancel();
            debugPrint('PiP started');
            break;
          case PipState.pipStateFailed:
            debugPrint('PiP failed: $error');
            break;
          default:
            break;
        }
      },
    ));

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
        final episodes = <EpisodeModel>[];
        for (final service in _movie!.services) {
          final movieRepository = _movieRepositories[service.service];
          if (movieRepository == null) {
            continue;
          }

          if (_seasonIndex! >= service.seasons!.length) continue;
          final season = service.seasons?[_seasonIndex!];
          if (season == null) continue;
          if (_episodeIndex! >= season.episodes.length) continue;
          final episode = season.episodes[_episodeIndex!];
          final episodeWithHosts =
              await movieRepository.getEpisodeHosts(episode);
          episodes.add(episodeWithHosts);
        }

        // this is dummy af but this system works better for movies than series
        final tempModel = MovieDetailsModel(
          services: [
            ServiceMovieDetailsModel(
                service: SupportedService.values.first,
                url: '',
                title: '',
                description: '',
                imageUrl: '',
                isSeries: true,
                videoUrls: episodes.expand((e) => e.videoUrls!).toList()),
          ],
        );

        movieDetails = await _videoSourceRepository.scrapeVideoUrls(tempModel);
      } else {
        movieDetails = _movie!;
        // await _videoSourceRepository.scrapeVideoUrls(_movie!); we already done this in movie details bloc
      }

      if (movieDetails.directUrls != null &&
          movieDetails.directUrls!.isNotEmpty) {
        // TODO: better source selection logic
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

    if (state.castFramework.castContext.state.value == CastState.connected) {
      add(const CastVideo());
      final sessionManager = state.castFramework.castContext.sessionManager;
      sessionManager.remoteMediaClient.onProgressUpdated =
          (final progressMs, final durationMs) {
        add(UpdatePosition(
          position: Duration(milliseconds: progressMs),
        ));
      };
    }

    try {
      state.castFramework.castContext.state.addListener(
        () async {
          switch (state.castFramework.castContext.state.value) {
            case CastState.connected:
              add(const CastVideo());
              break;
            default:
              break;
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing google cast: $e');
    }

    try {
      _audioSession = await AudioSession.instance;
      await _audioSession.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Error initializing audio session: $e');
    }

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
        play: await _audioSession.setActive(true),
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
    _audioSession.setActive(!state.isPlaying);
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
    _updateNotification();
  }

  Future<void> _onUpdateDuration(
    UpdateDuration event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(duration: event.duration));
    if (event.duration.inSeconds == 0) {
      return;
    }
    _mediaService.audioHandler.add(MediaItem(
      id: _movie!.title,
      title: _movie!.title,
      artUri: Uri.parse(_movie!.imageUrl),
      duration: state.duration,
    ));
    _updateNotification();
  }

  Future<void> _onUpdatePlayingState(
    UpdatePlayingState event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isPlaying: event.isPlaying));
    _updateNotification();
  }

  Future<void> _onUpdateBufferingState(
    UpdateBufferingState event,
    Emitter<PlayerState> emit,
  ) async {
    emit(state.copyWith(isBuffering: event.isBuffering));
    _updateNotification();
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
    _audioSession.setActive(false);
    _mediaService.audioHandler.playbackState.add(PlaybackState(
      playing: false,
    ));
    state.castFramework.castContext.sessionManager.remoteMediaClient.stop();
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
    state.pipFramework.dispose();
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

  Future<void> _onCastVideo(CastVideo event, Emitter<PlayerState> emit) async {
    if (state.castFramework.castContext.state.value == CastState.connected) {
      if (state.selectedSource == null) {
        emit(state.copyWith(
          errorMessage: 'Nie wybrano źródła wideo do przesłania.',
        ));
        return;
      }
      _player.pause();
      state.castFramework.castContext.sessionManager.remoteMediaClient.load(
          MediaLoadRequestData(
              currentTime: state.position.inMilliseconds,
              shouldAutoplay: true,
              mediaInfo: MediaInfo(
                  streamDuration: state.duration.inMilliseconds,
                  streamType: StreamType.buffered,
                  contentType: 'videos/mp4',
                  contentId: state.selectedSource!.url,
                  mediaMetadata: MediaMetadata(
                      mediaType: MediaType.movie,
                      strings: _movie!.isSeries
                          ? {
                              MediaMetadataKey.title.name: _movie!
                                  .seasons![_seasonIndex!]
                                  .episodes[_episodeIndex!]
                                  .title,
                              MediaMetadataKey.subtitle.name: _movie!.title,
                            }
                          : {MediaMetadataKey.title.name: _movie!.title},
                      webImages: [
                        WebImage(url: _movie!.imageUrl),
                        WebImage(url: _movie!.imageUrl)
                      ]))));
    }
  }

  void _updateNotification() {
    _mediaService.audioHandler.playbackState.add(PlaybackState(
      playing: state.isPlaying,
      updatePosition: state.position,
      processingState: state.isBuffering
          ? AudioProcessingState.buffering
          : AudioProcessingState.ready,
      bufferedPosition: state.duration,
    ));
  }
}
