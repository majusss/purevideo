import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:purevideo/core/video_hosts/scrapers/doodstream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/kinoger_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/lulustream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamruby_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamtape_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vidoza_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vtube_scraper.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';

void main() async {
  final registry = VideoHostRegistry();

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
  registry.registerScraper(KinoGerScraper(dio));
  registry.registerScraper(LuluStreamScraper(dio));
  registry.registerScraper(StreamrubyScraper(dio));

  final streamtape =
      registry.getScraperForUrl("https://streamtape.com/e/ZqaYmgmQLbTR0a");
  debugPrint((await streamtape?.getVideoSource(
          "https://streamtape.com/e/ZqaYmgmQLbTR0a", "Lektor", "720p"))
      .toString());

  final vidoza =
      registry.getScraperForUrl("https://videzz.net/embed-bwo6n958mgcl.html");
  debugPrint((await vidoza?.getVideoSource(
          "https://videzz.net/embed-bwo6n958mgcl.html", "Lektor", "720p"))
      .toString());

  final doodstream =
      registry.getScraperForUrl("https://doply.net/e/hgpi85creac0");
  debugPrint((await doodstream?.getVideoSource(
          "https://doply.net/e/hgpi85creac0", "Lektor", "720p"))
      .toString());

  final kinoger =
      registry.getScraperForUrl("https://ultrastream.online/#bktan");
  debugPrint((await kinoger?.getVideoSource(
          "https://ultrastream.online/#bktan", "Lektor", "720p"))
      .toString());

  // final moflix =
  //     registry.getScraperForUrl("https://boosteradx.online/v/w1xiqUUIjY5T/");
  // debugPrint((await moflix?.getVideoSource(
  //         "https://boosteradx.online/v/w1xiqUUIjY5T/", "Lektor", "720p"))
  //     .toString());

  final luluStream =
      registry.getScraperForUrl("https://lulu.st/e/wcshvwxkpmg3");
  debugPrint((await luluStream?.getVideoSource(
          "https://lulu.st/e/wcshvwxkpmg3", "Lektor", "720p"))
      .toString());

  final streamruby = registry.getScraperForUrl(
    "https://rubystm.com/embed-3a5j01prhwnz.html",
  );
  debugPrint((await streamruby?.getVideoSource(
          "https://rubystm.com/embed-3a5j01prhwnz.html", "Lektor", "720p"))
      .toString());
}
