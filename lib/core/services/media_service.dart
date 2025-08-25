import 'package:audio_service/audio_service.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:purevideo/core/utils/global_context.dart';
// import 'package:purevideo/di/injection_container.dart';
// import 'package:purevideo/presentation/player/bloc/player_bloc.dart';
// import 'package:purevideo/presentation/player/bloc/player_event.dart';

class MediaService {
  late final MyAudioHandler _audioHandler;

  MyAudioHandler get audioHandler => _audioHandler;

  Future<void> init() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'io.github.majusss.purevideo.media',
        androidNotificationChannelName: 'PureVideo Media',
        androidNotificationOngoing: true,
        fastForwardInterval: Duration(seconds: 10),
      ),
    );
  }
}

class MyAudioHandler extends BaseAudioHandler {
  MyAudioHandler();

  void add(MediaItem media) {
    mediaItem.add(media);
  }

  // @override
  // Future<void> play() {
  //   final playerBloc = getIt<GlobalContext>()
  //       .globalNavigatorKey
  //       .currentContext!
  //       .read<PlayerBloc>();

  //   debugPrint("Playing audio from MediaService");

  //   playerBloc.controller.player.play();
  //   return super.play();
  // }

  // @override
  // Future<void> pause() {
  //   final playerBloc = getIt<GlobalContext>()
  //       .globalNavigatorKey
  //       .currentContext!
  //       .read<PlayerBloc>();
  //   playerBloc.controller.player.pause();
  //   return super.pause();
  // }

  // @override
  // Future<void> seek(Duration position) {
  //   final playerBloc = getIt<GlobalContext>()
  //       .globalNavigatorKey
  //       .currentContext!
  //       .read<PlayerBloc>();
  //   playerBloc.add(SeekTo(position: position.inSeconds.toDouble()));
  //   return super.seek(position);
  // }

  // @override
  // Future<void> seekForward(bool begin) {
  //   final playerBloc = getIt<GlobalContext>()
  //       .globalNavigatorKey
  //       .currentContext!
  //       .read<PlayerBloc>();
  //   playerBloc.add(const SeekWithDirection(
  //     isForward: true,
  //   ));
  //   return super.seekForward(begin);
  // }

  // @override
  // Future<void> seekBackward(bool begin) {
  //   final playerBloc = getIt<GlobalContext>()
  //       .globalNavigatorKey
  //       .currentContext!
  //       .read<PlayerBloc>();
  //   playerBloc.add(const SeekWithDirection(
  //     isForward: false,
  //   ));
  //   return super.seekBackward(begin);
  // }
}
