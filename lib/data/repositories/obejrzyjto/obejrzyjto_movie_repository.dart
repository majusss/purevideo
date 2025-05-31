import 'package:dio/dio.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_dio_factory.dart';
import 'package:purevideo/data/repositories/obejrzyjto/obejrzyjto_utils.dart';
import 'package:purevideo/data/repositories/video_source_repository.dart';
import 'package:purevideo/di/injection_container.dart';

class ObejrzyjtoMovieRepository implements MovieRepository {
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

    final episodeResponse = await _dio!.get(episode.url);

    final bootstrapData = extractBootstrapData(episodeResponse.data);

    if (bootstrapData == null) {
      throw Exception(
          'Nie udało się pobrać danych bootstrap z odpowiedzi serwera.');
    }

    final watchPageData = bootstrapData['loaders']?['episodePage'];

    if (watchPageData['episode'] == null) {
      throw Exception('Brak danych o epizodzie.');
    }

    final episodeData = watchPageData['episode'];

    final videoData = episodeData['videos'] as List?;
    if (videoData == null || videoData.isEmpty) {
      throw Exception('Brak danych o hostach.');
    }

    final videoUrls = _extractVideoUrls(videoData);

    return episode.copyWith(
      videoUrls: videoUrls,
    );
  }

  Future<MovieDetailsModel> scrapeSeasons(
      MovieDetailsModel movie, int movieId) async {
    await _prepareDio();

    final response = await _dio!.get('/api/v1/titles/$movieId/seasons',
        options: Options(headers: {
          'Referer': 'https://www.obejrzyj.to/',
        }));

    if (response.data['pagination']['data'] == null) {
      throw Exception('Nie udało się pobrać danych z odpowiedzi serwera.');
    }

    final List data = response.data['pagination']['data'];

    final seasonCount = data.length;

    final List<SeasonModel> seasons = [];

    for (var i = 1; i <= seasonCount; i++) {
      final seasonResponse = await _dio!.get(
          '/api/v1/titles/$movieId/seasons/$i/episodes?perPage=999&excludeDescription=true&query=&orderBy=episode_number&orderDir=asc&page=1',
          options: Options(headers: {
            'Referer': 'https://www.obejrzyj.to/',
          }));

      final List episodesData = seasonResponse.data['pagination']['data'];

      final List<EpisodeModel> episodes = [];

      for (var j = 1; j <= episodesData.length; j++) {
        final episodeData = episodesData[j - 1];
        final name = episodeData['name'] as String?;
        if (name == null || name.isEmpty) {
          continue;
        }
        episodes.add(EpisodeModel(
          title: name,
          url:
              '/titles/$movieId/${generateSlug(movie.title)}/season/$i/episode/$j',
          videoUrls: [],
        ));
      }

      seasons.add(SeasonModel(name: 'Sezon $i', episodes: episodes));
    }

    return movie.copyWith(
      seasons: seasons,
    );
  }

  @override
  Future<MovieDetailsModel> getMovieDetails(String url) async {
    await _prepareDio();

    final response = await _dio!.get(url);
    final bootstrapData = extractBootstrapData(response.data);

    if (bootstrapData == null) {
      throw Exception(
          'Nie udało się pobrać danych bootstrap z odpowiedzi serwera.');
    }

    final watchPageData = bootstrapData['loaders']?['watchPage'];
    if (watchPageData['alternative_videos'] == null) {
      throw Exception('Brak danych o hostach.');
    }

    final videoData = watchPageData['alternative_videos'] as List?;
    if (videoData == null || videoData.isEmpty) {
      throw Exception('Brak danych o hostach.');
    }

    final videoUrls = _extractVideoUrls(videoData);

    final details = watchPageData?['title'];
    final movieModel = _buildMovieDetails(url, details, videoUrls);

    if (movieModel.isSeries) {
      final movieId = details['id'] as int?;
      if (movieId == null) {
        throw Exception('Brak ID filmu w danych serwera.');
      }

      final series = await scrapeSeasons(
        movieModel,
        movieId,
      );

      return series;
    }

    final updatedMovieModel =
        await _videoSourceRepository.scrapeVideoUrls(movieModel);

    return updatedMovieModel;
  }

  List<HostLink> _extractVideoUrls(List videoData) {
    final videoUrls = <HostLink>[];

    for (final video in videoData) {
      final url = video['src'] as String?;

      final quality = video['quality'] as String?;
      final lang = video['language'] as String?;

      if (url == null || url.isEmpty) {
        continue;
      }

      if (quality == null || quality.isEmpty) {
        continue;
      }

      if (lang == null || lang.isEmpty) {
        continue;
      }

      videoUrls.add(HostLink(
          url: url.replaceAll("?autoplay=1", ""),
          quality: quality,
          lang: lang));
    }

    return videoUrls;
  }

  MovieDetailsModel _buildMovieDetails(
      String url, Map<String, dynamic> details, List<HostLink> videoUrls) {
    final title = details['name'] as String?;
    if (title == null || title.isEmpty) {
      throw Exception('Brak tytułu filmu w danych serwera.');
    }

    final description = details['description'] as String?;
    if (description == null || description.isEmpty) {
      throw Exception('Brak opisu filmu w danych serwera.');
    }

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
        videoUrls: videoUrls);
  }

  @override
  Future<List<MovieModel>> getMovies() async {
    await _prepareDio();

    final response = await _dio!.get('/');
    final bootstrapData = extractBootstrapData(response.data);

    return bootstrapData != null
        ? _parseMoviesFromData(bootstrapData)
        : <MovieModel>[];
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
