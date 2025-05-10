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

class VideoSource {
  final String url, lang, quality;
  final Map<String, String>? headers;

  const VideoSource(
      {required this.url,
      required this.lang,
      required this.quality,
      this.headers});
}
