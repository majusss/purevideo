import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:purevideo/core/video_hosts/scrapers/doodstream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamtape_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vidoza_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vtube_scraper.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';

class VideoHostsContainer {
  static void registerVideoScrapers(VideoHostRegistry registry) {
    final Dio dio = Dio();

    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => ioc,
    );

    registry.registerScraper(StreamtapeScraper(dio));
    registry.registerScraper(VidozaScraper(dio));
    registry.registerScraper(DoodStreamScraper(dio));
    registry.registerScraper(VtubeScraper(dio));
  }
}
