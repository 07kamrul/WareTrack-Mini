import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';

sealed class LiveScannerEvent {
  const LiveScannerEvent();
}

final class LiveScannerStarted extends LiveScannerEvent {
  const LiveScannerStarted();
}

final class LiveScannerStopped extends LiveScannerEvent {
  const LiveScannerStopped();
}

final class LiveScannerModeChanged extends LiveScannerEvent {
  const LiveScannerModeChanged(this.mode);

  final ScannerMode mode;
}

final class LiveScannerScanRequested extends LiveScannerEvent {
  const LiveScannerScanRequested();
}

final class LiveScannerSettingsChanged extends LiveScannerEvent {
  const LiveScannerSettingsChanged(this.settings);

  final ScannerSettings settings;
}

final class LiveScannerExternalValueChanged extends LiveScannerEvent {
  const LiveScannerExternalValueChanged(this.value);

  final String value;
}

final class LiveScannerOcrFrameCaptured extends LiveScannerEvent {
  const LiveScannerOcrFrameCaptured({
    required this.bitmap,
    required this.width,
    required this.height,
  });

  final Uint8List bitmap;
  final int width;
  final int height;
}

final class LiveScannerOcrCaptureFailed extends LiveScannerEvent {
  const LiveScannerOcrCaptureFailed();
}

final class LiveScannerDetectionReceived extends LiveScannerEvent {
  const LiveScannerDetectionReceived(
    this.capture, {
    this.scanWindow,
    this.previewSize,
    this.previewFit = BoxFit.cover,
  });

  final BarcodeCapture capture;
  final Rect? scanWindow;
  final Size? previewSize;
  final BoxFit previewFit;
}

final class LiveScannerDetectionFailed extends LiveScannerEvent {
  const LiveScannerDetectionFailed();
}
