// Generates padded trial-build branding images from assets/images/app_logo_trial.png.
//
// Mirrors tool/generate_branding_images.dart's padding/composition so the
// trial icon looks visually consistent with the standard one (same canvas
// sizes and content fractions), just sourced from the trial logo.
//
// Outputs (consumed by flutter_launcher_icons / flutter_native_splash when
// generating the trial icon + splash set — see android/app/build.gradle.kts
// trialIcons source set):
//   assets/images/branding/app_icon_trial.png            – white bg, padded (iOS + legacy Android)
//   assets/images/branding/app_icon_foreground_trial.png – transparent, extra padding (adaptive fg)
//   assets/images/branding/splash_logo_trial.png         – transparent, centered (native splash)
//
// Run: dart run tool/generate_trial_branding_images.dart
import 'dart:io';

import 'package:image/image.dart' as img;

/// Crops [source] tightly to the bounding box of its non-background pixels.
/// The trial source logo carries its own built-in white margin (unlike the
/// standard logo, which is already tightly cropped) — without this trim,
/// contentFraction below would apply on top of that existing margin and
/// compound into a visibly smaller icon.
img.Image _trimToContent(img.Image source) {
  const threshold = 250;
  var minX = source.width, minY = source.height, maxX = 0, maxY = 0;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final p = source.getPixel(x, y);
      final isBackground =
          p.a < 10 || (p.r > threshold && p.g > threshold && p.b > threshold);
      if (!isBackground) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) return source;
  return img.copyCrop(
    source,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

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
  const src = 'assets/images/app_logo_trial.png';
  const outDir = 'assets/images/branding';

  final rawLogo = img.decodePng(File(src).readAsBytesSync());
  if (rawLogo == null) {
    stderr.writeln('Failed to decode $src');
    exit(1);
  }
  final logo = _trimToContent(rawLogo);

  Directory(outDir).createSync(recursive: true);
  final white = img.ColorRgba8(255, 255, 255, 255);

  final appIcon = _composePadded(
    logo,
    canvasSize: 1024,
    contentFraction: 0.78,
    background: white,
  );
  File('$outDir/app_icon_trial.png').writeAsBytesSync(img.encodePng(appIcon));

  final foreground = _composePadded(
    logo,
    canvasSize: 432,
    contentFraction: 0.66,
  );
  File(
    '$outDir/app_icon_foreground_trial.png',
  ).writeAsBytesSync(img.encodePng(foreground));

  final splash = _composePadded(
    rawLogo,
    canvasSize: 384,
    contentFraction: 0.80,
  );
  File('$outDir/splash_logo_trial.png').writeAsBytesSync(img.encodePng(splash));

  stdout.writeln('Generated trial branding images in $outDir/');
}
