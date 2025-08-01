import 'package:purevideo/core/services/webview_service.dart';
import 'package:purevideo/core/video_hosts/video_host_registry.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';
import 'package:purevideo/di/injection_container.dart';

class EkinoScraper extends VideoHostScraper {
  final _hostRegistry = getIt<VideoHostRegistry>();

  EkinoScraper();

  @override
  String get name => 'Ekino';

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    final iframeUrl =
        (await getIt<WebViewService>().waitForDomElement(url, 'iframe'))
            ?.attributes['src'];
    if (iframeUrl == null) {
      return null;
    }

    final videoHost = _hostRegistry.getScraperForUrl(iframeUrl);
    if (videoHost == null) {
      return null;
    }

    return videoHost.getVideoSource(iframeUrl, lang, quality);
  }

  @override
  List<String> get domains => ['play.ekino.link'];
}
