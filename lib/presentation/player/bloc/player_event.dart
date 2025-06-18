import 'package:equatable/equatable.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/movie_model.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class InitializePlayer extends PlayerEvent {
  final MovieDetailsModel movie;
  final int? seasonIndex;
  final int? episodeIndex;

  const InitializePlayer({
    required this.movie,
    this.seasonIndex,
    this.episodeIndex,
  });

  @override
  List<Object?> get props => [movie, seasonIndex, episodeIndex];
}

class LoadVideoSources extends PlayerEvent {
  const LoadVideoSources();
}

class InitializeVideoPlayer extends PlayerEvent {
  final VideoSource source;

  const InitializeVideoPlayer({required this.source});

  @override
  List<Object> get props => [source];
}

class PlayPause extends PlayerEvent {
  const PlayPause();
}

class SeekTo extends PlayerEvent {
  final double position;

  const SeekTo({required this.position});

  @override
  List<Object> get props => [position];
}

class SeekWithDirection extends PlayerEvent {
  final bool isForward;

  const SeekWithDirection({required this.isForward});

  @override
  List<Object> get props => [isForward];
}

class ChangeVideoSource extends PlayerEvent {
  final VideoSource source;

  const ChangeVideoSource({required this.source});

  @override
  List<Object> get props => [source];
}

class ToggleControlsVisibility extends PlayerEvent {
  const ToggleControlsVisibility();
}

class ShowControls extends PlayerEvent {
  const ShowControls();
}

class HideControls extends PlayerEvent {
  const HideControls();
}

class HideSeekingIndicator extends PlayerEvent {
  const HideSeekingIndicator();
}

class UpdatePosition extends PlayerEvent {
  final Duration position;

  const UpdatePosition({required this.position});

  @override
  List<Object> get props => [position];
}

class UpdateDuration extends PlayerEvent {
  final Duration duration;

  const UpdateDuration({required this.duration});

  @override
  List<Object> get props => [duration];
}

class UpdatePlayingState extends PlayerEvent {
  final bool isPlaying;

  const UpdatePlayingState({required this.isPlaying});

  @override
  List<Object> get props => [isPlaying];
}

class UpdateBufferingState extends PlayerEvent {
  final bool isBuffering;

  const UpdateBufferingState({required this.isBuffering});

  @override
  List<Object> get props => [isBuffering];
}

class PlayerError extends PlayerEvent {
  final String message;

  const PlayerError({required this.message});

  @override
  List<Object> get props => [message];
}

class DisposePlayer extends PlayerEvent {
  const DisposePlayer();
}
