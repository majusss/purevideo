import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class DoodStreamScraper extends VideoHostScraper {
  final Dio _dio;

  DoodStreamScraper(this._dio);

  @override
  String get name => 'DoodStream';

  @override
  List<String> get domains => [
        'dood.watch',
        'doodstream.com',
        'dood.to',
        'dood.so',
        'dood.cx',
        'dood.la',
        'dood.ws',
        'dood.sh',
        'doodstream.co',
        'dood.pm',
        'dood.wf',
        'dood.re',
        'dood.yt',
        'dooood.com',
        'dood.stream',
        'ds2play.com',
        'doods.pro',
        'ds2video.com',
        'd0o0d.com',
        'do0od.com',
        'd0000d.com',
        'd000d.com',
        'dood.li',
        'dood.work',
        'dooodster.com',
        'vidply.com',
        'all3do.com',
        'do7go.com',
        'doodcdn.io',
        'doply.net',
        'vide0.net',
        'vvide0.com',
        'd-s.io'
      ];

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final embedUrl = url.replaceAll('/d/', '/e/');
      final response = await _dio.get(embedUrl);

      final host = _getBaseUrl(response.redirects.last.location.toString());
      final responseText = response.data;

      final md5Match = RegExp(r"/pass_md5/[^']*").firstMatch(responseText);
      if (md5Match == null) {
        return null;
      }

      final md5 = host + md5Match.group(0)!;
      final trueResponse = await _dio.get(
        md5,
        options: Options(
          headers: {
            'Referer': host,
          },
          validateStatus: (_) => true,
        ),
      );

      final trueUrl =
          '${trueResponse.data}${_createHashTable()}?token=${md5.split("/").last}';

      return VideoSource(
        url: Uri.parse(trueUrl).toString(),
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
      debugPrint('Błąd podczas pobierania źródła z DoodStream($url): $e');
      return null;
    }
  }

  String _getBaseUrl(final String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}';
  }

  String _createHashTable() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(10, (_) => alphabet[random.nextInt(alphabet.length)])
        .join();
  }
}
