import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import 'package:purevideo/core/error/exceptions.dart';
import 'package:purevideo/core/services/webview_service.dart';
import 'package:purevideo/core/utils/supported_enum.dart';
import 'package:purevideo/data/models/account_model.dart';
import 'package:purevideo/data/repositories/auth_repository.dart';
import 'package:purevideo/di/injection_container.dart';

class FilmanDioFactory {
  static Dio getDio([AccountModel? account]) {
    final dio = Dio(
      BaseOptions(
        baseUrl: SupportedService.filman.baseUrl,
        followRedirects: false,
        validateStatus: (_) => true,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
          if (account != null) 'Cookie': account.cookies.join('; '),
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          if (response.data.toString().contains('Just a moment...')) {
            final cookies = await getIt<WebViewService>().getCfCookies(
              response.requestOptions.uri.toString(),
              initialCookies: response.requestOptions.headers['Cookie'],
            );
            final requestOptions = response.requestOptions;
            requestOptions.headers['Cookie'] = cookies;
            final newResponse = await dio.fetch(requestOptions);
            newResponse.headers['Set-Cookie']
                ?.addAll(cookies?.split('; ') as Iterable<String>);
            // TODO: make this code cleaner
            final cfClearance = cookies?.split('; ').firstWhereOrNull(
                  (cookie) => cookie.startsWith('cf_clearance='),
                );
            if (cfClearance != null) {
              final authRepository =
                  getIt<Map<SupportedService, AuthRepository>>()[
                      SupportedService.filman];
              final account = authRepository?.getAccount();
              if (account != null) {
                final cookies = account.cookies.map((cookie) {
                  if (cookie.startsWith('cf_clearance=')) {
                    return cfClearance;
                  }
                  return cookie;
                }).toList();

                authRepository?.setAccount(AccountModel(
                  service: SupportedService.filman,
                  fields: account.fields,
                  cookies: cookies,
                ));
              }
            }
            return handler.next(newResponse);
          }
          if (response.headers.map['location']?.contains(
                'https://filman.cc/logowanie',
              ) ==
              true) {
            throw const UnauthorizedException();
          }
          return handler.next(response);
        },
      ),
    );
    return dio;
  }
}
