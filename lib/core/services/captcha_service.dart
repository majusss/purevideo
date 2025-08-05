import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purevideo/core/utils/global_context.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum CaptchaServiceProvider { recaptcha, turnstile }

class CaptchaConfig {
  final CaptchaServiceProvider service;
  final String siteKey;
  final bool isInvisible;

  CaptchaConfig(
      {required this.service,
      required this.siteKey,
      required this.isInvisible});
}

class CaptchaService {
  final completer = Completer<String?>();

  Future<String?> getToken(CaptchaConfig config, String url) async {
    final Completer<String?> tokenCompleter = Completer<String?>();

    showDialog(
        context: getIt<GlobalContext>().context,
        builder: (context) =>
            _buildCaptchaDialog(context, config, url, tokenCompleter));

    return tokenCompleter.future;
  }

  Widget _buildCaptchaDialog(BuildContext context, CaptchaConfig config,
      String url, Completer<String?> completer) {
    switch (config.service) {
      case CaptchaServiceProvider.recaptcha:
        return _buildReCaptchaDialog(
            context, config.siteKey, url, config.isInvisible, completer);
      case CaptchaServiceProvider.turnstile:
        return _buildTurnstileDialog(context, config.siteKey, url, completer);
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
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
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

  Widget _buildReCaptchaDialog(BuildContext context, String siteKey, String url,
      bool isInvisible, Completer<String?> completer) {
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
            data: isInvisible
                ? _getInvisibleRecaptchaHtml(siteKey, 'pl')
                : _getReCaptchaHtml(siteKey, 'pl'),
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
                if (message.isNotEmpty && message[0] is String) {
                  final String? token = message[0] as String?;
                  final String? errorType =
                      (message.length > 1) ? message[1] as String? : null;

                  if (token != null && token.isNotEmpty) {
                    if (!completer.isCompleted) {
                      completer.complete(token);
                      Navigator.of(context).pop();
                    }
                  } else if (errorType == 'error' ||
                      errorType == 'cancel' ||
                      errorType == 'expired') {
                    _showErrorDialog(context, controller, completer);
                  }
                } else {
                  _showErrorDialog(context, controller, completer);
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
        #center {
          display: inline-block;
          position: absolute;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
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

  Widget _buildTurnstileDialog(BuildContext context, String siteKey, String url,
      Completer<String?> completer) {
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
                  debugPrint('Turnstile token: $token', wrapWidth: 1024);
                  if (token != null && token.isNotEmpty) {
                    if (!completer.isCompleted) {
                      completer.complete(token);
                      Navigator.of(context).pop();
                    }
                  } else {
                    _showErrorDialog(context, controller, completer);
                  }
                } else {
                  _showErrorDialog(context, controller, completer);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Future<dynamic> _showErrorDialog(BuildContext context,
      InAppWebViewController controller, Completer<String?> completer) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (final dialogContext) {
        return AlertDialog(
          title: const Text('Błąd weryfikacji'),
          content: const Text(
            'Wystąpił błąd podczas weryfikacji captcha. Czy chcesz spróbować ponownie?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              },
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                controller.reload();
              },
              child: const Text('Spróbuj ponownie'),
            ),
          ],
        );
      },
    );
  }

  String _getInvisibleRecaptchaHtml(String siteKey, String languageCode) => '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://recaptcha.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit&hl=$languageCode"></script>
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            background: transparent; 
          }
          #captcha { 
            text-align: center;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
          }
        </style>
      </head>
      <body>
        <div id="captcha"></div>
        
        <script>
          var widgetId = null;
          
          function onDataCallback(token) {
            window.flutter_inappwebview.callHandler('messageHandler', token);
          }
          
          function onDataExpiredCallback() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'expired');
          }
          
          function onDataErrorCallback() {
            window.flutter_inappwebview.callHandler('messageHandler', null, 'error');
          }

          function renderInvisible() {
            try {
              widgetId = grecaptcha.render('captcha', {
                sitekey: '$siteKey',
                size: 'invisible',
                callback: onDataCallback,
                'expired-callback': onDataExpiredCallback,
                'error-callback': onDataErrorCallback
              });
              grecaptcha.execute(widgetId);
            } catch (e) {
              onDataErrorCallback();
            }
          }

          function onloadCallback() {
            renderInvisible();
          }
        </script>
      </body>
    </html>
  ''';
}
