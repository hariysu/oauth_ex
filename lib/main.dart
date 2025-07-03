import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oauth_ex/slide_to_act.dart';
import 'package:oauth_ex/webview_content.dart';

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
  bool _isSuccess = false;

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
                      builder: (context, scrollController) {
                        final content = WebViewContent(
                          onSuccess: () {
                            _handleSuccess();
                            Navigator.pop(context);
                          },
                        );

                        return Platform.isAndroid
                            ? AnimatedPadding(
                              duration: Duration(milliseconds: 100),
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              child: content,
                            )
                            : content;
                      },
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
