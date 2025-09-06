import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class StreamrubyScraper extends VideoHostScraper {
  final Dio _dio;

  StreamrubyScraper(this._dio);

  @override
  String get name => 'StreamRuby';

  @override
  List<String> get domains => [
        'streamruby.com',
        'sruby.xyz',
        'rubystream.xyz',
        'tuktukcimamulti.buzz',
        'stmruby.com',
        'rubystm.com',
        'rubyvid.com'
      ];

  static const String _pattern =
      r'''sources:\s*\[(?:\{src:|\{file:)?\s*['"]([^'"]+)''';

  String _getPackedData(String html) {
    String packedData = '';
    final packedRegex = RegExp(
      r'''(eval\s*\(function\(p,a,c,k,e,.*?)</script>''',
      multiLine: true,
      caseSensitive: false,
      dotAll: true,
    );

    for (final match in packedRegex.allMatches(html)) {
      final r = match.group(1) ?? '';
      final evalMatches = RegExp(
        r'''(eval\s*\(function\(p,a,c,k,e,)''',
        multiLine: true,
        caseSensitive: false,
        dotAll: true,
      ).allMatches(r).toList();

      if (evalMatches.length == 1) {
        if (r.contains('eval(function(p,a,c,k,e,')) {
          packedData += _unpackJs(r);
        }
      } else {
        final parts = r.split('eval');
        for (int i = 1; i < parts.length; i++) {
          final evalPart = 'eval${parts[i]}';
          if (evalPart.contains('eval(function(p,a,c,k,e,')) {
            packedData += _unpackJs(evalPart);
          }
        }
      }
    }
    return packedData;
  }

  String _unpackJs(String packed) {
    try {
      final regex = RegExp(r"}\('(.+)',(\d+),(\d+),'(.+)'\.split\('\|'\)");
      final match = regex.firstMatch(packed);
      if (match != null) {
        final payload = match.group(1) ?? '';
        final radix = int.tryParse(match.group(2) ?? '36') ?? 36;
        final count = int.tryParse(match.group(3) ?? '0') ?? 0;
        final keywords = (match.group(4) ?? '').split('|');

        return _decode(payload, radix, count, keywords);
      }
    } catch (e) {
      debugPrint('Błąd podczas rozpakowywania JS: $e');
    }
    return '';
  }

  String _decode(String payload, int radix, int count, List<String> keywords) {
    String result = payload;
    for (int i = count - 1; i >= 0; i--) {
      final keyword = keywords.length > i ? keywords[i] : '';
      if (keyword.isNotEmpty) {
        final pattern = '\\b${i.toRadixString(radix)}\\b';
        result = result.replaceAll(RegExp(pattern), keyword);
      }
    }
    return result;
  }

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final uri = Uri.parse(url);
      final baseUrl = 'https://${uri.host}/';

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:92.0) Gecko/20100101 Firefox/92.0',
            'Accept-Language': 'en-US,en;q=0.5',
          },
        ),
      );

      String html = response.data.toString();
      html += _getPackedData(html);

      final regex = RegExp(_pattern);
      final match = regex.firstMatch(html);

      if (match == null || match.group(1) == null) {
        return null;
      }

      final streamUrl = match.group(1)!;

      return VideoSource(
        url: streamUrl,
        lang: lang,
        quality: quality,
        host: name,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:92.0) Gecko/20100101 Firefox/92.0',
          'Origin': baseUrl.substring(0, baseUrl.length - 1),
          'Referer': baseUrl,
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła z StreamRuby($url): $e');
      return null;
    }
  }
}
