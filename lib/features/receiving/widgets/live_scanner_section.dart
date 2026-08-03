import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/app_router.dart';
import 'package:waretrack_mini/core/constants/app_feature_flags.dart';
import 'package:waretrack_mini/core/utils/app_settings_scope.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_bloc.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_event.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_route_visibility.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_layout_metrics.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_overlay.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_preview_section.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

class LiveScannerSection extends StatefulWidget {
  const LiveScannerSection({
    super.key,
    required this.scannerOption,
    required this.metrics,
    required this.onScanned,
    this.instruction,
    this.inlineNotice,
    this.showScannedValue = true,
    this.onScanStarted,
    this.onExternalBufferChanged,
    this.ignoredScannerFocusNodes = const [],
    this.footerBuilder,
    this.leadingAction,
    this.trailingAction,
  });

  final ScannerOption scannerOption;
  final ScannerLayoutMetrics metrics;

  /// Called when the scanner surfaces a value. [isOcr] is true only when the
  /// value came from an OCR capture, so callers can preserve it verbatim
  /// instead of applying barcode/QR normalization.
  final void Function(String value, {required bool isOcr}) onScanned;
  final String? instruction;
  final String? inlineNotice;
  final bool showScannedValue;
  final VoidCallback? onScanStarted;
  final ValueChanged<String>? onExternalBufferChanged;
  final List<FocusNode> ignoredScannerFocusNodes;
  final Widget Function(BuildContext context, LiveScannerState state)?
  footerBuilder;
  final Widget? leadingAction;
  final Widget? trailingAction;

  @override
  State<LiveScannerSection> createState() => _LiveScannerSectionState();
}

class _LiveScannerSectionState extends State<LiveScannerSection>
    with WidgetsBindingObserver, RouteAware {
  late final LiveScannerBloc _bloc;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final StringBuffer _externalScannerBuffer = StringBuffer();
  Timer? _inputPauseTimer;
  bool _didSubscribeToRoute = false;
  bool _isRouteFocused = false;
  bool _hasRequestedScannerStart = false;
  bool _hasDisposed = false;

  static const Duration _externalScannerSettleDuration = Duration(
    milliseconds: 450,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = sl<LiveScannerBloc>(param1: widget.scannerOption);
    if (AppFeatureFlags.enableScannerMode) {
      HardwareKeyboard.instance.addHandler(_handleHardwareScannerKey);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSubscribeToRoute) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route == null) {
      return;
    }

    AppRouter.routeObserver.subscribe(this, route);
    _didSubscribeToRoute = true;
    _focusScannerRoute();
  }

  @override
  void didPush() => _focusScannerRoute();

  @override
  void didPopNext() => _focusScannerRoute();

  @override
  void didPushNext() => _unfocusScannerRoute();

  @override
  void didPop() => _unfocusScannerRoute();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasDisposed) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_isRouteFocused) {
        _focusScannerRoute();
      }
      return;
    }

    _requestScannerStop();
  }

  @override
  void dispose() {
    _hasDisposed = true;
    _isRouteFocused = false;
    _requestScannerStop();
    if (_didSubscribeToRoute) {
      AppRouter.routeObserver.unsubscribe(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    if (AppFeatureFlags.enableScannerMode) {
      HardwareKeyboard.instance.removeHandler(_handleHardwareScannerKey);
    }
    _inputPauseTimer?.cancel();
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<LiveScannerBloc, LiveScannerState>(
        listenWhen: (previous, current) =>
            previous.scanToken != current.scanToken &&
            current.merchandiseValue.trim().isNotEmpty,
        listener: (context, state) {
          _clearExternalScannerBuffer();
          widget.onScanned(
            state.merchandiseValue.trim(),
            isOcr: state.isOcrMode,
          );
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScannerPreviewSection(
                state: state,
                controller: _bloc.controller,
                metrics: widget.metrics,
                boundaryKey: _previewBoundaryKey,
                autoScan: AppSettingsScope.of(
                  context,
                ).settings.scanner.autoScan,
                notice: _localizedScannerNotice(context, state),
                cameraErrorMessage: _localizedCameraError(
                  context,
                  state.cameraError,
                ),
                instruction: widget.instruction,
                inlineNotice: widget.inlineNotice,
                showScannedValue: widget.showScannedValue,
                leadingAction: widget.leadingAction,
                trailingAction: widget.trailingAction,
                onScanPressed: () => _handleScanPressed(context, state),
                onModeChanged: _handleModeChanged,
                onDetect:
                    (
                      capture, {
                      scanWindow,
                      previewSize,
                      previewFit = BoxFit.cover,
                    }) => _bloc.add(
                      LiveScannerDetectionReceived(
                        capture,
                        scanWindow: scanWindow,
                        previewSize: previewSize,
                        previewFit: previewFit,
                      ),
                    ),
                onDetectError: () =>
                    _bloc.add(const LiveScannerDetectionFailed()),
              ),
              if (widget.footerBuilder case final footerBuilder?)
                footerBuilder(context, state),
            ],
          );
        },
      ),
    );
  }

  void _focusScannerRoute() {
    if (_hasDisposed) {
      return;
    }

    _isRouteFocused = true;
    unawaited(_startScannerWhenVisible());
  }

  void _unfocusScannerRoute() {
    _isRouteFocused = false;
    _requestScannerStop();
  }

  Future<void> _startScannerWhenVisible() async {
    await waitForScannerRouteVisible(ModalRoute.of(context));
    if (mounted && _isRouteFocused && !_hasDisposed) {
      _requestScannerStart();
    }
  }

  void _requestScannerStart() {
    if (_hasDisposed || _hasRequestedScannerStart) {
      return;
    }

    _hasRequestedScannerStart = true;
    _bloc.add(const LiveScannerStarted());
  }

  void _requestScannerStop() {
    if (!_hasRequestedScannerStart) {
      return;
    }

    _hasRequestedScannerStart = false;
    _bloc.add(const LiveScannerStopped());
  }

  void _handleModeChanged(ScannerMode mode) {
    if (mode == ScannerMode.scanner && !AppFeatureFlags.enableScannerMode) {
      return;
    }

    _clearExternalScannerBuffer();
    if (mode == ScannerMode.scanner) {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    }
    _bloc.add(LiveScannerModeChanged(mode));
  }

  Future<void> _handleScanPressed(
    BuildContext context,
    LiveScannerState state,
  ) async {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    widget.onScanStarted?.call();
    _bloc.add(const LiveScannerScanRequested());

    if (state.isBrQrMode || state.isExternalScannerMode) {
      return;
    }

    await _waitForCameraReady();
    await WidgetsBinding.instance.endOfFrame;

    final ocrBitmap = await _capturePreviewBitmap(devicePixelRatio);
    if (!mounted || ocrBitmap == null) {
      _bloc.add(const LiveScannerOcrCaptureFailed());
      return;
    }

    final croppedBitmap = _cropBitmapToFrameArea(ocrBitmap);
    _bloc.add(
      LiveScannerOcrFrameCaptured(
        bitmap: croppedBitmap.bytes,
        width: croppedBitmap.width,
        height: croppedBitmap.height,
      ),
    );
  }

  Future<void> _waitForCameraReady() async {
    if (_bloc.controller.value.isRunning) {
      return;
    }

    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || _bloc.controller.value.isRunning) {
        return;
      }
    }
  }

  bool _handleHardwareScannerKey(KeyEvent event) {
    if (!AppFeatureFlags.enableScannerMode) {
      return false;
    }

    if (_hasDisposed ||
        !_bloc.state.isExternalScannerMode ||
        event is! KeyDownEvent ||
        widget.ignoredScannerFocusNodes.any((node) => node.hasFocus)) {
      return false;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_externalScannerBuffer.toString().trim().isEmpty) {
        return false;
      }

      _completeExternalScan();
      return true;
    }

    if (key == LogicalKeyboardKey.backspace) {
      final value = _externalScannerBuffer.toString();
      if (value.isNotEmpty) {
        _externalScannerBuffer
          ..clear()
          ..write(value.substring(0, value.length - 1));
        _notifyExternalBufferChanged();
      }
      _scheduleExternalScannerCompletion();
      return true;
    }

    final character = event.character;
    if (character == null ||
        character.isEmpty ||
        character == '\n' ||
        character == '\r') {
      return false;
    }

    _externalScannerBuffer.write(character);
    _notifyExternalBufferChanged();
    _scheduleExternalScannerCompletion();
    return true;
  }

  void _scheduleExternalScannerCompletion() {
    _inputPauseTimer?.cancel();
    if (_externalScannerBuffer.isEmpty) {
      return;
    }

    _inputPauseTimer = Timer(_externalScannerSettleDuration, () {
      if (!mounted || !_bloc.state.isExternalScannerMode) {
        _inputPauseTimer = null;
        return;
      }

      _completeExternalScan();
      _inputPauseTimer = null;
    });
  }

  void _completeExternalScan() {
    final cleanValue = _externalScannerBuffer.toString().trim();
    _clearExternalScannerBuffer();
    if (cleanValue.isNotEmpty) {
      _bloc.add(LiveScannerExternalValueChanged(cleanValue));
    }
  }

  void _clearExternalScannerBuffer() {
    _inputPauseTimer?.cancel();
    _inputPauseTimer = null;
    if (_externalScannerBuffer.isEmpty) {
      return;
    }

    _externalScannerBuffer.clear();
    _notifyExternalBufferChanged();
  }

  void _notifyExternalBufferChanged() {
    widget.onExternalBufferChanged?.call(_externalScannerBuffer.toString());
  }

  Future<_CapturedBitmap?> _capturePreviewBitmap(
    double devicePixelRatio,
  ) async {
    final boundaryContext = _previewBoundaryKey.currentContext;
    if (boundaryContext == null) {
      return null;
    }

    final boundary =
        boundaryContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    final pixelRatio = devicePixelRatio.clamp(1.0, 2.0);
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final imageWidth = image.width;
    final imageHeight = image.height;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    if (byteData == null) {
      return null;
    }

    return _CapturedBitmap(
      bytes: byteData.buffer.asUint8List(),
      width: imageWidth,
      height: imageHeight,
    );
  }

  _CapturedBitmap _cropBitmapToFrameArea(_CapturedBitmap bitmap) {
    const bytesPerPixel = 4;
    final frameWidth = bitmap.width * ScannerOverlayGeometry.frameWidthPercent;
    final frameHeight =
        bitmap.height * ScannerOverlayGeometry.frameHeightPercent;
    final frameLeft = (bitmap.width - frameWidth) / 2;
    final frameTop = (bitmap.height - frameHeight) / 2;

    var frameLeftInt = frameLeft.round();
    var frameTopInt = frameTop.round();
    var frameRightInt = (frameLeft + frameWidth).round();
    var frameBottomInt = (frameTop + frameHeight).round();

    frameLeftInt = frameLeftInt.clamp(0, bitmap.width - 1);
    frameTopInt = frameTopInt.clamp(0, bitmap.height - 1);
    frameRightInt = frameRightInt.clamp(frameLeftInt + 1, bitmap.width);
    frameBottomInt = frameBottomInt.clamp(frameTopInt + 1, bitmap.height);

    final frameWidthInt = frameRightInt - frameLeftInt;
    final frameHeightInt = frameBottomInt - frameTopInt;
    final croppedBytes = Uint8List(
      frameWidthInt * frameHeightInt * bytesPerPixel,
    );

    for (int y = 0; y < frameHeightInt; y++) {
      for (int x = 0; x < frameWidthInt; x++) {
        final sourceX = frameLeftInt + x;
        final sourceY = frameTopInt + y;
        final sourceIndex = (sourceY * bitmap.width + sourceX) * bytesPerPixel;
        final destIndex = (y * frameWidthInt + x) * bytesPerPixel;

        if (sourceIndex + 3 < bitmap.bytes.length &&
            destIndex + 3 < croppedBytes.length) {
          croppedBytes[destIndex] = bitmap.bytes[sourceIndex];
          croppedBytes[destIndex + 1] = bitmap.bytes[sourceIndex + 1];
          croppedBytes[destIndex + 2] = bitmap.bytes[sourceIndex + 2];
          croppedBytes[destIndex + 3] = bitmap.bytes[sourceIndex + 3];
        }
      }
    }

    return _CapturedBitmap(
      bytes: croppedBytes,
      width: frameWidthInt,
      height: frameHeightInt,
    );
  }
}

String _localizedScannerNotice(BuildContext context, LiveScannerState state) {
  final l10n = AppLocalizations.of(context);

  return switch (state.scanNotice) {
    'Ready for external scanner input.' => l10n.readyExternalScanner,
    'Scanning in progress' => l10n.scanningInProgress,
    'Capturing OCR from the current camera preview...' => l10n.capturingOcr,
    'External scan received.' => l10n.externalScanReceived,
    'Unable to capture the current camera preview for OCR.' =>
      l10n.unableCaptureOcr,
    'Unable to process OCR from the current camera preview.' =>
      l10n.unableProcessOcr,
    'No readable text was found.' => l10n.noReadableText,
    'OCR text detected.' => l10n.ocrTextDetected,
    'Code detected.' => l10n.codeDetected,
    'Scan failed.' => l10n.scanFailed,
    'Ready for OCR capture.' => l10n.scanningStopped,
    _ => state.isScanning ? l10n.scanningInProgress : l10n.scanningStopped,
  };
}

String _localizedCameraError(BuildContext context, String? message) {
  final l10n = AppLocalizations.of(context);

  return switch (message) {
    'No compatible camera was found. On an emulator, enable a virtual back camera or try a physical device.' =>
      l10n.noCompatibleCamera,
    null => l10n.unableToOpenCamera,
    _ => message,
  };
}

class _CapturedBitmap {
  const _CapturedBitmap({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}
