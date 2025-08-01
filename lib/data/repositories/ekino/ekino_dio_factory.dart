import 'package:dio/dio.dart';
import 'package:purevideo/core/error/exceptions.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:html/parser.dart' as html;

class EkinoDioFactory {
  static Dio getDio([AccountModel? account]) {
    return Dio(
      BaseOptions(
        baseUrl: SupportedService.ekino.baseUrl,
        followRedirects: false,
        validateStatus: (_) => true,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          if (account != null) 'Cookie': account.cookies.join('; '),
        },
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            if (response.data.toString().contains('cf-wrapper')) {
              final error =
                  html.parse(response.data).querySelector('.code-label')?.text;
              if (error != null) {
                throw ServiceExeption(
                    SupportedService.ekino, 'Cloudflare error: $error');
              }
              // idk maybe should throw blocked by cf exeption?
            }

            return handler.next(response);
          },
        ),
      );
  }
}
