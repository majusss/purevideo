import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html;
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class VidozaScraper extends VideoHostScraper {
  final Dio _dio;

  VidozaScraper(this._dio);

  @override
  String get name => 'Vidoza';

  @override
  List<String> get domains => ['vidoza.net'];

  @override
  Future<VideoSource?> getVideoSource(String url) async {
    try {
      final response = await _dio.get(url);
      final document = html.parse(response.data);

      if (document.body?.text == "File was deleted") {
        return null;
      }

      final directLink = document.querySelector("source")?.attributes["src"];
      if (directLink == null) {
        return null;
      }

      return VideoSource(
        url: Uri.parse(directLink).toString(),
        quality: VideoQuality.p720,
        headers: {
          'Referer': url,
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła z Vidoza: $e');
      return null;
    }
  }
}
