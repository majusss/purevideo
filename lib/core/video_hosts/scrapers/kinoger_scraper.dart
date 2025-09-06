import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/export.dart';
import 'package:purevideo/core/video_hosts/video_host_scraper.dart';

class KinoGerScraper extends VideoHostScraper {
  final Dio _dio;

  KinoGerScraper(this._dio);

  @override
  String get name => 'KinoGer';

  @override
  List<String> get domains => [
        'kinoger.re',
        'shiid4u.upn.one',
        'moflix.upns.xyz',
        'player.upn.one',
        'disneycdn.net',
        'wasuytm.store',
        'ultrastream.online',
        'moflix.rpmplay.xyz',
        'tuktuk.rpmvid.com',
        'w1tv.xyz',
        'filedecrypt.link',
        'asianembed.cam',
        'videoshar.uns.bio',
        'videoland.cfd',
        'dzo.vidplayer.live'
      ];

  static const String _pattern =
      r'(?://|\.)((?:kinoger|wasuytm|ultrastream|(?:shiid4u|player)\.upn|moflix\.upns)\.(?:re|one|xyz|store|online))/#([A-Za-z0-9]+)';

  @override
  Future<VideoSource?> getVideoSource(
      String url, String lang, String quality) async {
    try {
      final regex = RegExp(_pattern);
      final match = regex.firstMatch(url);

      if (match == null || match.groupCount < 2) {
        debugPrint('Nieprawidłowy format URL dla KinoGer: $url');
        return null;
      }

      final host = match.group(1)!;
      final mediaId = match.group(2)!;
      final apiUrl = _buildApiUrl(host, mediaId);
      final referer = _getBaseUrl(url);

      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: {
            'User-Agent': _getUserAgent(),
            'Referer': referer,
          },
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode != 200 ||
          response.data == null ||
          response.data.toString().isEmpty) {
        return null;
      }

      final encryptedData = response.data.toString();
      final videoUrl = await _decryptAndExtractUrl(encryptedData);

      if (videoUrl == null) {
        return null;
      }

      return VideoSource(
        url: videoUrl,
        lang: lang,
        quality: quality,
        host: name,
        headers: {
          'User-Agent': _getUserAgent(),
          'Referer': referer,
          'Origin': referer.replaceAll('/', ''),
        },
      );
    } catch (e) {
      debugPrint('Błąd podczas pobierania źródła z KinoGer($url): $e');
      return null;
    }
  }

  String _buildApiUrl(String host, String mediaId) {
    return 'https://$host/api/v1/video?id=$mediaId';
  }

  String _getBaseUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}/';
  }

  String _getUserAgent() {
    return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115.0';
  }

  Future<String?> _decryptAndExtractUrl(String encryptedData) async {
    try {
      final hexData = encryptedData.substring(0, encryptedData.length - 1);
      final encryptedBytes = _hexToBytes(hexData);

      final key = _getDecryptionKey();
      final iv = _getDecryptionIv();

      final decryptedBytes = _decryptAesCbc(encryptedBytes, key, iv);
      final decryptedString = utf8.decode(decryptedBytes);

      final Map<String, dynamic> data = json.decode(decryptedString);

      final String? sourceUrl = data['source'] ?? data['cf'];

      if (sourceUrl != null && sourceUrl.isNotEmpty) {
        return sourceUrl;
      }

      return null;
    } catch (e) {
      debugPrint('Błąd podczas deszyfrowania danych: $e');
      return null;
    }
  }

  Uint8List _getDecryptionKey() {
    return Uint8List.fromList([
      0x6b,
      0x69,
      0x65,
      0x6d,
      0x74,
      0x69,
      0x65,
      0x6e,
      0x6d,
      0x75,
      0x61,
      0x39,
      0x31,
      0x31,
      0x63,
      0x61
    ]);
  }

  Uint8List _getDecryptionIv() {
    return Uint8List.fromList([
      0x31,
      0x32,
      0x33,
      0x34,
      0x35,
      0x36,
      0x37,
      0x38,
      0x39,
      0x30,
      0x6f,
      0x69,
      0x75,
      0x79,
      0x74,
      0x72
    ]);
  }

  Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  Uint8List _cryptAesCbc(
      bool isEncrypt, Uint8List data, Uint8List key, Uint8List iv) {
    final params = ParametersWithIV<KeyParameter>(KeyParameter(key), iv);
    final paddingParams =
        // ignore: prefer_void_to_null
        PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
            params, null);
    final cipher = CBCBlockCipher(AESEngine());
    final paddingCipher = PaddedBlockCipherImpl(PKCS7Padding(), cipher);
    paddingCipher.init(isEncrypt, paddingParams);

    return paddingCipher.process(data);
  }

  Uint8List _decryptAesCbc(
      Uint8List encryptedData, Uint8List key, Uint8List iv) {
    return _cryptAesCbc(false, encryptedData, key, iv);
  }
}
