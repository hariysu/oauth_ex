import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app_links/app_links.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _appLinks.allUriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        final code = uri.queryParameters['code'];
        final state = uri.queryParameters['state'];
        print('code: $code');
        print('state: $state');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder:
                  (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: WebViewContent(),
                  ),
            );
          },
          child: const Text('Go to URL'),
        ),
      ),
    );
  }
}

class WebViewContent extends StatefulWidget {
  const WebViewContent({super.key});

  @override
  State<WebViewContent> createState() => _WebViewContentState();
}

class _WebViewContentState extends State<WebViewContent> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {},
              onPageStarted: (String url) {},
              onPageFinished: (String url) {},
              onHttpError: (HttpResponseError error) {},
              onWebResourceError: (WebResourceError error) {},
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.contains(
                  'EkapAccount/ExternalCallBack?code=',
                )) {
                  print(request.url);
                  Navigator.pop(context);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.parse(
              'https://ekapv2.kik.gov.tr/authzsvc/EkapAccount/RedirectEdevletLogin?returnUrl=uygulama://edevlet-callback',
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}


/* class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // Optionally handle progress
              },
              onPageStarted: (String url) {},
              onPageFinished: (String url) {},
              onHttpError: (HttpResponseError error) {},
              onWebResourceError: (WebResourceError error) {},
              onNavigationRequest: (NavigationRequest request) {
                // E-devlet callback URL'ini yakala
                if (request.url.contains(
                  'EkapAccount/ExternalCallBack?code=',
                )) {
                  print(request.url);
                  Navigator.pop(context);
                  //_handleCallback(request.url);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(
            Uri.parse(
              'https://ekapv2.kik.gov.tr/authzsvc/EkapAccount/RedirectEdevletLogin?returnUrl=uygulama://edevlet-callback',
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebView2')),
      body: WebViewWidget(controller: controller),
    );
  }
} */