// Generates padded branding source images from assets/images/app_logo.png.
//
// Outputs (consumed by flutter_launcher_icons / flutter_native_splash):
//   assets/images/branding/app_icon.png            – white bg, padded (iOS + legacy Android)
//   assets/images/branding/app_icon_foreground.png – transparent, extra padding (adaptive fg)
//   assets/images/branding/splash_logo.png         – transparent, centered (native splash)
//
// Run: dart run tool/generate_branding_images.dart
import 'dart:io';

import 'package:image/image.dart' as img;

/// Fits [logo] (aspect-preserving) into a [canvasSize] square, centered, with
/// the logo occupying [contentFraction] of the canvas. Optionally fills a
/// solid [background]; otherwise the canvas stays transparent.
img.Image _composePadded(
  img.Image logo, {
  required int canvasSize,
  required double contentFraction,
  img.Color? background,
}) {
  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  if (background != null) {
    img.fill(canvas, color: background);
  }

  final box = canvasSize * contentFraction;
  final scale = box / (logo.width > logo.height ? logo.width : logo.height);
  final targetW = (logo.width * scale).round();
  final targetH = (logo.height * scale).round();

  final resized = img.copyResize(
    logo,
    width: targetW,
    height: targetH,
    interpolation: img.Interpolation.cubic,
  );

  img.compositeImage(
    canvas,
    resized,
    dstX: ((canvasSize - targetW) / 2).round(),
    dstY: ((canvasSize - targetH) / 2).round(),
  );
  return canvas;
}

void main() {
  const src = 'assets/images/app_logo.png';
  const outDir = 'assets/images/branding';

  final logo = img.decodePng(File(src).readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Failed to decode $src');
    exit(1);
  }

  Directory(outDir).createSync(recursive: true);
  final white = img.ColorRgba8(255, 255, 255, 255);

  final appIcon = _composePadded(
    logo,
    canvasSize: 1024,
    contentFraction: 0.78,
    background: white,
  );
  File('$outDir/app_icon.png').writeAsBytesSync(img.encodePng(appIcon));

  // Adaptive foreground: flutter_launcher_icons adds a further 16% inset, so
  // this fraction is intentionally modest — the full scanner frame (incl. the
  // red accent corner) must stay inside the circular-mask safe zone uncropped.
  final foreground = _composePadded(
    logo,
    canvasSize: 432,
    contentFraction: 0.66,
  );
  File(
    '$outDir/app_icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  final splash = _composePadded(
    logo,
    canvasSize: 384,
    contentFraction: 0.80,
  );
  File('$outDir/splash_logo.png').writeAsBytesSync(img.encodePng(splash));

  stdout.writeln('Generated branding images in $outDir/');
}
