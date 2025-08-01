import 'package:collection/collection.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class VideoHostRegistry {
  final List<VideoHostScraper> _scrapers = [];

  void registerScraper(VideoHostScraper scraper) {
    _scrapers.add(scraper);
  }

  VideoHostScraper? getScraperForUrl(String url) {
    return _scrapers.firstWhereOrNull((scraper) => scraper.canHandle(url));
  }

  bool isHostSupported(String url) {
    try {
      return _scrapers.any((scraper) => scraper.canHandle(url));
    } catch (e) {
      return false;
    }
  }

  List<VideoHostScraper> get scrapers => List.unmodifiable(_scrapers);
}
