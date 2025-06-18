import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:purevideo/core/video_hosts/scrapers/doodstream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/kinoger_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/lulustream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamruby_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamtape_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vidoza_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vtube_scraper.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';

class VideoHostsContainer {
  static void registerVideoScrapers(VideoHostRegistry registry) {
    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    final ioc = HttpClient();
    ioc.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => ioc,
    );

    // filman.cc
    registry.registerScraper(StreamtapeScraper(dio));
    registry.registerScraper(VidozaScraper(dio));
    registry.registerScraper(DoodStreamScraper(dio));
    registry.registerScraper(VtubeScraper(dio));

    // obejrzyj.to
    registry.registerScraper(KinoGerScraper(dio));
    registry.registerScraper(LuluStreamScraper(dio));
    registry.registerScraper(StreamrubyScraper(dio));
  }
}
