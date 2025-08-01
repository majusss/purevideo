import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purevideo/core/utils/global_context.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum SupportedCaptchaService { recaptcha, turnstile }

class CaptchaResponseModel {
  final String? token;
  final Map<String, String>? cookies;

  CaptchaResponseModel({this.token, this.cookies});
}

class CaptchaService {
  final completer = Completer<CaptchaResponseModel?>();

  Future<CaptchaResponseModel?> getToken(
      SupportedCaptchaService service, String siteKey, String url) async {
    showDialog(
        context: getIt<GlobalContext>().context,
        builder: (context) =>
            _buildCaptchaDialog(context, service, siteKey, url));

    return completer.future;
  }

  Widget _buildCaptchaDialog(BuildContext context,
      SupportedCaptchaService service, String siteKey, String url) {
    switch (service) {
      case SupportedCaptchaService.recaptcha:
        return _buildReCaptchaDialog(context, siteKey, url);
      // case SupportedCaptchaService.hcaptcha:
      //   return _buildHcaptchaDialog(siteKey, url);
      case SupportedCaptchaService.turnstile:
        return _buildTurnstileDialog(context, siteKey, url);
    }
  }

  String _getReCaptchaHtml(String siteKey, String languageCode) => '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://recaptcha.google.com/recaptcha/api.js?explicit&hl=$languageCode"></script>
        <script type="text/javascript">
          function onDataCallback(response) {
            window.flutter_inappwebview.callHandler('messageHandler', response);
          }
          function onCancel() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'cancel');
          }
          function onDataExpiredCallback() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'expired');
          }
          function onDataErrorCallback() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'error');
          }
        </script>
        <style>
          body {
            margin: 0;
            padding: 0;
            background-color: transparent;
          }
          #captcha {
            text-align: center;
            padding-top: 100px;
            background-color: transparent;
          }
        </style>
      </head>
      <body>
        <div id="captcha">
          <div class="g-recaptcha" 
               style="display: inline-block; height: auto;" 
               data-sitekey="$siteKey" 
               data-callback="onDataCallback"
               data-expired-callback="onDataExpiredCallback"
               data-error-callback="onDataErrorCallback">
          </div>
        </div>
      </body>
    </html>
  ''';

  Widget _buildReCaptchaDialog(
      BuildContext context, String siteKey, String url) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: InAppWebView(
          shouldOverrideUrlLoading: (final controller, final request) async {
            return NavigationActionPolicy.CANCEL;
          },
          initialData: InAppWebViewInitialData(
            data: _getReCaptchaHtml(siteKey, 'pl'),
            baseUrl: WebUri(url),
          ),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            supportZoom: false,
            disableContextMenu: true,
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
          ),
          onWebViewCreated: (final InAppWebViewController controller) {
            controller.addJavaScriptHandler(
              handlerName: 'messageHandler',
              callback: (final message) {
                if (message[0] is String) {
                  completer.complete(
                      CaptchaResponseModel(token: message[0] as String));
                  Navigator.of(context).pop();
                } else {
                  return _showErrorDialog(context, controller);
                }
              },
            );
          },
        ),
      ),
    );
  }

  String _getTurnstileHtml(String siteKey) => '''
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=turnstileOnLoad" async defer></script>
      <style>
        body {
          margin: 0;
          padding: 0;
          background-color: transparent;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
        }
        #turnstile {
          display: inline-block;
        }
      </style>
    </head>
    <body>
      <div id="center"></div>
      <script>
        window.turnstileOnLoad = function () {
          turnstile.render("#center", {
            sitekey: "$siteKey",
            callback: function (token) {
              window.flutter_inappwebview.callHandler("messageHandler", token, document.cookie);
            },
          });
        };
      </script>
    </body>
  </html>
  ''';

  Widget _buildTurnstileDialog(
      BuildContext context, String siteKey, String url) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: InAppWebView(
          shouldOverrideUrlLoading: (final controller, final request) async {
            return NavigationActionPolicy.CANCEL; // block navigation
          },
          initialData: InAppWebViewInitialData(
            data: _getTurnstileHtml(siteKey),
            baseUrl: WebUri(url),
          ),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            supportZoom: false,
            disableContextMenu: true,
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
            javaScriptEnabled: true,
            domStorageEnabled: true,
          ),
          onWebViewCreated: (final InAppWebViewController controller) {
            controller.addJavaScriptHandler(
              handlerName: 'messageHandler',
              callback: (final message) {
                if (message.isNotEmpty &&
                    message[0] is String &&
                    message[0] != null) {
                  String? token = message[0] as String?;
                  Map<String, String>? cookies;
                  if (message.length > 1 && message[1] is String) {
                    cookies = Map<String, String>.from(
                        Uri.splitQueryString(message[1] as String));
                  }
                  debugPrint('Turnstile token: $token, cookies: $cookies',
                      wrapWidth: 1024);
                  if (token != null && token.isNotEmpty) {
                    completer.complete(
                        CaptchaResponseModel(token: token, cookies: cookies));
                    Navigator.of(context).pop();
                  } else {
                    _showErrorDialog(context, controller);
                  }
                } else {
                  _showErrorDialog(context, controller);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<dynamic> _showErrorDialog(
      BuildContext context, InAppWebViewController controller) {
    return showDialog(
      context: context,
      builder: (final context) {
        return AlertDialog(
          title: const Text('Błąd'),
          content: const Text(
            'Wystąpił błąd podczas weryfikacji captcha.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.reload();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
