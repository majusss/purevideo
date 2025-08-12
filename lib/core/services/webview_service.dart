import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:purevideo/core/utils/global_context.dart';
import 'package:purevideo/di/injection_container.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewService {
  String _getJsCodeForElement(String elementSelector) {
    return '''
      (function() {
        function waitForElement(selector, callback) {
          const element = document.querySelector(selector);
          if (element) {
            callback(element);
          } else {
            setTimeout(() => waitForElement(selector, callback), 100);
          }
        }
        waitForElement('$elementSelector', function(element) {
          window.flutter_inappwebview.callHandler('messageHandler', element.outerHTML);
        });
        // setTimeout(() => {
        //   window.flutter_inappwebview.callHandler('messageHandler', null, 'timeout');
        // }, 15000);
      })();
    ''';
  }

  Future<dom.Element?> waitForDomElement(
      String url, String elementSelector) async {
    final completer = Completer<dom.Element?>();

    executeJavaScript(url, _getJsCodeForElement(elementSelector))
        .then((result) {
      if (result != null) {
        final document = dom.Document.html(result);
        final element = document.querySelector(elementSelector);
        completer.complete(element);
      } else {
        completer.complete(null);
      }
    }).catchError((error) {
      debugPrint('Error waiting for DOM element: $error');
      completer.complete(null);
    });

    return completer.future;
  }

  Future<String?> executeJavaScript(String url, String jsCode) async {
    final completer = Completer<String?>();

    showDialog(
      context: getIt<GlobalContext>().context,
      builder: (context) =>
          _buildWebViewDialog(context, url, jsCode, completer),
    );

    return completer.future;
  }

  Future<String?> getCfCookies(String url, {String? initialCookies}) async {
    final completer = Completer<String?>();

    showDialog(
        context: getIt<GlobalContext>().context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.zero,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                    url: WebUri(url),
                    headers: initialCookies != null
                        ? {'Cookie': initialCookies}
                        : null),
                initialSettings: InAppWebViewSettings(
                  userAgent:
                      'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
                  transparentBackground: true,
                  supportZoom: false,
                  disableContextMenu: true,
                  disableHorizontalScroll: true,
                  disableVerticalScroll: true,
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  clearCache: true,
                  cacheEnabled: false,
                  incognito: true,
                  useShouldInterceptRequest: true,
                ),
                onWebViewCreated: (controller) async {
                  await CookieManager.instance().deleteAllCookies();
                  await WebStorageManager.instance().deleteAllData();
                },
                onLoadStop: (controller, url) async {
                  try {
                    final cookies =
                        await CookieManager.instance().getCookies(url: url!);
                    final cfClearance = cookies.firstWhereOrNull(
                      (cookie) => cookie.name == 'cf_clearance',
                    );
                    if (cfClearance != null) {
                      completer.complete(cookies.map((cookie) {
                        return '${cookie.name}=${cookie.value}';
                      }).join('; '));
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showErrorDialog(context, controller, completer);
                    }
                  }
                },
              ),
            ),
          );
        });

    return completer.future;
  }

  Widget _buildWebViewDialog(BuildContext context, String url, String jsCode,
      Completer<String?> completer) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(url)),
          initialSettings: InAppWebViewSettings(
            userAgent:
                'Mozilla/5.0 (Linux; Android 16; Pixel 8 Build/BP31.250610.004; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.7204.180 Mobile Safari/537.36',
            transparentBackground: true,
            supportZoom: false,
            disableContextMenu: true,
            disableHorizontalScroll: true,
            disableVerticalScroll: true,
            javaScriptEnabled: true,
            domStorageEnabled: true,
            clearCache: true,
            cacheEnabled: false,
            incognito: true,
          ),
          onWebViewCreated: (controller) async {
            await CookieManager.instance().deleteAllCookies();
            await WebStorageManager.instance().deleteAllData();

            controller.addJavaScriptHandler(
              handlerName: 'messageHandler',
              callback: (message) {
                if (message.isNotEmpty && message[0] != null) {
                  completer.complete(message[0].toString());
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog(context, controller, completer);
                }
              },
            );
          },
          onLoadStop: (controller, url) async {
            try {
              await controller.evaluateJavascript(source: jsCode);
            } catch (e) {
              debugPrint('Błąd wykonywania JavaScript: $e');
              if (context.mounted) {
                _showErrorDialog(context, controller, completer);
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(BuildContext context,
      InAppWebViewController controller, Completer<String?> completer) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Błąd'),
          content: const Text(
            'Wystąpił błąd podczas wykonywania operacji w WebView.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                completer.complete(null);
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.reload();
              },
              child: const Text('Ponów'),
            ),
          ],
        );
      },
    );
  }
}
