import 'package:purevideo/core/video_hosts/video_host_registry.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/data/models/movie_model.dart';
import 'package:purevideo/di/injection_container.dart';

class VideoSourceRepository {
  final VideoHostRegistry _hostRegistry = getIt<VideoHostRegistry>();

  Future<MovieDetailsModel> scrapeVideoUrls(MovieDetailsModel movie) async {
    if (movie.videoUrls == null) return movie;

    final videoSources = <VideoSource>[];

    for (final hostLink in movie.videoUrls!) {
      final scraper = _hostRegistry.getScraperForUrl(hostLink.url);

      if (scraper == null) continue;

      final videoSource = await scraper.getVideoSource(
          hostLink.url, hostLink.lang, hostLink.quality);

      if (videoSource == null) continue;

      videoSources.add(videoSource);
    }

    return movie.copyWith(directUrls: videoSources);
  }
}
