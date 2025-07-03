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
  bool _isSuccess = false;

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

  void _handleSuccess() {
    setState(() {
      _isSuccess = true;
    });
  }

  void _resetSlider() {
    setState(() {
      _isSuccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SlideToAct(
          onSubmit: () {
            if (MediaQuery.of(context).orientation == Orientation.landscape) {
              // Use full-screen dialog in landscape
              showDialog(
                context: context,
                builder:
                    (context) => Dialog.fullscreen(
                      child: Scaffold(
                        body: Stack(
                          children: [
                            WebViewContent(
                              onSuccess: () {
                                _handleSuccess();
                                Navigator.pop(context);
                              },
                            ),
                            Positioned(
                              top:
                                  MediaQuery.of(context).padding.top +
                                  8, // Safe area padding
                              right: 16,
                              child: FloatingActionButton.small(
                                onPressed: () => Navigator.pop(context),
                                backgroundColor: Colors.black54,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ).whenComplete(_resetSlider);
            } else {
              // Use bottom sheet in portrait
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36.0),
                    topRight: Radius.circular(36.0),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                builder:
                    (context) => DraggableScrollableSheet(
                      initialChildSize: 0.9,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      expand: false,
                      builder:
                          (context, scrollController) => WebViewContent(
                            onSuccess: () {
                              _handleSuccess();
                              Navigator.pop(context);
                            },
                          ),
                    ),
              ).whenComplete(_resetSlider);
            }
          },
          isSuccess: _isSuccess,
        ),
      ),
    );
  }
}

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
              onHttpError: (HttpResponseError error) {},
              onWebResourceError: (WebResourceError error) {
                setState(() {
                  _hasError = true;
                });
              },
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.contains(
                  'EkapAccount/ExternalCallBack?code=',
                )) {
                  print(request.url);
                  widget.onSuccess();
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

class SlideToAct extends StatefulWidget {
  final VoidCallback onSubmit;
  final bool isSuccess;
  const SlideToAct({Key? key, required this.onSubmit, required this.isSuccess})
    : super(key: key);

  @override
  State<SlideToAct> createState() => _SlideToActState();
}

class _SlideToActState extends State<SlideToAct> {
  double _dragPosition = 0.0;
  bool _completed = false;

  @override
  void didUpdateWidget(covariant SlideToAct oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSuccess && _completed) {
      setState(() {
        _completed = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = 250.0;
    final height = 76.0;
    final thumbSize = 70.0;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (_completed) return;
        setState(() {
          _dragPosition += details.delta.dx;
          _dragPosition = _dragPosition.clamp(0.0, width - thumbSize);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_completed) return;
        if (_dragPosition > width - thumbSize - 8) {
          setState(() {
            _dragPosition = width - thumbSize;
            _completed = true;
          });
          Future.delayed(const Duration(milliseconds: 300), widget.onSubmit);
        } else {
          setState(() {
            _dragPosition = 0.0;
          });
        }
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              alignment: Alignment.center,
              child: Text(
                _completed && widget.isSuccess ? 'Başarılı!' : 'Giriş Yap',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              left: _dragPosition,
              top: 4,
              child: Container(
                width: thumbSize,
                height: thumbSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(thumbSize / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/e-devlet.png'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
