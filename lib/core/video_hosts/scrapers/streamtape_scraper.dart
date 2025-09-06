import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class StreamtapeScraper extends VideoHostScraper {
  final Dio _dio;

  StreamtapeScraper(this._dio);

  @override
  String get name => 'Streamtape';

  @override
  List<String> get domains => [
        'streamtape.com',
        'strtape.cloud',
        'streamtape.net',
        'streamta.pe',
        'streamtape.site',
        'strcloud.link',
        'strcloud.club',
        'strtpe.link',
        'streamtape.cc',
        'scloud.online',
        'stape.fun',
        'streamadblockplus.com',
        'shavetape.cash',
        'streamtape.to',
        'streamta.site',
        'streamadblocker.xyz',
        'tapewithadblock.org',
        'adblocktape.wiki',
        'antiadtape.com',
        'streamtape.xyz',
        'tapeblocker.com',
        'streamnoads.com',
        'tapeadvertisement.com',
        'tapeadsenjoyer.com',
        'watchadsontape.com'
      ];

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final response = await _dio.get(url,
          options: Options(
            followRedirects: false,
            validateStatus: (status) => true,
          ));
      final jsLineMatch = RegExp(
        r"(?<=document\.getElementById\('botlink'\)\.innerHTML = )(.*)(?=;)",
      ).firstMatch(response.data);

      if (jsLineMatch == null || jsLineMatch.group(0) == null) {
        return null;
      }

      final String jsLine = jsLineMatch.group(0)!;
      final List<String> urls = RegExp(r"'([^']*)'")
          .allMatches(jsLine)
          .map((m) => m.group(0)!.replaceAll("'", ''))
          .toList();

      if (urls.length != 2) {
        return null;
      }

      final String base = urls[0];
      final String encoded = urls[1];
      final String fullUrl = 'https:$base${encoded.substring(4)}';

      final apiResponse = await _dio.get(
        fullUrl,
        options: Options(
          followRedirects: false,
          validateStatus: (status) => true,
        ),
      );

      final String? directLink = apiResponse.headers['location']?.first;
      if (directLink == null) {
        return null;
      }

      return VideoSource(
        url: Uri.parse(directLink).toString(),
        lang: lang,
        quality: quality,
        host: name,
        headers: {
          'Referer': url,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła ze Streamtape($url): $e');
      return null;
    }
  }
}
