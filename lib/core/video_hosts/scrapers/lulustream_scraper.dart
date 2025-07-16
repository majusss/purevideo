import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class LuluStreamScraper extends VideoHostScraper {
  final Dio _dio;

  LuluStreamScraper(this._dio);

  @override
  String get name => 'LuluStream';

  @override
  List<String> get domains => [
        'lulustream.com',
        'luluvdo.com',
        'lulu.st',
        '732eg54de642sa.sbs',
        'cdn1.site',
        'streamhihi.com',
        'luluvdoo.com',
        'd00ds.site'
      ];

  static const String _pattern =
      r'''sources:\s*\[{file:\s*["'](?<url>[^"']+)''';

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final response = await _dio.get(url);

      final regex = RegExp(_pattern);
      final match = regex.firstMatch(response.data.toString());

      if (match == null || match.group(1) == null) {
        return null;
      }

      return VideoSource(
        url: match.group(1)!,
        lang: lang,
        quality: quality,
        host: name,
        headers: {
          'User-Agent': 'PostmanRuntime/7.44.0',
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła z LuluStream($url): $e');
      return null;
    }
  }
}
