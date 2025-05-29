import 'dart:convert';
import 'dart:ffi';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_dio_factory.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:purevideo/di/injection_container.dart';

class ObejrzyjtoMovieRepository implements MovieRepository {
  static final RegExp _bootstrapDataRegex = RegExp(
    r'window\.bootstrapData\s*=\s*(\{.*?\});',
    dotAll: true,
  );

  final AuthRepository _authRepository = getIt<
      Map<SupportedService, AuthRepository>>()[SupportedService.obejrzyjto]!;
  final VideoSourceRepository _videoSourceRepository =
      getIt<VideoSourceRepository>();

  Dio? _dio;

  ObejrzyjtoMovieRepository() {
    _authRepository.authStream.listen(_onAuthChanged);
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.obejrzyjto) {
      _dio = ObejrzyjtoDioFactory.getDio(auth.account);
    }
  }

  Future<void> _prepareDio() async {
    _dio ??= ObejrzyjtoDioFactory.getDio(
      _authRepository.getAccountForService(SupportedService.obejrzyjto),
    );
  }

  @override
  Future<EpisodeModel> getEpisodeHosts(EpisodeModel episode) async {
    await _prepareDio();

    return const EpisodeModel(
        title: "", url: "", videoUrls: [HostLink("", "", "")]);
  }

  @override
  Future<MovieDetailsModel> getMovieDetails(String url) async {
    await _prepareDio();

    final response = await _dio!.get(url);
    final bootstrapData = _extractBootstrapData(response.data);

    if (bootstrapData == null) {
      throw Exception(
          'Nie udało się pobrać danych bootstrap z odpowiedzi serwera.');
    }

    final watchPageData = bootstrapData['loaders']?['watchPage'];
    // final movieData = watchPageData?['alternative_videos'] as List?;
    final details = watchPageData?['title'];

    // if (movieData == null || movieData.isEmpty || details == null) {
    //   throw Exception('Brak danych o filmie w odpowiedzi serwera.');
    // }

    return _buildMovieDetails(url, details);
  }

  MovieDetailsModel _buildMovieDetails(
      String url, Map<String, dynamic> details) {
    debugPrint(details.toString());

    final title = details['name'] as String?;
    if (title == null || title.isEmpty) {
      throw Exception('Brak tytułu filmu w danych serwera.');
    }

    final description = details['description'] as String?;
    if (description == null || description.isEmpty) {
      throw Exception('Brak opisu filmu w danych serwera.');
    }

    debugPrint({
      'service': SupportedService.obejrzyjto,
      'url': url,
      'title': title,
      'description': description,
      'imageUrl': details['poster'] ?? '',
      'year': details['year'] ?? '',
      'genres': [],
      'countries': [],
      'isSeries': details['is_series'].toString() == 'true',
    }.toString());

    return MovieDetailsModel(
      service: SupportedService.obejrzyjto,
      url: url,
      title: title,
      description: description,
      imageUrl: details['poster'] ?? '',
      year: details['year'] ?? '',
      genres: [],
      countries: [],
      isSeries: details['is_series'].toString() == 'true',
    );
  }

  @override
  Future<List<MovieModel>> getMovies() async {
    await _prepareDio();

    final response = await _dio!.get('/');
    final bootstrapData = _extractBootstrapData(response.data);

    return bootstrapData != null
        ? _parseMoviesFromData(bootstrapData)
        : <MovieModel>[];
  }

  Map<String, dynamic>? _extractBootstrapData(String responseData) {
    final match = _bootstrapDataRegex.firstMatch(responseData);
    final jsonString = match?.group(1);

    if (jsonString == null) return null;

    final data = jsonDecode(jsonString);
    return data is Map<String, dynamic> ? data : null;
  }

  List<MovieModel> _parseMoviesFromData(Map<String, dynamic> data) {
    final loaders = data['loaders']?['channelPage']?['channel']?['content']
        ?['data'] as List?;
    if (loaders == null) return <MovieModel>[];

    return loaders
        .expand((loader) => _parseMoviesFromLoader(loader))
        .whereType<MovieModel>()
        .toList();
  }

  Iterable<MovieModel?> _parseMoviesFromLoader(Map<String, dynamic> loader) {
    final loaderName = loader['name'] as String?;
    final contentData = loader['content']?['data'] as List?;

    return contentData
            ?.map((movieData) => _parseMovie(movieData, loaderName)) ??
        [];
  }

  MovieModel? _parseMovie(Map<String, dynamic> data, String? category) {
    final name = data['name'] as String?;
    final poster = data['poster'] as String?;
    final primaryVideoId = data['primary_video']?['id'];

    if (name == null || primaryVideoId == null) return null;

    return MovieModel(
      service: SupportedService.obejrzyjto,
      title: name,
      imageUrl: poster ?? '',
      url: '/watch/$primaryVideoId',
      category: category ?? '',
    );
  }
}
