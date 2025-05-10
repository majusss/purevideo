import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:purevideo/presentation/widgets/error_view.dart';
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

// Enum dla kierunku przewijania
enum SeekDirection { forward, backward }

class _PlayerScreenState extends State<PlayerScreen> {
  // Media Kit controllers
  late final Player _player;
  late final VideoController _controller;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  late StreamSubscription<bool> _playingSubscription;
  late StreamSubscription<bool> _bufferingSubscription;
  // Stan odtwarzacza
  bool _isPlaying = false;
  bool _isOverlayVisible = true;
  bool _isBuffering = true;
  bool _isSeeking = false;
  SeekDirection? _seekDirection;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<VideoSource>? _videoSources;
  VideoSource? _selectedSource;
  bool _isLoading = true;
  String? _errorMessage;
  String _displayState = "Ładowanie...";

  // Timer do automatycznego ukrywania kontrolek
  Timer? _hideControlsTimer;

  final VideoSourceRepository _videoSourceRepository =
      getIt<VideoSourceRepository>();
  late MovieRepository _movieRepository;
  @override
  void initState() {
    super.initState();
    _movieRepository =
        getIt<Map<SupportedService, MovieRepository>>()[widget.movie.service]!;
    _initMediaKit();
    _loadVideoSources();
    _resetHideControlsTimer();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initMediaKit() {
    _player = Player();
    _controller = VideoController(_player);

    _positionSubscription = _player.stream.position.listen((position) {
      setState(() => _position = position);
    });
    _durationSubscription = _player.stream.duration.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _playingSubscription = _player.stream.playing.listen((playing) {
      setState(() => _isPlaying = playing);
    });

    _bufferingSubscription = _player.stream.buffering.listen((buffering) {
      setState(() => _isBuffering = buffering);
    });
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _playingSubscription.cancel();
    _bufferingSubscription.cancel();
    _hideControlsTimer?.cancel();
    _player.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadVideoSources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      MovieDetailsModel movieDetails;
      if (widget.seasonIndex != null && widget.episodeIndex != null) {
        final episode = widget
            .movie.seasons![widget.seasonIndex!].episodes[widget.episodeIndex!];

        final episodeWithHosts =
            await _movieRepository.getEpisodeHosts(episode);

        final tempModel = MovieDetailsModel(
          service: widget.movie.service,
          url: episode.url,
          title: episode.title,
          description: '',
          imageUrl: widget.movie.imageUrl,
          year: widget.movie.year,
          genres: widget.movie.genres,
          countries: widget.movie.countries,
          isSeries: true,
          videoUrls: episodeWithHosts.videoUrls,
        );

        movieDetails = await _videoSourceRepository.scrapeVideoUrls(tempModel);
      } else {
        movieDetails =
            await _videoSourceRepository.scrapeVideoUrls(widget.movie);
      }

      if (mounted) {
        setState(() {
          _videoSources = movieDetails.directUrls;
          _isLoading = false;
          if (_videoSources != null && _videoSources!.isNotEmpty) {
            _selectedSource = _videoSources!.first;
            _initializePlayer(_selectedSource!);
          } else {
            _errorMessage = 'Nie znaleziono źródeł odtwarzania';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Wystąpił błąd: $e';
        });
      }
    }
  }

  Future<void> _initializePlayer(VideoSource source) async {
    setState(() {
      _displayState = "Przygotowywanie odtwarzacza...";
      _isBuffering = true;
    });

    try {
      final Map<String, String> headers = source.headers ?? {};

      await _player.open(
        Media(source.url, httpHeaders: headers),
        play: true,
      );

      setState(() {
        _isBuffering = false;
        _isPlaying = true;
        _selectedSource = source;
        _displayState = "";
      });
    } catch (e) {
      setState(() {
        _isBuffering = false;
        _errorMessage = 'Błąd inicjalizacji odtwarzacza: $e';
      });
    }
  }

  void _togglePlayPause() {
    _player.playOrPause();

    if (_isOverlayVisible) {
      _resetHideControlsTimer();
    }
  }

  void _seekTo(double value) {
    final position =
        Duration(milliseconds: (value * _duration.inMilliseconds).round());
    _player.seek(position);
  }

  void _seekWithDirection(SeekDirection direction) {
    setState(() {
      _seekDirection = direction;
      _isSeeking = true;

      // Automatyczne ukrywanie kontrolek gdy użytkownik przewija
      _isOverlayVisible = false;

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _isSeeking = false;
          });
        }
      });
    });

    int newPositionSeconds = _position.inSeconds;

    if (direction == SeekDirection.backward) {
      newPositionSeconds = max(0, newPositionSeconds - 10);
    } else {
      newPositionSeconds = min(newPositionSeconds + 10, _duration.inSeconds);
    }

    _player.seek(Duration(seconds: newPositionSeconds));
  }

  void _changeVideoSource(VideoSource source) {
    setState(() {
      _selectedSource = source;
      _initializePlayer(source);
    });
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

  Widget _buildSeekingIndicator() {
    return Center(
      child: Transform(
        transform: Matrix4.translationValues(
            _seekDirection == SeekDirection.forward ? 100 : -100, 0, 0),
        child: AnimatedOpacity(
          opacity: _isSeeking ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            _seekDirection == SeekDirection.forward
                ? Icons.fast_forward
                : Icons.fast_rewind,
            size: 52,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isBuffering) return const SizedBox.shrink();

    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        if (_displayState.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _displayState,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ]
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    String title = widget.movie.title;
    if (widget.seasonIndex != null && widget.episodeIndex != null) {
      final episode = widget
          .movie.seasons![widget.seasonIndex!].episodes[widget.episodeIndex!];
      title = '${widget.movie.title} - ${episode.title}';
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                _displayState,
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

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: ErrorView(
          message: _errorMessage!,
          onRetry: _loadVideoSources,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Odtwarzacz wideo
          Video(
            controller: _controller,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),

          // Nakładka z kontrolkami
          SafeArea(child: _buildOverlay(title)),
        ],
      ),
    );
  } // Funkcja do resetowania timera automatycznego ukrywania

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _isOverlayVisible = false;
        });
      }
    });
  }

  Widget _buildOverlay(String title) {
    return MouseRegion(
      onHover: (_) {
        if (!_isOverlayVisible) {
          setState(() {
            _isOverlayVisible = true;
          });
        }
        _resetHideControlsTimer();
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isOverlayVisible = !_isOverlayVisible;
            if (_isOverlayVisible) {
              _resetHideControlsTimer();
            } else {
              _hideControlsTimer?.cancel();
            }
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            _buildSeekingIndicator(),
            _buildLoadingIndicator(),
            _buildDoubleTapControls(),
            IgnorePointer(
              ignoring: !_isOverlayVisible,
              child: AnimatedOpacity(
                opacity: _isOverlayVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    _buildTopBar(title),
                    _buildCenterPlayButton(),
                    _buildBrightnessControl(),
                    _buildIconsList(),
                    _buildBottomBar(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDoubleTapControls() {
    return Row(
      children: [
        SizedBox(
          height: double.infinity,
          width: MediaQuery.of(context).size.width * 0.5,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () => _seekWithDirection(SeekDirection.backward),
          ),
        ),
        SizedBox(
          height: double.infinity,
          width: MediaQuery.of(context).size.width * 0.5,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onDoubleTap: () => _seekWithDirection(SeekDirection.forward),
          ),
        ),
      ],
    );
  }

  Widget _buildBrightnessControl() {
    return Positioned(
      left: 18,
      top: -10,
      height: MediaQuery.of(context).size.height,
      child: FutureBuilder<double>(
        future: ScreenBrightness.instance.application,
        builder: (final context, final snapshot) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotatedBox(
                quarterTurns: -1,
                child: Slider(
                  value: snapshot.data ?? 0,
                  min: 0,
                  max: 1,
                  onChanged: (final value) {
                    setState(() {
                      ScreenBrightness.instance
                          .setApplicationScreenBrightness(value);
                    });
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

  Widget _buildTopBar(String title) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return Center(
      child: _isBuffering
          ? const SizedBox()
          : IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 72,
              color: Colors.white,
              onPressed: _togglePlayPause,
            ),
    );
  }

  Widget _buildIconsList() {
    return Align(
        alignment: Alignment.centerRight,
        child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 16),
                if (_videoSources != null && _videoSources!.length > 1)
                  PopupMenuButton<VideoSource>(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onSelected: _changeVideoSource,
                    itemBuilder: (context) => _videoSources!
                        .map(
                          (source) => PopupMenuItem<VideoSource>(
                            value: source,
                            child: Text(
                              '${source.quality} - ${source.lang}',
                              style: TextStyle(
                                fontWeight: source == _selectedSource
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            )));
  }

  Widget _buildBottomBar() {
    final double progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
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
              _formatDuration(_position),
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
                  onChanged: _seekTo,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: Colors.white,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _duration == Duration.zero ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
