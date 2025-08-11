import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/ekino/ekino_dio_factory.dart';
import 'package:purevideo/data/repositories/search_repository.dart';
import 'package:purevideo/di/injection_container.dart';

class EkinoSearchRepository extends SearchRepository {
  final AuthRepository _authRepository =
      getIt<Map<SupportedService, AuthRepository>>()[SupportedService.ekino]!;
  Dio? _dio;

  EkinoSearchRepository() {
    _authRepository.authStream.listen(_onAuthChanged);
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.ekino) {
      _dio = EkinoDioFactory.getDio(auth.account);
    }
  }

  Future<void> _prepareDio() async {
    if (_dio == null) {
      final account = _authRepository.getAccount();
      _dio = EkinoDioFactory.getDio(account);
    }
  }

  @override
  Future<List<ServiceMovieModel>> searchMovies(String query) async {
    if (query.isEmpty) {
      return [];
    }

    await _prepareDio();

    final response = await _dio!.get(
      '/search/qf',
      queryParameters: {'q': query},
    );

    final document = html.parse(response.data);

    final movies = <ServiceMovieModel>[];

    document.querySelectorAll('.movies-list-item').forEach((movieElement) {
      final coverElement = movieElement.querySelector('.cover-list a');
      if (coverElement == null) return;

      final url = coverElement.attributes['href'] ?? '';
      if (url.isEmpty) return;

      final imageUrl =
          coverElement.querySelector('img')?.attributes['src'] ?? '';

      final titleElement = movieElement.querySelector('.opis-list .title a');
      if (titleElement == null) return;

      final title = titleElement.text.trim();
      if (title.isEmpty) return;

      String cleanTitle = title;
      if (title.contains(' - HD')) {
        cleanTitle = title.split(' - HD').first.trim();
      } else if (title.contains(' - CAM')) {
        cleanTitle = title.split(' - CAM').first.trim();
      }

      String fullImageUrl = imageUrl;
      if (imageUrl.isNotEmpty && imageUrl.startsWith('/')) {
        fullImageUrl = 'https://ekino-tv.pl$imageUrl';
      }

      movies.add(ServiceMovieModel(
        service: SupportedService.ekino,
        title: cleanTitle,
        imageUrl: fullImageUrl,
        url: url,
      ));
    });

    return movies;
  }
}
