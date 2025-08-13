import 'dart:io';

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
          if (account != null)
            'Cookie': account.cookies
                .map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; '),
        },
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          if (response.data.toString().contains('Just a moment...')) {
            final List<Cookie> initialCookies =
                (response.requestOptions.headers['Cookie'] as String?)
                        ?.split(';')
                        .map((cookie) => Cookie.fromSetCookieValue(cookie))
                        .toList() ??
                    [];

            final cookies = await getIt<WebViewService>().getCfCookies(
              response.requestOptions.uri.toString(),
              initialCookies: initialCookies,
            );
            final requestOptions = response.requestOptions;
            requestOptions.headers['Cookie'] = cookies
                ?.map((cookie) => '${cookie.name}=${cookie.value}')
                .join('; ');
            final newResponse = await dio.fetch(requestOptions);
            newResponse.headers['set-cookie']?.addAll(
              cookies?.map((cookie) => cookie.toString()).toList() ?? [],
            );

            final cfClearance = cookies
                ?.firstWhereOrNull((cookie) => cookie.name == 'cf_clearance');
            if (cfClearance != null) {
              final authRepository =
                  getIt<Map<SupportedService, AuthRepository>>()[
                      SupportedService.filman];
              final account = authRepository?.getAccount();
              if (account != null) {
                final updatedCookies = account.cookies.map((cookie) {
                  if (cookie.name == 'cf_clearance') {
                    return cfClearance;
                  }
                  return cookie;
                }).toList();

                authRepository?.setAccount(AccountModel(
                  service: SupportedService.filman,
                  fields: account.fields,
                  cookies: updatedCookies,
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
