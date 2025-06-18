import 'package:hive_flutter/adapters.dart';

part 'video_host_scraper.g.dart';

abstract class VideoHostScraper {
  String get name;

  List<String> get domains;

  bool canHandle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return domains.any((domain) => uri.host.endsWith(domain));
  }

  Future<VideoSource?> getVideoSource(String url, String lang, String quality);
}

@HiveType(typeId: 3)
class VideoSource {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String lang;

  @HiveField(2)
  final String quality;

  @HiveField(3)
  final String host;

  @HiveField(4)
  final Map<String, String>? headers;

  const VideoSource(
      {required this.url,
      required this.lang,
      required this.quality,
      required this.host,
      this.headers});

  @override
  String toString() {
    return 'VideoSource(url: $url, lang: $lang, quality: $quality, headers: $headers)';
  }
}
