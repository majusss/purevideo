import 'package:get_it/get_it.dart';
import 'package:purevideo/core/services/settings_service.dart';
import 'package:purevideo/core/services/watched_service.dart';
import 'package:purevideo/core/services/captcha_service.dart';
import 'package:purevideo/core/services/webview_service.dart';
import 'package:purevideo/core/utils/global_context.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';
import 'package:purevideo/data/repositories/ekino/ekino_movie_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_search_repository.dart';
import 'package:purevideo/data/repositories/ekino/ekino_search_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_auth_repository.dart';
import 'package:purevideo/data/repositories/ekino/ekino_auth_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_movie_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_search_repository.dart';
import 'package:purevideo/data/repositories/search_repository.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_movie_repository.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/di/video_hosts_container.dart';

final getIt = GetIt.instance;

void setupInjection() {
  final videoHostRegistry = VideoHostRegistry();
  getIt.registerSingleton<VideoHostRegistry>(videoHostRegistry);
  VideoHostsContainer.registerVideoScrapers(videoHostRegistry);

  // getIt.registerFactory<ReCaptchaBloc>(() => ReCaptchaBloc());
  getIt.registerFactory<CaptchaService>(() => CaptchaService());
  getIt.registerFactory<WebViewService>(() => WebViewService());

  getIt.registerSingleton<VideoSourceRepository>(VideoSourceRepository());

  getIt.registerSingleton<SettingsService>(SettingsService());
  getIt.registerSingleton<WatchedService>(WatchedService());

  getIt.registerSingleton<Map<SupportedService, AuthRepository>>({
    SupportedService.filman: FilmanAuthRepository(),
    SupportedService.obejrzyjto: ObejrzyjtoAuthRepository(),
    SupportedService.ekino: EkinoAuthRepository(),
  });
  getIt.registerSingleton<Map<SupportedService, MovieRepository>>({
    SupportedService.filman: FilmanMovieRepository(),
    SupportedService.obejrzyjto: ObejrzyjtoMovieRepository(),
    SupportedService.ekino: EkinoMovieRepository(),
  });
  getIt.registerSingleton<Map<SupportedService, SearchRepository>>({
    SupportedService.filman: FilmanSearchRepository(),
    SupportedService.obejrzyjto: ObejrzyjtoSearchRepository(),
    SupportedService.ekino: EkinoSearchRepository(),
  });

  getIt.registerSingleton<GlobalContext>(GlobalContext());
}
