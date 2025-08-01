import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class FileMoonScraper extends VideoHostScraper {
  final Dio _dio;

  FileMoonScraper(this._dio);

  @override
  String get name => 'FileMoon';

  static const String _postDataPattern = r'var\s*postData\s*=\s*(\{.+?\})';
  static const String _sourcesPattern = r'sources:\s*\[{\s*file:\s*"([^"]+)';

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
      if (r.contains('eval(function(p,a,c,k,e,')) {
        packedData += _unpackJs(r);
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

  String _tearDecode(String dataFile, String dataSeed) {
    if (dataSeed.isEmpty || dataFile.isEmpty) {
      return '';
    }

    try {
      // Replacer dla cyfr zgodnie z Python
      final replacedSeed = dataSeed.replaceAllMapped(
        RegExp(r'[012567]'),
        (match) {
          const chars = {
            '0': '5',
            '1': '6',
            '2': '7',
            '5': '0',
            '6': '1',
            '7': '2'
          };
          return chars[match.group(0)] ?? match.group(0)!;
        },
      );

      final newDataSeed = _binaryDigest(replacedSeed);
      final newDataFile = _ascii2Binary(dataFile);

      int a69 = 0;
      final a70 = newDataFile.length;
      List<int> a71 = [1633837924, 1650680933];
      final List<int> a74 = [];

      while (a69 < a70) {
        final List<int> a73 = [newDataFile[a69], newDataFile[a69 + 1]];
        a69 += 2;

        final a72 = _xorBlocks(a71, _teaDecode(a73, newDataSeed));
        a74.addAll(a72);
        a71 = [a73[0], a73[1]];
      }

      final result = _bytes2Str(_unpad(_blocks2Bytes(a74)));

      // Drugi replacer
      return result.replaceAllMapped(
        RegExp(r'[012567]'),
        (match) {
          const chars = {
            '0': '5',
            '1': '6',
            '2': '7',
            '5': '0',
            '6': '1',
            '7': '2'
          };
          return chars[match.group(0)] ?? match.group(0)!;
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas dekodowania tear_decode: $e');
      return '';
    }
  }

  List<int> _str2Bytes(String str) {
    return str.codeUnits;
  }

  String _bytes2Str(List<int> bytes) {
    return String.fromCharCodes(bytes.where((b) => b != 0));
  }

  List<int> _digestPad(List<int> data) {
    final result = <int>[];
    final a43 = 15 - (data.length % 16);
    result.add(a43);
    result.addAll(data);

    for (int i = 0; i < a43; i++) {
      result.add(0);
    }
    return result;
  }

  List<int> _blocks2Bytes(List<int> blocks) {
    final result = <int>[];

    for (final block in blocks) {
      result.add(255 & (block >> 24));
      result.add(255 & (block >> 16));
      result.add(255 & (block >> 8));
      result.add(255 & block);
    }
    return result;
  }

  List<int> _bytes2Blocks(List<int> bytes) {
    final result = <int>[];

    for (int i = 0; i < bytes.length; i += 4) {
      int block = (255 & bytes[i]) << 24;
      if (i + 1 < bytes.length) block |= (255 & bytes[i + 1]) << 16;
      if (i + 2 < bytes.length) block |= (255 & bytes[i + 2]) << 8;
      if (i + 3 < bytes.length) block |= (255 & bytes[i + 3]);
      result.add(block);
    }
    return result;
  }

  List<int> _xorBlocks(List<int> a, List<int> b) {
    return [a[0] ^ b[0], a[1] ^ b[1]];
  }

  List<int> _unpad(List<int> data) {
    if (data.isEmpty) return [];

    final padLength = 7 & data[0];
    final endIndex = data.length - padLength;

    return data.sublist(1, endIndex > 1 ? endIndex : 1);
  }

  List<int> _teaCode(List<int> data, List<int> key) {
    int a85 = data[0];
    int a83 = data[1];
    int a87 = 0;

    for (int i = 0; i < 32; i++) {
      a85 = _toInt32(
          a85 + ((((a83 << 4) ^ (a83 >> 5)) + a83) ^ (a87 + key[a87 & 3])));
      a87 = _toInt32(a87 - 1640531527);
      a83 = _toInt32(a83 +
          ((((a85 << 4) ^ (a85 >> 5)) + a85) ^ (a87 + key[(a87 >> 11) & 3])));
    }

    return [a85, a83];
  }

  List<int> _teaDecode(List<int> data, List<int> key) {
    int a95 = data[0];
    int a96 = data[1];
    int a97 = -957401312;

    for (int i = 0; i < 32; i++) {
      a96 = _toInt32(a96 -
          ((((a95 << 4) ^ (a95 >> 5)) + a95) ^ (a97 + key[(a97 >> 11) & 3])));
      a97 = _toInt32(a97 + 1640531527);
      a95 = _toInt32(
          a95 - ((((a96 << 4) ^ (a96 >> 5)) + a96) ^ (a97 + key[a97 & 3])));
    }

    return [a95, a96];
  }

  int _toInt32(int value) {
    return (value << 32) >> 32;
  }

  List<int> _binaryDigest(String input) {
    final a63 = [1633837924, 1650680933, 1667523942, 1684366951];
    List<int> a62 = [1633837924, 1650680933];
    List<int> a61 = [1633837924, 1650680933];

    final a59 = _bytes2Blocks(_digestPad(_str2Bytes(input)));

    for (int i = 0; i < a59.length; i += 4) {
      final a66 = [a59[i], a59[i + 1]];
      final a68 = [a59[i + 2], a59[i + 3]];

      a62 = _teaCode(_xorBlocks(a66, a62), a63);
      a61 = _teaCode(_xorBlocks(a68, a61), a63);

      final a64 = a62[0];
      a62[0] = a62[1];
      a62[1] = a61[0];
      a61[0] = a61[1];
      a61[1] = a64;
    }

    return [a62[0], a62[1], a61[0], a61[1]];
  }

  List<int> _ascii2Bytes(String input) {
    const a2b = {
      'A': 0,
      'B': 1,
      'C': 2,
      'D': 3,
      'E': 4,
      'F': 5,
      'G': 6,
      'H': 7,
      'I': 8,
      'J': 9,
      'K': 10,
      'L': 11,
      'M': 12,
      'N': 13,
      'O': 14,
      'P': 15,
      'Q': 16,
      'R': 17,
      'S': 18,
      'T': 19,
      'U': 20,
      'V': 21,
      'W': 22,
      'X': 23,
      'Y': 24,
      'Z': 25,
      'a': 26,
      'b': 27,
      'c': 28,
      'd': 29,
      'e': 30,
      'f': 31,
      'g': 32,
      'h': 33,
      'i': 34,
      'j': 35,
      'k': 36,
      'l': 37,
      'm': 38,
      'n': 39,
      'o': 40,
      'p': 41,
      'q': 42,
      'r': 43,
      's': 44,
      't': 45,
      'u': 46,
      'v': 47,
      'w': 48,
      'x': 49,
      'y': 50,
      'z': 51,
      '0': 52,
      '1': 53,
      '2': 54,
      '3': 55,
      '4': 56,
      '5': 57,
      '6': 58,
      '7': 59,
      '8': 60,
      '9': 61,
      '-': 62,
      '_': 63
    };

    final result = <int>[];
    int a6 = -1;
    final a7 = input.length;
    int a9 = 0;

    while (true) {
      // Znajdź pierwszy prawidłowy znak
      do {
        a6++;
        if (a6 >= a7) return result;
      } while (!a2b.containsKey(input[a6]));

      result.add(_toInt32(a2b[input[a6]]! << 2));

      // Znajdź drugi prawidłowy znak
      do {
        a6++;
        if (a6 >= a7) return result;
      } while (!a2b.containsKey(input[a6]));

      int a3 = a2b[input[a6]]!;
      result[a9] |= a3 >> 4;
      a9++;
      a3 = 15 & a3;

      if (a3 == 0 && a6 == (a7 - 1)) return result;
      result.add(_toInt32(a3 << 4));

      // Znajdź trzeci prawidłowy znak
      do {
        a6++;
        if (a6 >= a7) return result;
      } while (!a2b.containsKey(input[a6]));

      a3 = a2b[input[a6]]!;
      result[a9] |= a3 >> 2;
      a9++;
      a3 = 3 & a3;

      if (a3 == 0 && a6 == (a7 - 1)) return result;
      result.add(_toInt32(a3 << 6));

      // Znajdź czwarty prawidłowy znak
      do {
        a6++;
        if (a6 >= a7) return result;
      } while (!a2b.containsKey(input[a6]));

      result[a9] |= a2b[input[a6]]!;
      a9++;
    }
  }

  List<int> _ascii2Binary(String input) {
    return _bytes2Blocks(_ascii2Bytes(input));
  }

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      final mediaId = uri.pathSegments.last.split('/').first;

      String webUrl = 'https://$host/e/$mediaId';

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0',
        'Cookie': '__ddg1_=PZYJSmASXDCQGP6auJU9; __ddg2_=hxAe1bBqtlYhVSik',
      };

      var response = await _dio.get(
        webUrl,
        options: Options(headers: headers),
      );

      String html = response.data.toString();

      // Sprawdź czy strona nie została znaleziona i spróbuj /d/ zamiast /e/
      if (html.contains('<h1>Page not found</h1>') ||
          html.contains(
              '<h1>This video cannot be watched under this domain</h1>')) {
        webUrl = webUrl.replaceAll('/e/', '/d/');
        response = await _dio.get(
          webUrl,
          options: Options(headers: headers),
        );
        html = response.data.toString();
      }

      // Sprawdź czy jest iframe redirect
      final iframeMatch = RegExp(r'<iframe\s*src="([^"]+)').firstMatch(html);
      if (iframeMatch != null) {
        webUrl = iframeMatch.group(1)!;
        final updatedHeaders = Map<String, String>.from(headers);
        updatedHeaders.addAll({
          'accept-language': 'en-US,en;q=0.9',
          'sec-fetch-dest': 'iframe',
          'Referer': webUrl,
        });

        response = await _dio.get(
          webUrl,
          options: Options(headers: updatedHeaders),
        );
        html = response.data.toString();
      }

      // Dodaj rozpakowane dane JS
      html += _getPackedData(html);

      // Pierwsza metoda: postData z tear_decode
      final postDataMatch =
          RegExp(_postDataPattern, dotAll: true).firstMatch(html);
      if (postDataMatch != null) {
        final postDataStr = postDataMatch.group(1)!;

        final bMatch = RegExp(r"b:\s*'([^']+)").firstMatch(postDataStr);
        final fileCodeMatch =
            RegExp(r"file_code:\s*'([^']+)").firstMatch(postDataStr);
        final hashMatch = RegExp(r"hash:\s*'([^']+)").firstMatch(postDataStr);

        if (bMatch != null && fileCodeMatch != null && hashMatch != null) {
          final postData = {
            'b': bMatch.group(1)!,
            'file_code': fileCodeMatch.group(1)!,
            'hash': hashMatch.group(1)!,
          };

          final postHeaders = Map<String, String>.from(headers);
          postHeaders.addAll({
            'Referer': webUrl,
            'Origin': Uri.parse(webUrl).origin,
            'X-Requested-With': 'XMLHttpRequest',
            'Content-Type': 'application/x-www-form-urlencoded',
          });

          final postResponse = await _dio.post(
            '${Uri.parse(webUrl).origin}/dl',
            data: postData,
            options: Options(
              headers: postHeaders,
              contentType: Headers.formUrlEncodedContentType,
            ),
          );

          final responseData = json.decode(postResponse.data.toString());
          if (responseData is List && responseData.isNotEmpty) {
            final firstItem = responseData[0];
            final encodedFile = firstItem['file'];
            final seed = firstItem['seed'];

            if (encodedFile != null && seed != null) {
              final decodedUrl = _tearDecode(encodedFile, seed);
              if (decodedUrl.isNotEmpty) {
                final videoHeaders = Map<String, String>.from(headers);
                videoHeaders.remove('Cookie');
                videoHeaders.remove('X-Requested-With');
                videoHeaders.addAll({
                  'Referer': webUrl,
                  'Origin': Uri.parse(webUrl).origin,
                });

                return VideoSource(
                  url: decodedUrl,
                  lang: lang,
                  quality: quality,
                  host: name,
                  headers: videoHeaders,
                );
              }
            }
          }
        }
      }

      // Druga metoda: bezpośredni sources regex
      final sourcesMatch =
          RegExp(_sourcesPattern, dotAll: true).firstMatch(html);
      if (sourcesMatch != null) {
        final videoUrl = sourcesMatch.group(1)!;

        final videoHeaders = Map<String, String>.from(headers);
        videoHeaders.remove('Cookie');
        videoHeaders.addAll({
          'Referer': webUrl,
          'Origin': Uri.parse(webUrl).origin,
        });

        return VideoSource(
          url: videoUrl,
          lang: lang,
          quality: quality,
          host: name,
          headers: videoHeaders,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła z FileMoon($url): $e');
      return null;
    }
  }

  @override
  List<String> get domains => [
        'filemoon.sx',
        'filemoon.to',
        'filemoon.in',
        'filemoon.link',
        'filemoon.nl',
        'filemoon.wf',
        'cinegrab.com',
        'filemoon.eu',
        'filemoon.art',
        'moonmov.pro',
        'kerapoxy.cc',
        'furher.in',
        '1azayf9w.xyz',
        '81u6xl9d.xyz',
        'smdfs40r.skin',
        'bf0skv.org',
        'z1ekv717.fun',
        'l1afav.net',
        '222i8x.lol',
        '8mhlloqo.fun',
        '96ar.com',
        'xcoic.com',
        'f51rm.com',
        'c1z39.com'
      ];
}
