import 'package:dio/dio.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_dio_factory.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_utils.dart';
import 'package:purevideo/data/repositories/search_repository.dart';
import 'package:purevideo/di/injection_container.dart';

class ObejrzyjtoSearchRepository extends SearchRepository {
  final AuthRepository _authRepository = getIt<
      Map<SupportedService, AuthRepository>>()[SupportedService.obejrzyjto]!;

  Dio? _dio;

  ObejrzyjtoSearchRepository() {
    _authRepository.authStream.listen(_onAuthChanged);
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.obejrzyjto) {
      _dio = ObejrzyjtoDioFactory.getDio(auth.account);
    }
  }

  Future<void> _prepareDio() async {
    _dio ??= ObejrzyjtoDioFactory.getDio(
      _authRepository.getAccount(),
    );
  }

  @override
  Future<List<MovieModel>> searchMovies(String query) async {
    if (query.isEmpty) {
      return [];
    }

    await _prepareDio();

    final response = await _dio!.get('/search/${Uri.encodeComponent(query)}');

    final bootstrapData = extractBootstrapData(response.data);
    final results =
        bootstrapData?['loaders']?['searchPage']?['results'] as List?;

    if (results == null || results.isEmpty) {
      return [];
    }

    final movies = <MovieModel>[];
    for (final movieData in results) {
      if (movieData == null) continue;

      final title = movieData['name'] as String?;
      final imageUrl = movieData['poster'] as String?;

      if (title == null || imageUrl == null) continue;

      final detailsResponse =
          await _dio!.get('/titles/${movieData['id']}/${generateSlug(title)}');

      final detailsBootstrapData = extractBootstrapData(detailsResponse.data);

      if (detailsBootstrapData == null) {
        continue;
      }

      final primaryVideoId = detailsBootstrapData['loaders']?['titlePage']
          ?['title']?['primary_video']?['id'] as int?;

      if (primaryVideoId == null) {
        continue;
      }

      movies.add(MovieModel(
          service: SupportedService.obejrzyjto,
          title: title,
          imageUrl: imageUrl,
          url: '/watch/$primaryVideoId'));
    }

    return movies;
  }
}
