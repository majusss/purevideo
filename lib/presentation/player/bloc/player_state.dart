import 'package:equatable/equatable.dart';
import 'package:flutter_cast_framework/cast.dart';
import 'package:pip/pip.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

enum SeekDirection { forward, backward }

class PlayerState extends Equatable {
  final bool isLoading;
  final bool isPlaying;
  final bool isBuffering;
  final bool isOverlayVisible;
  final bool isSeeking;
  final bool isImersive;
  final SeekDirection? seekDirection;
  final Duration position;
  final Duration duration;
  final List<VideoSource>? videoSources;
  final VideoSource? selectedSource;
  final String? errorMessage;
  final String displayState;

  final FlutterCastFramework castFramework;
  final Pip pipFramework;

  const PlayerState({
    this.isLoading = true,
    this.isPlaying = false,
    this.isBuffering = true,
    this.isOverlayVisible = true,
    this.isSeeking = false,
    this.isImersive = false,
    this.seekDirection,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.videoSources,
    this.selectedSource,
    this.errorMessage,
    this.displayState = 'Ładowanie...',
    required this.castFramework,
    required this.pipFramework,
  });

  PlayerState copyWith({
    bool? isLoading,
    bool? isPlaying,
    bool? isBuffering,
    bool? isOverlayVisible,
    bool? isSeeking,
    bool? isImersive,
    SeekDirection? seekDirection,
    Duration? position,
    Duration? duration,
    List<VideoSource>? videoSources,
    VideoSource? selectedSource,
    String? errorMessage,
    String? displayState,
    FlutterCastFramework? castFramework,
    Pip? pipFramework,
  }) {
    return PlayerState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isSeeking: isSeeking ?? this.isSeeking,
      isImersive: isImersive ?? this.isImersive,
      seekDirection: seekDirection ?? this.seekDirection,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      videoSources: videoSources ?? this.videoSources,
      selectedSource: selectedSource ?? this.selectedSource,
      errorMessage: errorMessage,
      displayState: displayState ?? this.displayState,
      castFramework: castFramework ?? this.castFramework,
      pipFramework: pipFramework ?? this.pipFramework,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isPlaying,
        isBuffering,
        isOverlayVisible,
        isSeeking,
        isImersive,
        seekDirection,
        position,
        duration,
        videoSources,
        selectedSource,
        errorMessage,
        displayState,
        castFramework,
      ];
}
