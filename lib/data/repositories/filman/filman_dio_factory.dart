import 'package:dio/dio.dart';
import 'package:purevideo/core/error/filman.dart';
import 'package:purevideo/data/models/account_model.dart';

class FilmanDioFactory {
  static Dio getDio([AccountModel? account]) {
    return Dio(
        BaseOptions(
          baseUrl: 'https://filman.cc',
          followRedirects: false,
          validateStatus: (_) => true,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            if (account != null) 'Cookie': account.cookies.join('; '),
          },
        ),
      )
      ..interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            if (response.headers.map['location']?.contains(
                  "https://filman.cc/logowanie",
                ) ==
                true) {
              throw FilmanAuthException("Przekierowano na stronę logowania");
            }

            return handler.next(response);
          },
        ),
      );
  }
}
