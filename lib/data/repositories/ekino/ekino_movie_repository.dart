import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:purevideo/core/services/webview_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/data/models/auth_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/data/repositories/ekino/ekino_dio_factory.dart';
import 'package:purevideo/data/repositories/movie_repository.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

class EkinoMovieRepository implements MovieRepository {
  final AuthRepository _authRepository =
      getIt<Map<SupportedService, AuthRepository>>()[SupportedService.ekino]!;

  Dio? _dio;

  EkinoMovieRepository() {
    _authRepository.authStream.listen(_onAuthChanged);
  }

  void _onAuthChanged(AuthModel auth) {
    if (auth.service == SupportedService.obejrzyjto) {
      _dio = EkinoDioFactory.getDio(auth.account);
    }
  }

  Future<void> _prepareDio() async {
    _dio ??= EkinoDioFactory.getDio(
      _authRepository.getAccount(),
    );
  }

  Future<List<HostLink>> _extractHostLinksFromDocument(
      dom.Document document) async {
    final videoUrls = <HostLink>[];
    final tabPanes =
        document.querySelectorAll('.tab-content .tab-pane[role="tabpanel"]');
    final playerTabs = document.querySelectorAll('#myTab li');

    for (int i = 0; i < tabPanes.length && i < playerTabs.length; i++) {
      final tabPane = tabPanes[i];
      final playerTab = playerTabs[i];

      final tabId = tabPane.attributes['id'] ?? '';
      if (tabId.isEmpty || tabId == 'premium' || tabId == 'rek') continue;

      final onclickLink = tabPane.querySelector('a[onclick]');
      if (onclickLink == null) continue;

      final onclick = onclickLink.attributes['onclick'] ?? '';
      if (onclick.isEmpty) continue;

      final onclickMatch =
          RegExp(r"ShowPlayer\('([^']+)','([^']+)'\)").firstMatch(onclick);
      if (onclickMatch == null) continue;

      final hostName = onclickMatch.group(1) ?? '';
      final hostId = onclickMatch.group(2) ?? '';

      if (hostName.isEmpty || hostId.isEmpty) continue;

      final languageIcon = playerTab.querySelector('i.glyphicon');
      final language = languageIcon?.attributes['title']?.trim() ?? 'Nieznany';

      final qualityIcon = playerTab.querySelector('img');
      final quality = qualityIcon?.attributes['title']?.trim() ?? 'Nieznana';

      final gateUrl = '/watch/f/$hostName/$hostId';

      final videoUrl = (await getIt<WebViewService>().waitForDomElement(
              '${SupportedService.ekino.baseUrl}$gateUrl', 'a'))
          ?.attributes['href'];

      if (videoUrl == null || videoUrl.isEmpty) continue;

      videoUrls.add(HostLink(
        url: videoUrl,
        lang: language,
        quality: quality,
      ));
    }

    return videoUrls;
  }

  @override
  Future<EpisodeModel> getEpisodeHosts(EpisodeModel episode) async {
    await _prepareDio();

    final episodeResponse = await _dio!.get(episode.url);
    final document = html.parse(episodeResponse.data);

    final videoUrls = await _extractHostLinksFromDocument(document);

    videoUrls.map((url) => debugPrint('Video URL: ${url.url} from ${url.lang} '
        '(${url.quality})'));

    return episode.copyWith(
      videoUrls: videoUrls,
    );
  }

  @override
  Future<ServiceMovieDetailsModel> getMovieDetails(String url) async {
    await _prepareDio();

    final response = await _dio!.get(url);
    final document = html.parse(response.data);

    final titleElement = document.querySelector('h1.title');
    final title = titleElement?.text.trim() ?? 'Brak tytułu';

    String cleanTitle = title;
    if (title.contains(' - HD')) {
      cleanTitle = title.split(' - HD').first.trim();
    } else if (title.contains(' - CAM')) {
      cleanTitle = title.split(' - CAM').first.trim();
    }

    final descriptionElement = document.querySelector('.descriptionMovie');
    String description = descriptionElement?.text.trim() ?? '';

    final lines = description.split('\n');
    final cleanLines = <String>[];
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !trimmedLine.startsWith('Edit:')) {
        cleanLines.add(trimmedLine);
      }
    }
    description = cleanLines.join('\n');

    final posterElement = document.querySelector('.moviePoster');
    String imageUrl = posterElement?.attributes['src'] ?? '';
    if (imageUrl.isNotEmpty && imageUrl.startsWith('/')) {
      imageUrl = 'https://ekino-tv.pl$imageUrl';
    }

    final isSeries = document.querySelector('#list-series') != null;

    if (isSeries) {
      final seasons = <SeasonModel>[];
      final seriesContainer = document.querySelector('#list-series');

      if (seriesContainer != null) {
        final children = seriesContainer.children;

        for (int i = 0; i < children.length; i += 2) {
          final seasonElement = children[i];
          if (seasonElement.localName != 'p') continue;

          final seasonName = seasonElement.text.trim();

          if (i + 1 >= children.length) continue;
          final episodesList = children[i + 1];
          if (episodesList.localName != 'ul' ||
              !episodesList.classes.contains('list-series')) {
            continue;
          }

          final seasonNumberMatch =
              RegExp(r'Sezon (\d+)').firstMatch(seasonName);
          final seasonNumber = seasonNumberMatch != null
              ? int.tryParse(seasonNumberMatch.group(1) ?? '0') ?? 0
              : 0;

          final episodes = <EpisodeModel>[];

          for (final episodeItem in episodesList.children) {
            final episodeLink = episodeItem.querySelector('a');
            if (episodeLink == null) continue;

            final episodeUrl = episodeLink.attributes['href'] ?? '';
            if (episodeUrl.isEmpty) continue;

            final episodeTitle = episodeLink.text.trim();

            final episodeNumberDiv = episodeItem.querySelector('div');
            final episodeNumber = episodeNumberDiv != null
                ? int.tryParse(episodeNumberDiv.text.trim()) ?? 0
                : 0;

            episodes.add(EpisodeModel(
              title: episodeTitle,
              number: episodeNumber,
              url: episodeUrl,
              videoUrls: [],
            ));
          }

          seasons.add(SeasonModel(
            name: seasonName,
            number: seasonNumber,
            episodes: episodes.reversed.toList(),
          ));
        }
      }

      return ServiceMovieDetailsModel(
        service: SupportedService.ekino,
        url: url,
        title: cleanTitle,
        description: description,
        imageUrl: imageUrl,
        isSeries: true,
        seasons: seasons.reversed.toList(),
      );
    }

    final videoUrls = await _extractHostLinksFromDocument(document);

    final movieModel = ServiceMovieDetailsModel(
      service: SupportedService.ekino,
      url: url,
      title: cleanTitle,
      description: description,
      imageUrl: imageUrl,
      isSeries: false,
      videoUrls: videoUrls,
    );

    return movieModel;
  }

  @override
  Future<List<ServiceMovieModel>> getMovies() async {
    await _prepareDio();

    final response = await _dio!.get('/');
    final document = html.parse(response.data);

    final movies = <ServiceMovieModel>[];

    final movieSections = document.querySelectorAll('.mostPopular');

    for (final section in movieSections) {
      final categoryElement = section.querySelector('h4');
      if (categoryElement == null) continue;

      final subCategoryElement = section.querySelector('span');

      String category = categoryElement.text.trim();

      if (subCategoryElement != null && category == 'Najpopularniejsze') {
        category += ' ${subCategoryElement.text.trim()}';
      }

      final movieList = section.querySelector('ul.list');
      if (movieList == null) continue;

      for (final item in movieList.children) {
        final leftScope = item.querySelector('.scope_left');
        if (leftScope == null) continue;

        final link = leftScope.querySelector('a');
        if (link == null) continue;

        final url = link.attributes['href'] ?? '';
        if (url.isEmpty) continue;

        final img = link.querySelector('img');
        if (img == null) continue;

        String imageUrl = img.attributes['src'] ?? '';
        if (imageUrl.isNotEmpty && imageUrl.startsWith('//')) {
          imageUrl = 'https:$imageUrl';
        }

        final title = img.attributes['alt']?.trim() ?? 'Brak tytułu';

        String cleanTitle = title;
        if (title.contains(' - HD')) {
          cleanTitle = title.split(' - HD').first.trim();
        } else if (title.contains(' - CAM')) {
          cleanTitle = title.split(' - CAM').first.trim();
        }

        final movie = ServiceMovieModel(
          service: SupportedService.ekino,
          title: cleanTitle,
          imageUrl: imageUrl,
          url: url,
          category: category,
        );

        movies.add(movie);
      }
    }

    return movies;
  }
}
