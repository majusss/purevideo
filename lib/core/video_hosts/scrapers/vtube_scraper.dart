import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

// TODO: dead now?
class VtubeScraper extends VideoHostScraper {
  final Dio _dio;

  VtubeScraper(this._dio);

  @override
  String get name => 'Vtube';

  @override
  List<String> get domains =>
      ['vtube.to', 'vtplay.net', 'vtbe.net', 'vtbe.to', 'vtube.network'];

  String _deobfuscate(String p, final int a, int c, final List<String> k) {
    while (c-- > 0) {
      if (k[c] != '') {
        p = p.replaceAll(RegExp('\\b${c.toRadixString(a)}\\b'), k[c]);
      }
    }
    return p;
  }

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Referer': 'https://filman.cc/',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      final jsLineMatch = RegExp(
        r"(?<=<script type='text\/javascript'>eval\()(.*)(?=\)<\/script>)",
      ).firstMatch(response.data.toString().replaceAll('\n', ''));

      if (jsLineMatch == null || jsLineMatch.group(0) == null) {
        return null;
      }

      final String jsLine = jsLineMatch.group(0)!;

      final removeStart = jsLine.replaceAll(
        "function(p,a,c,k,e,d){while(c--)if(k[c])p=p.replace(new RegExp('\\\\b'+c.toString(a)+'\\\\b','g'),k[c]);return p}(",
        '',
      );

      final removeEnd = removeStart.substring(0, removeStart.length - 1);
      final firstArgMatch =
          RegExp(r"'([^'\\]*(?:\\.[^'\\]*)*)'").firstMatch(removeEnd);

      if (firstArgMatch == null || firstArgMatch.group(0) == null) {
        return null;
      }

      final firstArg = firstArgMatch.group(0)!;
      final stringWithoutFirstArg = removeEnd.replaceFirst(firstArg, '');
      final normalizedArgs =
          stringWithoutFirstArg.split(',').where((i) => i.isNotEmpty);

      final int secondArg = int.parse(normalizedArgs.first);
      final int thirdArg = int.parse(normalizedArgs.elementAt(1));
      final fourthArg = normalizedArgs
          .elementAt(2)
          .replaceAll(".split('|')", '')
          .replaceAll("'", '')
          .split('|');

      final String decoded =
          _deobfuscate(firstArg, secondArg, thirdArg, fourthArg);
      final directLink = decoded
          .split('jwplayer(\\"vplayer\\").setup({sources:[{file:\\"')[1]
          .split('\\"')[0];

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
      debugPrint('Błąd podczas pobierania źródła z Vtube: $e');
      return null;
    }
  }
}
