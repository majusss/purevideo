import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/core/video_hosts/scrapers/doodstream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/kinoger_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/lulustream_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamruby_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/streamtape_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vidoza_scraper.dart';
import 'package:purevideo/core/video_hosts/scrapers/vtube_scraper.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/link_model.dart';
import 'package:purevideo/data/models/movie_model.dart';

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

  // hive test
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  Hive.registerAdapter(SupportedServiceAdapter());
  Hive.registerAdapter(MovieModelAdapter());
  Hive.registerAdapter(MovieDetailsModelAdapter());
  Hive.registerAdapter(VideoSourceAdapter());
  Hive.registerAdapter(SeasonModelAdapter());
  Hive.registerAdapter(EpisodeModelAdapter());
  Hive.registerAdapter(HostLinkAdapter());

  debugPrint("testing movie model");
  await Hive.openBox<MovieModel>("testMovie");
  final box = Hive.box<MovieModel>('testMovie');
  debugPrint("adding movie to box");
  await box.add(const MovieModel(
      service: SupportedService.filman,
      title: "test",
      imageUrl: "file://test",
      url: "://test"));
  debugPrint("movie added to box");
  MovieModel? movie = box.getAt(0);
  debugPrint("movie retrieved from box: ${movie?.title}");

  debugPrint("testing movie details model");
  await Hive.openBox<MovieDetailsModel>("testMovieDetails");
  final detailsBox = Hive.box<MovieDetailsModel>('testMovieDetails');
  debugPrint("adding movie details to box");
  await detailsBox.add(const MovieDetailsModel(
      service: SupportedService.filman,
      url: "//a",
      title: "test details",
      description: "test detail desc",
      imageUrl: "//aaa",
      year: "2010",
      genres: ["a"],
      countries: ["a"],
      seasons: [
        SeasonModel(name: "Season 1", episodes: [
          EpisodeModel(
              title: "Episode 1",
              url: "//a",
              videoUrls: [HostLink(lang: "pl", quality: "720p", url: "//a")])
        ])
      ],
      directUrls: [
        VideoSource(url: "//a", lang: "pl", quality: "720p", host: "filman")
      ],
      isSeries: true));
  debugPrint("movie details added to box");
  MovieDetailsModel? details = detailsBox.getAt(0);
  debugPrint(
      "movie details retrieved from box: ${details?.title} - ${details?.year} - ${details?.genres} - ${details?.countries} - ${details?.isSeries} - ${details?.imageUrl} - ${details?.description} - ${details?.url}");
}
