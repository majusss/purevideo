import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import '../video_scraper.dart';

class DoodstreamScraper implements VideoScraper {
  final Dio _dio = Dio();
  final RegExp _tokenRegex = RegExp(r'/pass_md5/([a-zA-Z0-9]+)');

  @override
  Future<String?> getVideoSource(String url) async {
    try {
      final response = await _dio.get(url);
      final document = html_parser.parse(response.data);
      final scripts = document.getElementsByTagName('script');

      String? token;
      for (final script in scripts) {
        final match = _tokenRegex.firstMatch(script.text);
        if (match != null) {
          token = match.group(1);
          break;
        }
      }

      if (token == null) return null;

      final videoResponse = await _dio.get(
        'https://dood.yt/pass_md5/$token',
        options: Options(headers: {'Referer': url}),
      );

      return videoResponse.data;
    } catch (e) {
      return null;
    }
  }
}
