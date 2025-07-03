import 'package:flutter/material.dart';

class SlideToAct extends StatefulWidget {
  final VoidCallback onSubmit;
  final bool isSuccess;
  const SlideToAct({
    super.key,
    required this.onSubmit,
    required this.isSuccess,
  });

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
