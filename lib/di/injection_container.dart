import 'package:get_it/get_it.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_movie_repository.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:purevideo/presentation/blocs/movies/movies_bloc.dart';
import 'package:purevideo/presentation/widgets/re_captcha.dart';

final getIt = GetIt.instance;

void setupInjection() {
  getIt.registerFactory<ReCaptchaBloc>(() => ReCaptchaBloc());

  getIt.registerSingleton<Map<SupportedService, AuthRepository>>({
    SupportedService.filman: FilmanAuthRepository(),
  });
  getIt.registerSingleton<Map<SupportedService, MovieRepository>>({
    SupportedService.filman: FilmanMovieRepository(),
  });

  getIt.registerFactory<AccountsBloc>(() => AccountsBloc());
  getIt.registerFactory<MoviesBloc>(() => MoviesBloc());
}
