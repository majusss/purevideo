import 'package:dio/dio.dart';
import 'package:purevideo/core/error/exceptions.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:html/parser.dart' as html;

class ObejrzyjtoDioFactory {
  static Dio getDio([AccountModel? account]) {
    return Dio(
      BaseOptions(
        baseUrl: SupportedService.obejrzyjto.baseUrl,
        followRedirects: false,
        validateStatus: (_) => true,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
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
                    SupportedService.obejrzyjto, 'Cloudflare error: $error');
              }
              // idk maybe should throw blocked by cf exeption?
            }

            return handler.next(response);
          },
        ),
      );
  }
}
