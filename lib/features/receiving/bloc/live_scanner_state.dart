import 'package:flutter/material.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';

enum ScannerMode { brQr, ocr, scanner }

final class LiveScannerState {
  const LiveScannerState({
    required this.scannerOption,
    required this.activeMode,
    this.enableScannerMode = false,
    this.merchandiseValue = '',
    this.latestScannedValue = '',
    this.cameraError,
    this.scanNotice,
    this.isScanning = false,
    this.isModeSwitching = false,
    this.isCameraReady = false,
    this.detectedFrame,
    this.scanToken = 0,
  });

  final ScannerOption scannerOption;
  final ScannerMode activeMode;
  final bool enableScannerMode;
  final String merchandiseValue;
  final String latestScannedValue;
  final String? cameraError;
  final String? scanNotice;
  final bool isScanning;
  final bool isModeSwitching;
  final bool isCameraReady;
  final Rect? detectedFrame;
  final int scanToken;

  bool get isBrQrMode => activeMode == ScannerMode.brQr;

  bool get isOcrMode => activeMode == ScannerMode.ocr;

  bool get isExternalScannerMode => activeMode == ScannerMode.scanner;

  bool get canUseExternalScannerMode => enableScannerMode;

  String get title {
    return switch (activeMode) {
      ScannerMode.brQr => 'BR/QR Scanner',
      ScannerMode.ocr => 'OCR Scanner',
      ScannerMode.scanner => 'Scanner',
    };
  }

  LiveScannerState copyWith({
    ScannerOption? scannerOption,
    ScannerMode? activeMode,
    bool? enableScannerMode,
    String? merchandiseValue,
    String? latestScannedValue,
    String? cameraError,
    String? scanNotice,
    bool? isScanning,
    bool? isModeSwitching,
    bool? isCameraReady,
    Rect? detectedFrame,
    int? scanToken,
    bool clearCameraError = false,
    bool clearScanNotice = false,
    bool clearDetectedFrame = false,
  }) {
    return LiveScannerState(
      scannerOption: scannerOption ?? this.scannerOption,
      activeMode: activeMode ?? this.activeMode,
      enableScannerMode: enableScannerMode ?? this.enableScannerMode,
      merchandiseValue: merchandiseValue ?? this.merchandiseValue,
      latestScannedValue: latestScannedValue ?? this.latestScannedValue,
      cameraError: clearCameraError ? null : cameraError ?? this.cameraError,
      scanNotice: clearScanNotice ? null : scanNotice ?? this.scanNotice,
      isScanning: isScanning ?? this.isScanning,
      isModeSwitching: isModeSwitching ?? this.isModeSwitching,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      detectedFrame: clearDetectedFrame
          ? null
          : detectedFrame ?? this.detectedFrame,
      scanToken: scanToken ?? this.scanToken,
    );
  }
}
