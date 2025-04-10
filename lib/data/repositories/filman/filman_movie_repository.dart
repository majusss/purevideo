import 'package:dio/dio.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_dio_factory.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:html/parser.dart' as html;
import 'package:purevideo/di/injection_container.dart';

class FilmanMovieRepository implements MovieRepository {
  final AuthRepository _authRepository =
      getIt<Map<SupportedService, AuthRepository>>()[SupportedService.filman]!;
  Dio? _dio;

  FilmanMovieRepository() {
    _authRepository.authStream.listen(_onAuthChanged);
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.filman) {
      _dio = FilmanDioFactory.getDio(auth.account);
    }
  }

  @override
  Future<List<MovieModel>> getMovies() async {
    if (_dio == null) {
      final account = _authRepository.getAccountForService(
        SupportedService.filman,
      );
      _dio = FilmanDioFactory.getDio(account);
    }

    final response = await _dio!.get('/');
    final document = html.parse(response.data);

    final movies = <MovieModel>[];

    for (final list in document.querySelectorAll("div[id=item-list]")) {
      for (final item in list.children) {
        final poster = item.querySelector(".poster");
        final title =
            poster
                ?.querySelector("a")
                ?.attributes["title"]
                ?.trim()
                .split("/")
                .first
                .trim() ??
            "Brak danych";
        final imageUrl =
            poster?.querySelector("img")?.attributes["src"] ??
            "https://placehold.co/250x370/png?font=roboto&text=?";
        final link =
            poster?.querySelector("a")?.attributes["href"] ?? "Brak danych";
        final category =
            list.parent?.querySelector("h3")?.text.trim() ?? "INNE";

        final movie = MovieModel(
          service: SupportedService.filman,
          title: title,
          imageUrl: imageUrl,
          url: link,
          category: category,
        );

        movies.add(movie);
      }
    }

    return movies;
  }

  @override
  Future<MovieDetailsModel> getMovieDetails(String url) async {
    if (_dio == null) {
      final account = _authRepository.getAccountForService(
        SupportedService.filman,
      );
      _dio = FilmanDioFactory.getDio(account);
    }

    final response = await _dio!.get(url);
    final document = html.parse(response.data);

    final title =
        document.querySelector('[itemprop="name"]')?.text.trim() ??
        'Brak tytułu';
    final description =
        document.querySelector('.description')?.text.trim() ?? '';
    final imageUrl =
        document.querySelector('#single-poster img')?.attributes['src'] ?? '';

    String year = '';
    List<String> genres = [];
    List<String> countries = [];

    final infoBox = document.querySelector('.info');
    if (infoBox != null) {
      for (final ulElement in infoBox.children) {
        if (ulElement.children.isEmpty) continue;

        final label = ulElement.children.first.text.trim();

        switch (label) {
          case 'Rok:':
          case 'Premiera:':
            if (ulElement.children.length > 1) {
              year = ulElement.children[1].text.trim();
            }
            break;
          case 'Gatunek:':
          case 'Kategoria:':
            genres =
                ulElement
                    .querySelectorAll('li a')
                    .map((e) => e.text.trim())
                    .toList();
            break;
          case 'Kraj:':
            countries =
                ulElement
                    .querySelectorAll('li a')
                    .map((e) => e.text.trim())
                    .toList();
            break;
        }
      }
    }

    final episodeList = document.querySelector('#episode-list');
    final isSeries = episodeList != null;

    if (isSeries) {
      final seasons = <SeasonModel>[];
      for (final seasonElement in episodeList.children) {
        final seasonName = seasonElement.children.first.text.trim();
        final episodes = <EpisodeModel>[];
        for (final episodeElement in seasonElement.children.last.children) {
          final title = episodeElement.text.trim();
          final url =
              episodeElement.querySelector('a')?.attributes['href'] ?? '';

          episodes.add(
            EpisodeModel(
              title: title,
              url: url,
              description: Future.value("TODO"),
              links: Future.value([]),
            ),
          );
        }
        seasons.add(SeasonModel(name: seasonName, episodes: episodes));
      }
      return MovieDetailsModel(
        service: SupportedService.filman,
        title: title,
        description: description,
        imageUrl: imageUrl,
        year: year,
        genres: genres,
        countries: countries,
        isSeries: isSeries,
        seasons: seasons.reversed.toList(),
      );
    }
    return MovieDetailsModel(
      service: SupportedService.filman,
      title: title,
      description: description,
      imageUrl: imageUrl,
      year: year,
      genres: genres,
      countries: countries,
      isSeries: isSeries,
    );
  }
}
