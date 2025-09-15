import 'package:dio/dio.dart';

class FilmwebDioFactory {
  static Dio getDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://www.filmweb.pl/',
        followRedirects: false,
        validateStatus: (_) => true,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
        },
      ),
    );
    return dio;
  }
}
