import 'package:equatable/equatable.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

enum SeekDirection { forward, backward }

class PlayerState extends Equatable {
  final bool isLoading;
  final bool isPlaying;
  final bool isBuffering;
  final bool isOverlayVisible;
  final bool isSeeking;
  final SeekDirection? seekDirection;
  final Duration position;
  final Duration duration;
  final List<VideoSource>? videoSources;
  final VideoSource? selectedSource;
  final String? errorMessage;
  final String displayState;

  const PlayerState({
    this.isLoading = true,
    this.isPlaying = false,
    this.isBuffering = true,
    this.isOverlayVisible = true,
    this.isSeeking = false,
    this.seekDirection,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.videoSources,
    this.selectedSource,
    this.errorMessage,
    this.displayState = "Ładowanie...",
  });

  PlayerState copyWith({
    bool? isLoading,
    bool? isPlaying,
    bool? isBuffering,  
    bool? isOverlayVisible,
    bool? isSeeking,
    SeekDirection? seekDirection,
    Duration? position,
    Duration? duration,
    List<VideoSource>? videoSources,
    VideoSource? selectedSource,
    String? errorMessage,
    String? displayState,
  }) {
    return PlayerState(
      isLoading: isLoading ?? this.isLoading,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isSeeking: isSeeking ?? this.isSeeking,
      seekDirection: seekDirection ?? this.seekDirection,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      videoSources: videoSources ?? this.videoSources,
      selectedSource: selectedSource ?? this.selectedSource,
      errorMessage: errorMessage,
      displayState: displayState ?? this.displayState,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isPlaying,
        isBuffering,
        isOverlayVisible,
        isSeeking,
        seekDirection,
        position,
        duration,
        videoSources,
        selectedSource,
        errorMessage,
        displayState,
      ];
}
