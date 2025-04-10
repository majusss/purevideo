import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class VideoHostRegistry {
  final Map<String, VideoHostScraper> _scrapers = {};

  static final VideoHostRegistry instance = VideoHostRegistry._();

  VideoHostRegistry._();

  void registerScraper(VideoHostScraper scraper) {
    _scrapers[scraper.name] = scraper;
  }

  VideoHostScraper? getScraperForUrl(String url) {
    return _scrapers.values.firstWhere(
      (scraper) => scraper.canHandle(url),
      orElse: () => throw UnsupportedHostException(url),
    );
  }

  List<VideoHostScraper> get scrapers => _scrapers.values.toList();
}

class UnsupportedHostException implements Exception {
  final String url;

  UnsupportedHostException(this.url);

  @override
  String toString() =>
      'Nieobsługiwany host wideo: ${Uri.tryParse(url)?.host ?? url}';
}
