import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/presentation/global/widgets/error_view.dart';
import 'package:purevideo/presentation/player/bloc/player_bloc.dart';
import 'package:purevideo/presentation/player/bloc/player_event.dart';
import 'package:purevideo/presentation/player/bloc/player_state.dart';
import 'package:screen_brightness/screen_brightness.dart';

class PlayerScreen extends StatefulWidget {
  final MovieDetailsModel movie;
  final int? seasonIndex;
  final int? episodeIndex;

  const PlayerScreen({
    Key? key,
    required this.movie,
    this.seasonIndex,
    this.episodeIndex,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PlayerBloc _playerBloc;

  @override
  void initState() {
    _playerBloc = PlayerBloc();
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void deactivate() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.deactivate();
  }

  @override
  void dispose() {
    _playerBloc.add(const DisposePlayer());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _playerBloc
        ..add(InitializePlayer(
          movie: widget.movie,
          seasonIndex: widget.seasonIndex,
          episodeIndex: widget.episodeIndex,
        )),
      child: const PlayerView(),
    );
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerBloc, PlayerState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingView(context, state);
        }

        if (state.errorMessage != null) {
          return _buildErrorView(context, state);
        }

        return _buildPlayerView(context, state);
      },
    );
  }

  Widget _buildLoadingView(BuildContext context, PlayerState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              state.displayState,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Anuluj'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, PlayerState state) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ErrorView(
        message: state.errorMessage!,
        onRetry: () {
          context.read<PlayerBloc>().add(const LoadVideoSources());
        },
      ),
    );
  }

  Widget _buildPlayerView(BuildContext context, PlayerState state) {
    final bloc = context.read<PlayerBloc>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Video(
            controller: bloc.controller,
            controls: NoVideoControls,
            fit: state.isImersive ? BoxFit.cover : BoxFit.contain,
          ),
          SafeArea(child: _buildOverlay(context, state)),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, PlayerState state) {
    final bloc = context.read<PlayerBloc>();

    return MouseRegion(
      onHover: (_) {
        if (!state.isOverlayVisible) {
          bloc.add(const ShowControls());
        }
      },
      child: GestureDetector(
        onTap: () {
          bloc.add(const ToggleControlsVisibility());
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            _buildSeekingIndicator(state),
            _buildLoadingIndicator(state),
            _buildDoubleTapControls(bloc),
            IgnorePointer(
              ignoring: !state.isOverlayVisible,
              child: AnimatedOpacity(
                opacity: state.isOverlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    _buildTopBar(context),
                    _buildCenterPlayButton(state, bloc),
                    _buildBrightnessControl(context),
                    _buildIconsList(state, bloc),
                    _buildBottomBar(context, state, bloc),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSeekingIndicator(PlayerState state) {
    return Center(
      child: Transform(
        transform: Matrix4.translationValues(
            state.seekDirection == SeekDirection.forward ? 100 : -100, 0, 0),
        child: AnimatedOpacity(
          opacity: state.isSeeking ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            state.seekDirection == SeekDirection.forward
                ? Icons.fast_forward
                : Icons.fast_rewind,
            size: 52,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(PlayerState state) {
    if (!state.isBuffering) return const SizedBox.shrink();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          if (state.displayState.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              state.displayState,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDoubleTapControls(PlayerBloc bloc) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () =>
                  bloc.add(const SeekWithDirection(isForward: false)),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () =>
                  bloc.add(const SeekWithDirection(isForward: true)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextEpisodeButton(BuildContext context) {
    final playerScreen = context.findAncestorWidgetOfExactType<PlayerScreen>();
    final movie = playerScreen!.movie;
    final seasonIndex = playerScreen.seasonIndex;
    final episodeIndex = playerScreen.episodeIndex;

    late Map<String, dynamic> queryParameters;

    if (seasonIndex == null || episodeIndex == null) {
      return const SizedBox.shrink();
    }
    final nextEpisodeIndex = episodeIndex + 1;
    if (nextEpisodeIndex < movie.seasons![seasonIndex].episodes.length) {
      queryParameters = {
        'season': seasonIndex.toString(),
        'episode': nextEpisodeIndex.toString(),
      };
    } else if (seasonIndex + 1 < movie.seasons!.length) {
      queryParameters = {
        'season': (seasonIndex + 1).toString(),
        'episode': '0',
      };
    } else {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: () async {
        // disable screen rotation in deactivate method
        context.pushReplacementNamed('player',
            extra: movie, queryParameters: queryParameters);
      },
      icon: const Text('Następny odcinek'),
      label: const Icon(Icons.skip_next),
    );
  }

  Widget _buildBrightnessControl(BuildContext context) {
    return Positioned(
      left: 18,
      top: -10,
      height: MediaQuery.of(context).size.height,
      child: FutureBuilder<double>(
        future: ScreenBrightness.instance.application,
        builder: (context, snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: -1,
                child: Slider(
                  value: snapshot.data ?? 0,
                  min: 0,
                  max: 1,
                  onChanged: (value) {
                    ScreenBrightness.instance
                        .setApplicationScreenBrightness(value);
                  },
                ),
              ),
              Icon(_getBrightnessIcon(snapshot.data ?? 0), color: Colors.white),
            ],
          );
        },
      ),
    );
  }

  IconData _getBrightnessIcon(final double brightness) {
    if (brightness >= 0.875) return Icons.brightness_7;
    if (brightness >= 0.75) return Icons.brightness_6;
    if (brightness >= 0.625) return Icons.brightness_5;
    if (brightness >= 0.5) return Icons.brightness_4;
    if (brightness >= 0.375) return Icons.brightness_1;
    if (brightness >= 0.25) return Icons.brightness_2;
    if (brightness >= 0.125) return Icons.brightness_3;
    return Icons.brightness_3;
  }

  Widget _buildTopBar(BuildContext context) {
    final playerScreen = context.findAncestorWidgetOfExactType<PlayerScreen>();
    final movie = playerScreen!.movie;

    String title = movie.title;
    if (movie.isSeries == true &&
        playerScreen.seasonIndex != null &&
        playerScreen.episodeIndex != null) {
      final seasonIndex = playerScreen.seasonIndex!;
      final episodeIndex = playerScreen.episodeIndex!;
      final episode = movie.seasons![seasonIndex].episodes[episodeIndex];
      title = '${movie.title} - ${episode.title}';
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        height: 48,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (movie.isSeries)
              Align(
                  alignment: Alignment.centerRight,
                  child: _buildNextEpisodeButton(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton(PlayerState state, PlayerBloc bloc) {
    return Center(
      child: state.isBuffering
          ? const SizedBox()
          : IconButton(
              icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 72,
              color: Colors.white,
              onPressed: () => bloc.add(const PlayPause()),
            ),
    );
  }

  Widget _buildIconsList(PlayerState state, PlayerBloc bloc) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            if (state.videoSources != null && state.videoSources!.length > 1)
              PopupMenuButton<VideoSource>(
                icon: const Icon(Icons.settings, color: Colors.white),
                onSelected: (source) =>
                    bloc.add(ChangeVideoSource(source: source)),
                itemBuilder: (context) => state.videoSources!
                    .map(
                      (source) => PopupMenuItem<VideoSource>(
                        value: source,
                        child: Text(
                          '${source.host}: ${source.quality} - ${source.lang}',
                          style: TextStyle(
                            fontWeight: source == state.selectedSource
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            IconButton(
                icon: Icon(
                    state.isImersive ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: Colors.white),
                onPressed: () {
                  bloc.add(const ToggleImmersiveMode());
                })
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, PlayerState state, PlayerBloc bloc) {
    final double progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 56),
        width: double.infinity,
        height: 48,
        child: Row(
          children: [
            Text(
              _formatDuration(state.position),
              style: const TextStyle(color: Colors.white),
            ),
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 2,
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) => bloc.add(SeekTo(position: value)),
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: state.duration == Duration.zero ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _formatDuration(state.duration),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    } else {
      return '$twoDigitMinutes:$twoDigitSeconds';
    }
  }
}
