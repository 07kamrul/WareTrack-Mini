import 'package:flutter/material.dart';

final class ScannerOverlayGeometry {
  const ScannerOverlayGeometry._();

  static const double frameWidthPercent = 0.80;
  static const double frameHeightPercent = 0.20;

  static Rect frameRectFor(Size size) {
    final frameWidth = size.width * frameWidthPercent;
    final frameHeight = size.height * frameHeightPercent;

    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: frameWidth,
      height: frameHeight,
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key, required this.isOcrMode});

  final bool isOcrMode;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScannerOverlayPainter(dimOutsideFrame: isOcrMode),
      child: const SizedBox.expand(),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  const ScannerOverlayPainter({required this.dimOutsideFrame});

  final bool dimOutsideFrame;

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 15.0;
    final frame = ScannerOverlayGeometry.frameRectFor(size);
    final frameLeft = frame.left;
    final frameTop = frame.top;
    final frameRight = frame.right;
    final frameBottom = frame.bottom;

    if (dimOutsideFrame) {
      final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.4);

      canvas
        ..drawRect(Rect.fromLTWH(0, 0, size.width, frameTop), overlayPaint)
        ..drawRect(
          Rect.fromLTWH(0, frameBottom, size.width, size.height - frameBottom),
          overlayPaint,
        )
        ..drawRect(
          Rect.fromLTWH(0, frameTop, frameLeft, frame.height),
          overlayPaint,
        )
        ..drawRect(
          Rect.fromLTWH(
            frameRight,
            frameTop,
            size.width - frameRight,
            frame.height,
          ),
          overlayPaint,
        );
    }

    final framePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(frameLeft, frameTop, frameRight, frameBottom),
      framePaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas
      ..drawLine(
        Offset(frameLeft, frameTop + cornerLength),
        Offset(frameLeft, frameTop),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameLeft, frameTop),
        Offset(frameLeft + cornerLength, frameTop),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameRight - cornerLength, frameTop),
        Offset(frameRight, frameTop),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameRight, frameTop),
        Offset(frameRight, frameTop + cornerLength),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameLeft, frameBottom - cornerLength),
        Offset(frameLeft, frameBottom),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameLeft, frameBottom),
        Offset(frameLeft + cornerLength, frameBottom),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameRight - cornerLength, frameBottom),
        Offset(frameRight, frameBottom),
        cornerPaint,
      )
      ..drawLine(
        Offset(frameRight, frameBottom - cornerLength),
        Offset(frameRight, frameBottom),
        cornerPaint,
      );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return oldDelegate.dimOutsideFrame != dimOutsideFrame;
  }
}
