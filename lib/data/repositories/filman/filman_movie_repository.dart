import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/filman/filman_dio_factory.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
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

  Future<void> _prepareDio() async {
    if (_dio == null) {
      final account = _authRepository.getAccount();
      _dio = FilmanDioFactory.getDio(account);
    }
  }

  List<HostLink> _extractHostLinksFromDocument(dom.Document document) {
    final videoUrls = <HostLink>[];

    for (final row in document.querySelectorAll('tbody tr')) {
      String? link;

      try {
        final decoded = base64Decode(
            row.querySelector('td a')?.attributes['data-iframe'] ?? '');
        link = (jsonDecode(utf8.decode(decoded))['src'] as String)
            .split('/')
            .take(7)
            .join('/');
      } catch (_) {
        link = null;
      }

      if (link == null || link.isEmpty == true) continue;

      final tableData = row.querySelectorAll('td');
      if (tableData.length < 3) continue;
      final language = tableData[1].text.trim();
      final qualityVersion = tableData[2].text.trim();

      videoUrls.add(HostLink(
        url: link,
        lang: language,
        quality: qualityVersion,
      ));
    }

    return videoUrls;
  }

  @override
  Future<List<ServiceMovieModel>> getMovies() async {
    await _prepareDio();

    final response = await _dio!.get('/');
    final document = html.parse(response.data);

    final movies = <ServiceMovieModel>[];

    for (final list in document.querySelectorAll('div[id=item-list]')) {
      for (final item in list.children) {
        final poster = item.querySelector('.poster');
        final title = poster
                ?.querySelector('a')
                ?.attributes['title']
                ?.trim()
                .split('/')
                .first
                .trim() ??
            'Brak danych';
        final imageUrl = poster?.querySelector('img')?.attributes['src'] ??
            'https://placehold.co/250x370/png?font=roboto&text=?';
        final link =
            poster?.querySelector('a')?.attributes['href'] ?? 'Brak danych';
        final category =
            list.parent?.querySelector('h3')?.text.trim() ?? 'INNE';

        final movie = ServiceMovieModel(
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

  Future<List<HostLink>> _scrapeEpisodeVideoUrls(String episodeUrl) async {
    await _prepareDio();

    final response = await _dio!.get(episodeUrl);
    final document = html.parse(response.data);

    final hostLinks = _extractHostLinksFromDocument(document);

    return hostLinks;
  }

  String _prepareTitle(String title) {
    return title.contains('/') ? title.split('/').first.trim() : title.trim();
  }

  @override
  Future<ServiceMovieDetailsModel> getMovieDetails(String url) async {
    await _prepareDio();

    final response = await _dio!.get(url);
    final document = html.parse(response.data);

    final title = _prepareTitle(
        document.querySelector('[itemprop="title"]')?.text.trim() ??
            document.querySelector('h2')?.text.trim() ??
            'Brak tytułu');
    final description =
        document.querySelector('.description')?.text.trim() ?? '';
    final imageUrl =
        document.querySelector('#single-poster img')?.attributes['src'] ?? '';

    final episodeList = document.querySelector('#episode-list');
    final isSeries = episodeList != null;

    if (isSeries) {
      final seasons = <SeasonModel>[];
      for (int i = 0; i < episodeList.children.length; i++) {
        final seasonElement = episodeList.children[i];
        final episodes = <EpisodeModel>[];

        for (int j = 0; j < seasonElement.children.last.children.length; j++) {
          final episodeElement = seasonElement.children.last.children[j];
          final episodeTitle = episodeElement.text.trim();
          final episodeUrl =
              episodeElement.querySelector('a')?.attributes['href'];

          if (episodeUrl == null) {
            continue;
          }

          episodes.add(
            EpisodeModel(
                title: episodeTitle,
                number: seasonElement.children.last.children.length - j,
                url: episodeUrl,
                videoUrls: []),
          );
        }

        seasons.add(SeasonModel(
            number: episodeList.children.length - i,
            episodes: episodes.toList().reversed.toList()));
      }

      return ServiceMovieDetailsModel(
        service: SupportedService.filman,
        url: url,
        title: title,
        description: description,
        imageUrl: imageUrl,
        isSeries: isSeries,
        seasons: seasons.toList().reversed.toList(),
      );
    }

    final videoUrls = _extractHostLinksFromDocument(document);

    final movieModel = ServiceMovieDetailsModel(
      service: SupportedService.filman,
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
      isSeries: isSeries,
      videoUrls: videoUrls,
    );

    return movieModel;
  }

  @override
  Future<EpisodeModel> getEpisodeHosts(EpisodeModel episode) async {
    final videoUrls = await _scrapeEpisodeVideoUrls(episode.url);
    return episode.copyWith(videoUrls: videoUrls);
  }
}
