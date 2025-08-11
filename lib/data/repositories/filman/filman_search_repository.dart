import 'package:dio/dio.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_dio_factory.dart';
import 'package:purevideo/data/repositories/search_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:html/parser.dart' as html;

class FilmanSearchRepository implements SearchRepository {
  final AuthRepository _authRepository =
      getIt<Map<SupportedService, AuthRepository>>()[SupportedService.filman]!;
  Dio? _dio;

  FilmanSearchRepository() {
    _authRepository.authStream.listen(_onAuthChanged);
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.filman) {
      _dio = FilmanDioFactory.getDio(auth.account);
    }
  }

  Future<void> _prepareDio() async {
    if (_dio == null) {
      final account = _authRepository.getAccount();
      _dio = FilmanDioFactory.getDio(account);
    }
  }

  @override
  Future<List<ServiceMovieModel>> searchMovies(String query) async {
    if (query.isEmpty) {
      return [];
    }

    await _prepareDio();

    final response = await _dio!.get(
      '/item',
      queryParameters: {'phrase': query},
    );

    final document = html.parse(response.data);

    final movies = <ServiceMovieModel>[];

    document
        .querySelectorAll('.col-xs-6.col-sm-3.col-lg-2')
        .forEach((final filmDOM) {
      final poster = filmDOM.querySelector('.poster');
      final title =
          filmDOM.querySelector('.film_title')?.text.trim() ?? 'Brak danych';
      final imageUrl =
          poster?.querySelector('img')?.attributes['src']?.trim() ?? '';
      final link =
          poster?.querySelector('a')?.attributes['href'] ?? 'Brak danych';

      if (title.isEmpty || imageUrl.isEmpty == true || link.isEmpty) return;
      movies.add(ServiceMovieModel(
          service: SupportedService.filman,
          title: title,
          imageUrl: imageUrl,
          url: link));
    });

    return movies;
  }
}
