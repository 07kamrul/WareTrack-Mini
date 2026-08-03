import 'dart:async';
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/painting.dart' show Alignment, BoxFit, applyBoxFit;
import 'package:waretrack_mini/core/utils/base_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:waretrack_mini/core/constants/app_feature_flags.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/data/models/ocr_result.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/core/utils/receiving_barcode_value.dart';
import 'package:waretrack_mini/core/services/process_ocr_image_use_case.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_event.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';

class LiveScannerBloc extends BaseBloc<LiveScannerEvent, LiveScannerState> {
  LiveScannerBloc(
    ScannerOption scannerOption, {
    required AppSettingsController settingsController,
    required ScanFeedbackService scanFeedbackService,
    required ProcessOcrImageUseCase processOcrImageUseCase,
  }) : _settingsController = settingsController,
       _scanFeedbackService = scanFeedbackService,
       _processOcrImageUseCase = processOcrImageUseCase,
       _scannerOption = scannerOption,
       _scannerSettings = settingsController.settings.scanner,
       controller = _createController(
         scannerOption,
         settingsController.settings.scanner,
       ),
       super(
         LiveScannerState(
           scannerOption: scannerOption,
           activeMode: scannerOption.isOcr ? ScannerMode.ocr : ScannerMode.brQr,
           enableScannerMode: AppFeatureFlags.enableScannerMode,
         ),
       ) {
    on<LiveScannerStarted>(_onStarted);
    on<LiveScannerStopped>(_onStopped);
    on<LiveScannerModeChanged>(_onModeChanged);
    on<LiveScannerScanRequested>(_onScanRequested);
    on<LiveScannerSettingsChanged>(_onSettingsChanged);
    on<LiveScannerExternalValueChanged>(_onExternalValueChanged);
    on<LiveScannerOcrFrameCaptured>(_onOcrFrameCaptured);
    on<LiveScannerOcrCaptureFailed>(_onOcrCaptureFailed);
    on<LiveScannerDetectionReceived>(_onDetectionReceived);
    on<LiveScannerDetectionFailed>(_onDetectionFailed);
    _settingsController.addListener(_handleSettingsUpdated);
  }

  static const List<BarcodeFormat> _brQrFormats = [
    BarcodeFormat.qrCode,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.codabar,
    BarcodeFormat.dataMatrix,
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.itf2of5,
    BarcodeFormat.itf14,
    BarcodeFormat.pdf417,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.aztec,
  ];

  static List<BarcodeFormat> _scannerFormatsFor(ScannerOption scannerOption) {
    if (scannerOption.isOcr || scannerOption.formats.isEmpty) {
      return _brQrFormats;
    }

    final selectedFormats = _mapFormats(scannerOption.formats);
    if (selectedFormats.contains(BarcodeFormat.all)) {
      return const [BarcodeFormat.all];
    }

    return selectedFormats;
  }

  static List<BarcodeFormat> _mapFormats(List<ScannerFormat> formats) {
    return formats.map(_mapFormat).toSet().toList(growable: false);
  }

  static BarcodeFormat _mapFormat(ScannerFormat format) {
    return switch (format) {
      ScannerFormat.all => BarcodeFormat.all,
      ScannerFormat.code128 => BarcodeFormat.code128,
      ScannerFormat.code39 => BarcodeFormat.code39,
      ScannerFormat.code93 => BarcodeFormat.code93,
      ScannerFormat.codabar => BarcodeFormat.codabar,
      ScannerFormat.dataMatrix => BarcodeFormat.dataMatrix,
      ScannerFormat.ean13 => BarcodeFormat.ean13,
      ScannerFormat.ean8 => BarcodeFormat.ean8,
      ScannerFormat.itf2of5 => BarcodeFormat.itf2of5,
      ScannerFormat.itf14 => BarcodeFormat.itf14,
      ScannerFormat.pdf417 => BarcodeFormat.pdf417,
      ScannerFormat.upcA => BarcodeFormat.upcA,
      ScannerFormat.upcE => BarcodeFormat.upcE,
      ScannerFormat.qrCode => BarcodeFormat.qrCode,
      ScannerFormat.aztec => BarcodeFormat.aztec,
    };
  }

  static MobileScannerController _createController(
    ScannerOption scannerOption,
    ScannerSettings settings,
  ) {
    return MobileScannerController(
      autoStart: false,
      cameraResolution: const Size(1280, 720),
      formats: _scannerFormatsFor(scannerOption),
      detectionSpeed: settings.fastScanMode
          ? DetectionSpeed.unrestricted
          : DetectionSpeed.normal,
      facing: CameraFacing.back,
      autoZoom: false,
      torchEnabled: false,
    );
  }

  MobileScannerController controller;
  final AppSettingsController _settingsController;
  final ScanFeedbackService _scanFeedbackService;
  final ProcessOcrImageUseCase _processOcrImageUseCase;
  final ScannerOption _scannerOption;
  ScannerSettings _scannerSettings;
  String? _lastDetectedValue;
  DateTime? _lastDetectedAt;
  String? _candidateValue;
  BarcodeFormat? _candidateFormat;
  int _candidateHits = 0;
  Future<void>? _cameraStartFuture;
  Future<void>? _cameraStopFuture;
  Future<void>? _cameraLifecycleFuture;
  Future<void>? _closeFuture;
  CameraFacing? _resolvedCameraFacing;
  bool _isCameraServiceRunning = false;
  bool _isCameraActive = false;
  bool _isDisposingCamera = false;
  bool _isClosing = false;
  bool _isDisposed = false;
  bool _isControllerDisposed = false;
  bool _isRouteFocused = false;
  bool _needsCameraRebind = false;
  bool _isHandlingDetection = false;
  bool _isProcessingOcrFrame = false;
  int _cameraSession = 0;

  Future<void> _onStarted(
    LiveScannerStarted event,
    Emitter<LiveScannerState> emit,
  ) async {
    await _runCameraLifecycle(() async {
      await _handleStarted(event, emit);
    });
  }

  Future<void> _handleStarted(
    Object event,
    Emitter<LiveScannerState> emit,
  ) async {
    _isRouteFocused = true;

    if (state.isExternalScannerMode) {
      await _stopCamera();
      return;
    }

    await _startCamera(emit, eventId: event);
    if (!_isCameraUsable) {
      return;
    }

    if (_scannerSettings.autoScan) {
      emit(
        state.copyWith(
          isCameraReady: true,
          isScanning: true,
          scanNotice: state.isBrQrMode
              ? 'Scanning in progress'
              : 'Ready for OCR capture.',
        ),
      );
    } else {
      emit(
        state.copyWith(
          isCameraReady: true,
          isScanning: false,
          scanNotice: state.isBrQrMode ? 'Scanning stopped.' : null,
          clearDetectedFrame: true,
          clearCameraError: true,
        ),
      );
    }
  }

  Future<void> _onStopped(
    LiveScannerStopped event,
    Emitter<LiveScannerState> emit,
  ) async {
    await _runCameraLifecycle(() async {
      emit(state.copyWith(isCameraReady: false));
      await _handleStopped();
    });
  }

  Future<void> _handleStopped() async {
    _isRouteFocused = false;
    _resetDetectedCode();
    _cancelPendingFrameProcessing();
    await _stopCamera();
  }

  Future<void> _onModeChanged(
    LiveScannerModeChanged event,
    Emitter<LiveScannerState> emit,
  ) async {
    await _runCameraLifecycle(() async {
      await _handleModeChanged(event, emit);
    });
  }

  Future<void> _handleModeChanged(
    LiveScannerModeChanged event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (event.mode == ScannerMode.scanner && !state.canUseExternalScannerMode) {
      return;
    }

    if (event.mode == state.activeMode) {
      return;
    }

    emit(state.copyWith(isModeSwitching: true));

    final isExternalScannerMode = event.mode == ScannerMode.scanner;
    final wasExternalScannerMode = state.isExternalScannerMode;

    if (isExternalScannerMode) {
      _cancelPendingFrameProcessing();
      await _releaseCameraForScannerMode();
    }

    final shouldAutoScan = !isExternalScannerMode && _scannerSettings.autoScan;

    emit(
      state.copyWith(
        activeMode: event.mode,
        merchandiseValue: '',
        isModeSwitching: isExternalScannerMode ? false : true,
        isCameraReady: isExternalScannerMode ? false : state.isCameraReady,
        isScanning: isExternalScannerMode || shouldAutoScan,
        scanNotice: isExternalScannerMode
            ? 'Ready for external scanner input.'
            : shouldAutoScan
            ? event.mode == ScannerMode.brQr
                  ? 'Scanning in progress'
                  : 'Ready for OCR capture.'
            : null,
        clearScanNotice: !isExternalScannerMode && !shouldAutoScan,
        clearDetectedFrame: true,
        clearCameraError: true,
      ),
    );

    if (isExternalScannerMode) {
      return;
    }

    if (wasExternalScannerMode || _needsCameraRebind || _isControllerDisposed) {
      await _reinitializeCameraController();
      if (emit.isDone) {
        return;
      }
      emit(state.copyWith(clearCameraError: true, clearDetectedFrame: true));
    }

    await _startCamera(emit, eventId: event);
    if (!emit.isDone) {
      emit(state.copyWith(isModeSwitching: false));
    }
  }

  Future<void> _onScanRequested(
    LiveScannerScanRequested event,
    Emitter<LiveScannerState> emit,
  ) async {
    await _runCameraLifecycle(() async {
      await _handleScanRequested(event, emit);
    });
  }

  Future<void> _handleScanRequested(
    LiveScannerScanRequested event,
    Emitter<LiveScannerState> emit,
  ) async {
    _resetDetectedCode();

    if (state.isExternalScannerMode) {
      emit(
        state.copyWith(
          merchandiseValue: '',
          isScanning: true,
          scanNotice: 'Ready for external scanner input.',
          clearCameraError: true,
          clearDetectedFrame: true,
        ),
      );
      _cancelPendingFrameProcessing();
      await _stopCamera();
      return;
    }

    emit(
      state.copyWith(
        merchandiseValue: '',
        isScanning: true,
        scanNotice: state.isBrQrMode
            ? 'Scanning in progress'
            : 'Capturing OCR from the current camera preview...',
        clearCameraError: true,
        clearDetectedFrame: true,
      ),
    );

    if (controller.value.isRunning) {
      unawaited(_prepareCameraForQr());
      return;
    }

    await _startCamera(emit, eventId: event);
  }

  Future<void> _onSettingsChanged(
    LiveScannerSettingsChanged event,
    Emitter<LiveScannerState> emit,
  ) async {
    await _runCameraLifecycle(() async {
      await _handleSettingsChanged(event, emit);
    });
  }

  Future<void> _handleSettingsChanged(
    LiveScannerSettingsChanged event,
    Emitter<LiveScannerState> emit,
  ) async {
    final previousSettings = _scannerSettings;
    _scannerSettings = event.settings;

    if (previousSettings.autoScan == event.settings.autoScan) {
      return;
    }

    _resetDetectedCode();

    if (state.isExternalScannerMode) {
      emit(
        state.copyWith(
          isScanning: true,
          scanNotice: 'Ready for external scanner input.',
          clearDetectedFrame: true,
          clearCameraError: true,
        ),
      );
      _cancelPendingFrameProcessing();
      await _stopCamera();
      return;
    }

    if (event.settings.autoScan) {
      emit(
        state.copyWith(
          merchandiseValue: '',
          isScanning: true,
          scanNotice: state.isBrQrMode
              ? 'Scanning in progress'
              : 'Ready for OCR capture.',
          clearDetectedFrame: true,
          clearCameraError: true,
        ),
      );
      if (_isRouteFocused) {
        await _startCamera(emit, eventId: event);
      }
      return;
    }

    if (_isRouteFocused && !controller.value.isRunning) {
      await _startCamera(emit, eventId: event);
    }

    emit(
      state.copyWith(
        isScanning: false,
        scanNotice: 'Scanning stopped.',
        clearDetectedFrame: true,
        clearCameraError: true,
      ),
    );
  }

  Future<void> _onExternalValueChanged(
    LiveScannerExternalValueChanged event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (!state.isExternalScannerMode) {
      return;
    }

    final scannedValue = event.value.trim();

    if (scannedValue.isNotEmpty) {
      if (_scannerSettings.duplicateProtection &&
          _isDuplicateCode(scannedValue)) {
        return;
      }

      _rememberDetectedCode(scannedValue);
      emit(
        state.copyWith(
          merchandiseValue: scannedValue,
          latestScannedValue: scannedValue,
          isScanning: true,
          scanNotice: 'External scan received.',
          clearCameraError: true,
          clearDetectedFrame: true,
          scanToken: state.scanToken + 1,
        ),
      );

      await _playScanSuccess(event);
    } else if (scannedValue.isEmpty && state.merchandiseValue.isNotEmpty) {
      // Only clear if we're trying to set empty and we have a value
      emit(state.copyWith(scanNotice: 'Ready for external scanner input.'));
    }
  }

  Future<void> _onOcrFrameCaptured(
    LiveScannerOcrFrameCaptured event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (_isProcessingOcrFrame) {
      return;
    }

    _isProcessingOcrFrame = true;
    try {
      await _handleOcrFrameCaptured(event, emit);
    } finally {
      _isProcessingOcrFrame = false;
    }
  }

  Future<void> _handleOcrFrameCaptured(
    LiveScannerOcrFrameCaptured event,
    Emitter<LiveScannerState> emit,
  ) async {
    final frameSession = _cameraSession;
    if (!_canHandleCameraFrame(frameSession) ||
        !state.isOcrMode ||
        !state.isScanning) {
      return;
    }

    if (event.width <= 0 || event.height <= 0 || event.bitmap.isEmpty) {
      if (!_canHandleCameraFrame(frameSession) || emit.isDone) {
        return;
      }
      emit(
        state.copyWith(
          isScanning: false,
          scanNotice: 'Unable to capture the current camera preview for OCR.',
        ),
      );
      await _playScanError(event);
      return;
    }

    final OcrResult result;
    try {
      result = await _processOcrImageUseCase.fromBitmap(
        event.bitmap,
        event.width,
        event.height,
      );
    } catch (_) {
      if (!_canHandleCameraFrame(frameSession) || emit.isDone) {
        return;
      }
      emit(
        state.copyWith(
          isScanning: false,
          scanNotice: 'Unable to process OCR from the current camera preview.',
        ),
      );
      await _playScanError(event);
      return;
    }

    if (!_canHandleCameraFrame(frameSession) || emit.isDone) {
      return;
    }

    final scannedText = result.text.trim();

    if (scannedText.isEmpty) {
      emit(
        state.copyWith(
          isScanning: false,
          scanNotice: 'No readable text was found.',
        ),
      );
      await _playScanError(event);
      return;
    }

    if (_scannerSettings.duplicateProtection && _isDuplicateCode(scannedText)) {
      return;
    }

    _rememberDetectedCode(scannedText);

    emit(
      state.copyWith(
        merchandiseValue: scannedText,
        latestScannedValue: scannedText,
        isScanning: false,
        scanNotice: 'OCR text detected.',
        clearCameraError: true,
        scanToken: state.scanToken + 1,
      ),
    );

    await _playScanSuccess(event);

    if (_scannerSettings.cameraResetAfterDetection) {
      unawaited(_prepareCameraForQr());
    }
  }

  Future<void> _onOcrCaptureFailed(
    LiveScannerOcrCaptureFailed event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (!_canHandleCameraFrame()) {
      return;
    }

    emit(
      state.copyWith(
        isScanning: false,
        scanNotice: 'Unable to capture the current camera preview for OCR.',
      ),
    );
    await _playScanError(event);
  }

  Future<void> _stopCamera() async {
    if (_isControllerDisposed) {
      return;
    }

    final activeStart = _cameraStartFuture;
    if (activeStart != null) {
      try {
        await activeStart;
      } catch (_) {}
    }

    final activeStop = _cameraStopFuture;
    if (activeStop != null) {
      await activeStop;
      return;
    }

    _cancelPendingFrameProcessing();
    _isDisposingCamera = true;
    _isCameraActive = false;

    if (!_isCameraServiceRunning && !controller.value.isRunning) {
      _isDisposingCamera = false;
      return;
    }

    final stopFuture = controller.stop();
    _cameraStopFuture = stopFuture;
    try {
      await stopFuture;
    } catch (_) {
      // The scanner can already be stopped during quick mode switches.
    } finally {
      _cameraStopFuture = null;
      _isCameraServiceRunning = controller.value.isRunning;
      _isCameraActive = false;
      _isDisposingCamera = false;
    }
  }

  Future<void> _releaseCameraForScannerMode() async {
    await _stopCamera();
    _needsCameraRebind = false;
  }

  Future<void> _reinitializeCameraController() async {
    if (_isClosing || _isDisposed) {
      return;
    }

    final activeStop = _cameraStopFuture;
    if (activeStop != null) {
      await activeStop;
    }

    _cancelPendingFrameProcessing();
    if (!_isControllerDisposed) {
      _isControllerDisposed = true;
      await controller.dispose();
    }
    controller = _createController(_scannerOption, _scannerSettings);
    _isControllerDisposed = false;
    _isCameraServiceRunning = false;
    _isCameraActive = false;
    _isDisposingCamera = false;
    _needsCameraRebind = false;

    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _runCameraLifecycle(Future<void> Function() action) {
    final previousLifecycle = _cameraLifecycleFuture;

    final nextLifecycle = () async {
      if (previousLifecycle != null) {
        try {
          await previousLifecycle;
        } catch (_) {}
      }

      if (_isClosing || (_isControllerDisposed && !_needsCameraRebind)) {
        return;
      }

      await action();
    }();

    late final Future<void> trackedLifecycle;
    trackedLifecycle = nextLifecycle.whenComplete(() {
      if (identical(_cameraLifecycleFuture, trackedLifecycle)) {
        _cameraLifecycleFuture = null;
      }
    });
    _cameraLifecycleFuture = trackedLifecycle;

    return trackedLifecycle;
  }

  Future<void> _onDetectionReceived(
    LiveScannerDetectionReceived event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (_isHandlingDetection) {
      return;
    }

    _isHandlingDetection = true;
    try {
      await _handleDetectionReceived(event, emit);
    } finally {
      _isHandlingDetection = false;
    }
  }

  Future<void> _handleDetectionReceived(
    LiveScannerDetectionReceived event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (!_canHandleCameraFrame()) {
      return;
    }

    if (!state.isScanning) {
      return;
    }

    if (!state.isBrQrMode) {
      return;
    }

    if (event.capture.barcodes.isEmpty) {
      return;
    }

    final scan = _bestStableScan(
      event.capture.barcodes,
      captureSize: event.capture.size,
      previewSize: event.previewSize,
      scanWindow: event.scanWindow,
      previewFit: event.previewFit,
    );
    if (scan == null) {
      return;
    }

    if (_scannerSettings.duplicateProtection && _isDuplicateCode(scan.value)) {
      return;
    }

    _rememberDetectedCode(scan.value);
    final detectedFrame = _normalizedFrameFor(scan.barcode, event.capture.size);

    emit(
      state.copyWith(
        merchandiseValue: scan.value,
        latestScannedValue: scan.value,
        isScanning: false,
        scanNotice: 'Code detected.',
        clearCameraError: true,
        detectedFrame: detectedFrame,
        scanToken: state.scanToken + 1,
      ),
    );

    await _playScanSuccess(event);

    if (_scannerSettings.cameraResetAfterDetection) {
      unawaited(_prepareCameraForQr());
    }
  }

  Future<void> _onDetectionFailed(
    LiveScannerDetectionFailed event,
    Emitter<LiveScannerState> emit,
  ) async {
    if (!_canHandleCameraFrame()) {
      return;
    }

    if (!state.isBrQrMode || !state.isScanning) {
      return;
    }

    emit(
      state.copyWith(
        isScanning: false,
        scanNotice: 'Scan failed.',
        clearCameraError: true,
      ),
    );
    await _playScanError(event);
  }

  Future<void> _startCamera(
    Emitter<LiveScannerState> emit, {
    Object? eventId,
  }) async {
    if (_isClosing || _isDisposed || _isControllerDisposed) {
      return;
    }

    final activeStop = _cameraStopFuture;
    if (activeStop != null) {
      await activeStop;
      if (_isClosing || _isDisposed || _isControllerDisposed) {
        return;
      }
    }

    if (_isDisposingCamera) {
      final activeStop = _cameraStopFuture;
      if (activeStop != null) {
        await activeStop;
      }
      if (_isClosing || _isDisposed || _isControllerDisposed) {
        return;
      }
    }

    if (_isCameraServiceRunning || controller.value.isRunning) {
      _isCameraServiceRunning = true;
      _isCameraActive = true;
      await _prepareCameraForQr();
      emit(state.copyWith(clearCameraError: true, isCameraReady: true));
      return;
    }

    final activeStart = _cameraStartFuture;
    if (activeStart != null) {
      try {
        await activeStart;
      } catch (_) {}
      if (!_isClosing &&
          !_isDisposed &&
          !_isControllerDisposed &&
          controller.value.isRunning) {
        _isCameraServiceRunning = true;
        _isCameraActive = true;
        emit(state.copyWith(clearCameraError: true, isCameraReady: true));
      }
      return;
    }

    final startFuture = _startResolvedCamera();
    _cameraStartFuture = startFuture;
    try {
      await startFuture;
    } catch (_) {
    } finally {
      _cameraStartFuture = null;
    }

    if (controller.value.isRunning) {
      _isCameraServiceRunning = true;
      _isCameraActive = true;
      await _prepareCameraForQr();
      emit(state.copyWith(clearCameraError: true, isCameraReady: true));
      return;
    }

    _isCameraServiceRunning = false;
    _isCameraActive = false;
    emit(
      state.copyWith(
        isScanning: false,
        isCameraReady: false,
        cameraError:
            'No compatible camera was found. On an emulator, enable a virtual back camera or try a physical device.',
      ),
    );
    await _playScanError(eventId);
  }

  Future<void> _startResolvedCamera() async {
    final facing = await _resolveCameraFacing();
    if (facing == null ||
        _isClosing ||
        _isDisposed ||
        _isControllerDisposed ||
        _isDisposingCamera) {
      return;
    }

    await Future<void>.delayed(Duration.zero);
    if (_isClosing ||
        _isDisposed ||
        _isControllerDisposed ||
        _isDisposingCamera) {
      return;
    }

    await controller.start(cameraDirection: facing);
    _isCameraServiceRunning = controller.value.isRunning;
    _isCameraActive = controller.value.isRunning;
    if (_isCameraActive) {
      _cameraSession++;
    }
  }

  Future<CameraFacing?> _resolveCameraFacing() async {
    final cachedFacing = _resolvedCameraFacing;
    if (cachedFacing != null) {
      return cachedFacing;
    }

    final availableFacings = await _availableCameraFacings();
    if (availableFacings.isEmpty) {
      return null;
    }

    final selectedFacing = availableFacings.contains(CameraFacing.back)
        ? CameraFacing.back
        : availableFacings.first;
    _resolvedCameraFacing = selectedFacing;
    return selectedFacing;
  }

  Future<List<CameraFacing>> _availableCameraFacings() async {
    return const [CameraFacing.back];
  }

  Future<void> _prepareCameraForQr() async {
    if (!_isCameraUsable) {
      return;
    }

    try {
      await controller.setFocusPoint(const Offset(0.5, 0.5));
    } catch (_) {}
  }

  bool _isDuplicateCode(String value) {
    final now = DateTime.now();
    final lastDetectedAt = _lastDetectedAt;

    return _lastDetectedValue == value &&
        lastDetectedAt != null &&
        now.difference(lastDetectedAt) < const Duration(milliseconds: 1200);
  }

  void _rememberDetectedCode(String value) {
    _lastDetectedValue = value;
    _lastDetectedAt = DateTime.now();
  }

  void _resetDetectedCode() {
    _lastDetectedValue = null;
    _lastDetectedAt = null;
    _candidateValue = null;
    _candidateFormat = null;
    _candidateHits = 0;
  }

  bool get _isCameraUsable {
    return _isCameraActive &&
        !_isDisposingCamera &&
        !_isClosing &&
        !_isDisposed &&
        !_isControllerDisposed &&
        controller.value.isRunning;
  }

  bool _canHandleCameraFrame([int? session]) {
    if (!_isCameraUsable) {
      return false;
    }

    return session == null || session == _cameraSession;
  }

  void _cancelPendingFrameProcessing() {
    _cameraSession++;
    _isHandlingDetection = false;
    _isProcessingOcrFrame = false;
    _resetDetectedCode();
  }

  _StableScan? _bestStableScan(
    List<Barcode> barcodes, {
    required Size captureSize,
    required Size? previewSize,
    required Rect? scanWindow,
    required BoxFit previewFit,
  }) {
    final scanArea = _normalizedScanWindow(
      captureSize: captureSize,
      previewSize: previewSize,
      scanWindow: scanWindow,
      previewFit: previewFit,
    );
    final sortedBarcodes =
        barcodes
            .map(
              (barcode) => _BarcodeCandidate(
                barcode: barcode,
                frame: _barcodeFrameInCapture(barcode, captureSize),
              ),
            )
            .where(
              (candidate) => _isCandidateInsideScanArea(candidate, scanArea),
            )
            .toList()
          ..sort((a, b) {
            final aDistance = _distanceFromScanCenter(a.frame, scanArea);
            final bDistance = _distanceFromScanCenter(b.frame, scanArea);
            return aDistance.compareTo(bDistance);
          });

    for (final candidate in sortedBarcodes) {
      final barcode = candidate.barcode;
      final value = _stableBarcodeValue(barcode);
      if (value == null) {
        continue;
      }

      return _StableScan(barcode: barcode, value: value);
    }

    return null;
  }

  Rect? _normalizedScanWindow({
    required Size captureSize,
    required Size? previewSize,
    required Rect? scanWindow,
    required BoxFit previewFit,
  }) {
    if (captureSize.isEmpty ||
        previewSize == null ||
        previewSize.isEmpty ||
        scanWindow == null ||
        scanWindow.isEmpty) {
      return null;
    }

    final fitted = applyBoxFit(previewFit, captureSize, previewSize);
    final scaleX = fitted.destination.width / captureSize.width;
    final scaleY = fitted.destination.height / captureSize.height;
    final textureWindow = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & previewSize,
    );
    final scanWindowInCapture = Rect.fromLTRB(
      (scanWindow.left - textureWindow.left) / scaleX,
      (scanWindow.top - textureWindow.top) / scaleY,
      (scanWindow.right - textureWindow.left) / scaleX,
      (scanWindow.bottom - textureWindow.top) / scaleY,
    ).intersect(Offset.zero & captureSize);

    if (scanWindowInCapture.isEmpty) {
      return null;
    }

    return Rect.fromLTRB(
      scanWindowInCapture.left / captureSize.width,
      scanWindowInCapture.top / captureSize.height,
      scanWindowInCapture.right / captureSize.width,
      scanWindowInCapture.bottom / captureSize.height,
    );
  }

  Rect? _barcodeFrameInCapture(Barcode barcode, Size captureSize) {
    if (barcode.corners.isEmpty || captureSize.isEmpty) {
      return null;
    }

    final xs = barcode.corners.map((corner) => corner.dx / captureSize.width);
    final ys = barcode.corners.map((corner) => corner.dy / captureSize.height);

    return Rect.fromLTRB(
      xs.reduce((a, b) => a < b ? a : b).clamp(0.0, 1.0),
      ys.reduce((a, b) => a < b ? a : b).clamp(0.0, 1.0),
      xs.reduce((a, b) => a > b ? a : b).clamp(0.0, 1.0),
      ys.reduce((a, b) => a > b ? a : b).clamp(0.0, 1.0),
    );
  }

  bool _isCandidateInsideScanArea(_BarcodeCandidate candidate, Rect? scanArea) {
    if (scanArea == null || !_usesCenteredScanArea(candidate.barcode.format)) {
      return true;
    }

    final frame = candidate.frame;
    if (frame == null || frame.isEmpty) {
      return true;
    }

    final tolerantArea = scanArea.inflate(0.08);
    return tolerantArea.contains(frame.center) || tolerantArea.overlaps(frame);
  }

  double _distanceFromScanCenter(Rect? frame, Rect? scanArea) {
    if (frame == null || scanArea == null) {
      return 0;
    }

    final dx = frame.center.dx - scanArea.center.dx;
    final dy = frame.center.dy - scanArea.center.dy;
    return dx * dx + dy * dy;
  }

  bool _usesCenteredScanArea(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.qrCode ||
      BarcodeFormat.dataMatrix ||
      BarcodeFormat.pdf417 ||
      BarcodeFormat.aztec => false,
      _ => true,
    };
  }

  String? _stableBarcodeValue(Barcode barcode) {
    final value = _cleanBarcodeValue(barcode.rawValue ?? barcode.displayValue);
    if (value == null) {
      _candidateValue = null;
      _candidateFormat = null;
      _candidateHits = 0;
      return null;
    }

    final merchandiseValue = _formatMerchandiseValue(value, barcode.format);
    if (merchandiseValue.isEmpty ||
        !_isValidBarcodeValue(merchandiseValue, barcode.format)) {
      _candidateValue = null;
      _candidateFormat = null;
      _candidateHits = 0;
      return null;
    }

    final stableValue = _stableComparisonValue(
      merchandiseValue,
      barcode.format,
    );
    if (_candidateValue == stableValue && _candidateFormat == barcode.format) {
      _candidateHits++;
    } else {
      _candidateValue = stableValue;
      _candidateFormat = barcode.format;
      _candidateHits = 1;
    }

    final requiredHits = _requiredStableHitsFor(
      barcode.format,
      merchandiseValue,
    );
    return _candidateHits >= requiredHits ? merchandiseValue : null;
  }

  String? _cleanBarcodeValue(String? value) {
    final cleanValue = value?.trim();
    if (cleanValue == null || cleanValue.isEmpty) {
      return null;
    }

    return cleanValue.replaceAll(RegExp(r'[\r\n\t ]+'), '');
  }

  String _stableComparisonValue(String value, BarcodeFormat format) {
    return format == BarcodeFormat.codabar || format == BarcodeFormat.code39
        ? value.toUpperCase()
        : value;
  }

  String _formatMerchandiseValue(String value, BarcodeFormat format) {
    if (format == BarcodeFormat.code39) {
      return _stripCode39Guards(value).toUpperCase();
    }

    if (format == BarcodeFormat.codabar) {
      return ReceivingBarcodeValue.normalizeNw7Output(value) ?? '';
    }

    return value;
  }

  String _stripCode39Guards(String value) {
    if (value.length >= 3 && value.startsWith('*') && value.endsWith('*')) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }

  bool _isValidBarcodeValue(String value, BarcodeFormat format) {
    if (value.contains('\uFFFD')) {
      return false;
    }

    return switch (format) {
      BarcodeFormat.qrCode ||
      BarcodeFormat.dataMatrix ||
      BarcodeFormat.pdf417 ||
      BarcodeFormat.aztec => value.length >= 2 && value.length <= 4096,
      BarcodeFormat.ean13 => RegExp(r'^\d{13}$').hasMatch(value),
      BarcodeFormat.ean8 => RegExp(r'^\d{8}$').hasMatch(value),
      BarcodeFormat.upcA => RegExp(r'^\d{12}$').hasMatch(value),
      BarcodeFormat.upcE => RegExp(r'^\d{6,8}$').hasMatch(value),
      BarcodeFormat.code128 || BarcodeFormat.code39 || BarcodeFormat.code93 =>
        RegExp(r'^[A-Z0-9 .$/+%-]{6,64}$').hasMatch(value),
      BarcodeFormat.codabar => RegExp(r'^\d{3,62}$').hasMatch(value),
      BarcodeFormat.itf2of5 ||
      BarcodeFormat.itf2of5WithChecksum ||
      BarcodeFormat.itf14 => RegExp(r'^\d{10,32}$').hasMatch(value),
      BarcodeFormat.all || BarcodeFormat.unknown => value.length >= 10,
      // ignore: deprecated_member_use
      BarcodeFormat.itf => RegExp(r'^\d{10,32}$').hasMatch(value),
    };
  }

  int _requiredStableHitsFor(BarcodeFormat format, String value) {
    if (_isReceivingFastBarcode(value)) {
      return 1;
    }

    if (_scannerSettings.fastScanMode) {
      return switch (format) {
        BarcodeFormat.qrCode ||
        BarcodeFormat.dataMatrix ||
        BarcodeFormat.pdf417 ||
        BarcodeFormat.aztec => 1,
        _ => 2,
      };
    }

    return switch (format) {
      BarcodeFormat.qrCode ||
      BarcodeFormat.dataMatrix ||
      BarcodeFormat.pdf417 ||
      BarcodeFormat.aztec => 2,
      _ => 3,
    };
  }

  bool _isReceivingFastBarcode(String value) {
    if (state.scannerOption.key != 'receiving') {
      return false;
    }

    return RegExp(
      r'^(?:\d{13}|\d{15}|\d-\d-\d-\d|[a-etn*]\d{3,62}[a-etn*]|#QR~/.+)$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  void _handleSettingsUpdated() {
    final settings = _settingsController.settings.scanner;
    if (settings == _scannerSettings) {
      return;
    }

    add(LiveScannerSettingsChanged(settings));
  }

  Future<void> _playScanSuccess(Object? eventId) async {
    if (!_scannerSettings.scanSound ||
        !_scannerOption.playDetectionSuccessSound) {
      return;
    }

    await _scanFeedbackService.playScanSuccess(eventId: eventId);
  }

  Future<void> _playScanError(Object? eventId) async {
    if (!_scannerSettings.scanSound) {
      return;
    }

    await _scanFeedbackService.playScanError(eventId: eventId);
  }

  Rect? _normalizedFrameFor(Barcode barcode, Size captureSize) {
    if (barcode.corners.isEmpty || captureSize.isEmpty) {
      return null;
    }

    final xs = barcode.corners.map((corner) => corner.dx / captureSize.width);
    final ys = barcode.corners.map((corner) => corner.dy / captureSize.height);

    final left = xs.reduce((a, b) => a < b ? a : b);
    final right = xs.reduce((a, b) => a > b ? a : b);
    final top = ys.reduce((a, b) => a < b ? a : b);
    final bottom = ys.reduce((a, b) => a > b ? a : b);

    const padding = 0.08;

    return Rect.fromLTRB(
      (left - padding).clamp(0.05, 0.85),
      (top - padding).clamp(0.05, 0.85),
      (right + padding).clamp(0.15, 0.95),
      (bottom + padding).clamp(0.15, 0.95),
    );
  }

  @override
  Future<void> close() async {
    final activeClose = _closeFuture;
    if (activeClose != null) {
      return activeClose;
    }

    _isClosing = true;
    _isDisposed = true;
    _isCameraActive = false;
    _cancelPendingFrameProcessing();
    _closeFuture = () async {
      _settingsController.removeListener(_handleSettingsUpdated);
      final activeLifecycle = _cameraLifecycleFuture;
      if (activeLifecycle != null) {
        try {
          await activeLifecycle;
        } catch (_) {}
      }
      final activeStart = _cameraStartFuture;
      if (activeStart != null) {
        try {
          await activeStart;
        } catch (_) {}
      }
      await _stopCamera();
      if (!_isControllerDisposed) {
        _isControllerDisposed = true;
        await controller.dispose();
      }
      await _processOcrImageUseCase.dispose();
      return super.close();
    }();

    return _closeFuture;
  }
}

final class _StableScan {
  const _StableScan({required this.barcode, required this.value});

  final Barcode barcode;
  final String value;
}

final class _BarcodeCandidate {
  const _BarcodeCandidate({required this.barcode, required this.frame});

  final Barcode barcode;
  final Rect? frame;
}
