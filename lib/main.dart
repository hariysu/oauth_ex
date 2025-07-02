import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _appLinks.allUriLinkStream.listen((Uri? uri) {
      print("sample");
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
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(
                'https://ekapv2.kik.gov.tr/authzsvc/EkapAccount/RedirectEdevletLogin?returnUrl=uygulama://edevlet-callback',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.inAppBrowserView);
              } else {
                throw 'Could not launch $url';
              }
            },
            child: Text('Go to URL'),
          ),
        ),
      ),
    );
  }
}
