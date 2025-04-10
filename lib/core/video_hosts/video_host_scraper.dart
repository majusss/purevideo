abstract class VideoHostScraper {
  /// Nazwa hosta (np. 'CDA', 'Voe', 'Streamtape')
  String get name;

  /// Lista domen obsługiwanych przez tego scrapera (np. ['cda.pl', 'www.cda.pl'])
  List<String> get domains;

  /// Sprawdza czy podany URL jest obsługiwany przez tego scrapera
  bool canHandle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return domains.any((domain) => uri.host.endsWith(domain));
  }

  /// Pobiera bezpośredni link do wideo
  /// Zwraca null jeśli nie udało się pobrać linku
  /// Rzuca wyjątek w przypadku błędu (np. wideo zostało usunięte)
  Future<VideoSource?> getVideoSource(String url);
}

class VideoSource {
  final String url;
  final VideoQuality quality;
  final Map<String, String>? headers;

  const VideoSource({required this.url, required this.quality, this.headers});
}

enum VideoQuality {
  p360('360p'),
  p480('480p'),
  p720('720p'),
  p1080('1080p');

  final String label;
  const VideoQuality(this.label);
}
