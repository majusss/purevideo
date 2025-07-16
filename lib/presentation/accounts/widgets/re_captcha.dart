import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoogleReCaptcha extends StatefulWidget {
  final String siteKey;
  final String url;
  final String languageCode;
  final Function(String) onToken;

  const GoogleReCaptcha({
    super.key,
    required this.siteKey,
    required this.url,
    this.languageCode = 'pl',
    required this.onToken,
  });

  @override
  State<GoogleReCaptcha> createState() => _GoogleReCaptchaState();
}

class _GoogleReCaptchaState extends State<GoogleReCaptcha> {
  String? _captchaToken;

  void _showCaptchaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.zero,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: _GoogleReCaptchaView(
                siteKey: widget.siteKey,
                url: widget.url,
                languageCode: widget.languageCode,
                onToken: (token) {
                  Navigator.of(context).pop();
                  setState(() {
                    _captchaToken = token;
                  });
                  widget.onToken(token);
                },
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _captchaToken != null
        ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Captcha zweryfikowana'),
          ],
        )
        : ElevatedButton(
          onPressed: _showCaptchaDialog,
          child: const Text('Weryfikuj Captcha'),
        );
  }
}

class _GoogleReCaptchaView extends StatelessWidget {
  final String siteKey;
  final String url;
  final String languageCode;
  final Function(String) onToken;

  const _GoogleReCaptchaView({
    required this.siteKey,
    required this.url,
    required this.languageCode,
    required this.onToken,
  });

  String _getHtmlContent() => '''
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

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return _buildDesktopCaptcha(context);
    }
    return _buildMobileCaptcha(context);
  }

  Widget _buildMobileCaptcha(BuildContext context) {
    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: _getHtmlContent(),
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
              onToken(message[0]);
            } else {
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
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDesktopCaptcha(BuildContext context) {
    final TextEditingController textController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Captcha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              onToken(textController.text);
            },
            child: const Text('Zatwierdź'),
          ),
        ],
      ),
    );
  }
}

abstract class ReCaptchaEvent {
  const ReCaptchaEvent();

  List<Object> get props => [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReCaptchaEvent &&
          runtimeType == other.runtimeType &&
          props == other.props;

  @override
  int get hashCode => props.hashCode;
}

class ReCaptchaShown extends ReCaptchaEvent {
  const ReCaptchaShown();
}

class ReCaptchaHidden extends ReCaptchaEvent {
  const ReCaptchaHidden();
}

class ReCaptchaTokenSubmitted extends ReCaptchaEvent {
  final String token;

  const ReCaptchaTokenSubmitted(this.token);

  @override
  List<Object> get props => [token];
}

class ReCaptchaTokenReset extends ReCaptchaEvent {
  const ReCaptchaTokenReset();
}

class ReCaptchaState {
  final bool isVisible;
  final String? token;

  const ReCaptchaState({this.isVisible = false, this.token});

  ReCaptchaState copyWith({bool? isVisible, String? token}) {
    return ReCaptchaState(
      isVisible: isVisible ?? this.isVisible,
      token: token ?? this.token,
    );
  }

  List<Object?> get props => [isVisible, token];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReCaptchaState &&
          runtimeType == other.runtimeType &&
          isVisible == other.isVisible &&
          token == other.token;

  @override
  int get hashCode => Object.hash(isVisible, token);
}

typedef TokenCallback = void Function(String token);

class ReCaptchaBloc extends Bloc<ReCaptchaEvent, ReCaptchaState> {
  TokenCallback? _onTokenCallback;

  ReCaptchaBloc() : super(const ReCaptchaState()) {
    on<ReCaptchaShown>(_onShown);
    on<ReCaptchaHidden>(_onHidden);
    on<ReCaptchaTokenSubmitted>(_onTokenSubmitted);
    on<ReCaptchaTokenReset>(_onTokenReset);
  }

  void onToken(TokenCallback callback) {
    _onTokenCallback = callback;
  }

  void _onShown(ReCaptchaShown event, Emitter<ReCaptchaState> emit) {
    emit(state.copyWith(isVisible: true));
  }

  void _onHidden(ReCaptchaHidden event, Emitter<ReCaptchaState> emit) {
    emit(state.copyWith(isVisible: false));
  }

  void _onTokenSubmitted(
    ReCaptchaTokenSubmitted event,
    Emitter<ReCaptchaState> emit,
  ) {
    if (_onTokenCallback != null) {
      _onTokenCallback!(event.token);
    }
    emit(state.copyWith(isVisible: false, token: event.token));
  }

  void _onTokenReset(ReCaptchaTokenReset event, Emitter<ReCaptchaState> emit) {
    emit(state.copyWith(token: null));
  }

  void show() {
    add(const ReCaptchaShown());
  }

  void hide() {
    add(const ReCaptchaHidden());
  }

  void reset() {
    add(const ReCaptchaTokenReset());
  }
}
