import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html;
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class VoeScraper extends VideoHostScraper {
  final Dio _dio;

  VoeScraper(this._dio);

  @override
  String get name => 'Voe';

  @override
  List<String> get domains => ['voe.sx'];

  @override
  Future<VideoSource?> getVideoSource(String url) async {
    try {
      final response = await _dio.get(url);
      final document = html.parse(response.data);

      // Szukamy tagu script zawierającego 'hls'
      final scripts = document.querySelectorAll('script');
      String? m3u8Url;

      for (final script in scripts) {
        final content = script.text;
        if (content.contains('hls')) {
          // Przykładowy regex do wyciągnięcia URL m3u8
          final match = RegExp(r'hls": "([^"]+)"').firstMatch(content);
          if (match != null) {
            m3u8Url = match.group(1);
            break;
          }
        }
      }

      if (m3u8Url == null) return null;

      return VideoSource(
        url: m3u8Url,
        quality: VideoQuality.p720, // VOE zazwyczaj oferuje 720p
        headers: {
          'Referer': url,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła z VOE: $e');
      return null;
    }
  }
}
