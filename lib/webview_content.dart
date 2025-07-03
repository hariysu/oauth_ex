import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewContent extends StatefulWidget {
  final VoidCallback onSuccess;
  const WebViewContent({super.key, required this.onSuccess});

  @override
  State<WebViewContent> createState() => _WebViewContentState();
}

class _WebViewContentState extends State<WebViewContent> {
  late final WebViewController controller;
  bool _hasError = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                setState(() {
                  _progress = progress / 100.0;
                });
              },
              onPageStarted: (String url) {},
              onPageFinished: (String url) {
                setState(() {
                  _progress = 1.0;
                });
              },
              onHttpError: (HttpResponseError error) {
                setState(() {
                  _hasError = true;
                });
              },
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _hasError = true;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                // Success case
                if (request.url.contains(
                  'EkapAccount/ExternalCallBack?code=',
                )) {
                  print(request.url);
                  widget.onSuccess();
                  return NavigationDecision.prevent;
                }
                // Error case
                else if (request.url.contains(
                      'EkapAccount/ExternalCallBack?error=',
                    ) ||
                    request.url.contains(
                      'EkapAccount/ExternalCallBack?error_description=',
                    )) {
                  setState(() {
                    _hasError = true;
                  });
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.parse(
              'https://ekapv2.kik.gov.tr/authzsvc/EkapAccount/RedirectEdevletLogin?',
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 24),
              Text(
                'Lütfen daha sonra tekrar deneyin',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (_progress < 1.0)
          Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(/* value: _progress */),
            ),
          ),
      ],
    );
  }
}
