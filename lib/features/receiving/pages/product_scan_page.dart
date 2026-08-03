import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/app_router.dart';
import 'package:waretrack_mini/core/constants/app_feature_flags.dart';
import 'package:waretrack_mini/core/constants/app_routes.dart';
import 'package:waretrack_mini/core/utils/app_settings_scope.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/core/widgets/primary_app_bar.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_bloc.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_event.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_route_visibility.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_layout_metrics.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_overlay.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_preview_section.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_result_card.dart';

String _scannerTitle(AppLocalizations l10n, ScannerMode mode) {
  return switch (mode) {
    ScannerMode.brQr => l10n.brQrScanner,
    ScannerMode.ocr => l10n.ocrScanner,
    ScannerMode.scanner => l10n.scanner,
  };
}

String _localizedNotice(BuildContext context, LiveScannerState state) {
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

class LiveScannerPage extends StatefulWidget {
  const LiveScannerPage({super.key, required this.scannerOption});

  final ScannerOption scannerOption;

  @override
  State<LiveScannerPage> createState() => _LiveScannerPageState();
}

class _LiveScannerPageState extends State<LiveScannerPage>
    with WidgetsBindingObserver, RouteAware {
  late final LiveScannerBloc _bloc;
  late final TextEditingController _merchandiseController;
  late final FocusNode _merchandiseFocusNode;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  Timer? _inputPauseTimer;
  bool _isClearingExternalInput = false;
  bool _wasExternalScannerMode = false;
  bool _didSubscribeToRoute = false;
  bool _isRouteFocused = false;
  bool _hasRequestedScannerStart = false;
  bool _hasDisposed = false;
  int _syncedScanToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = sl<LiveScannerBloc>(param1: widget.scannerOption);
    _merchandiseController = TextEditingController();
    _merchandiseFocusNode = FocusNode();
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
    _inputPauseTimer?.cancel();
    _merchandiseFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _merchandiseFocusNode.dispose();
    _merchandiseController.dispose();
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  void didPush() {
    _focusScannerRoute();
  }

  @override
  void didPopNext() => _focusScannerRoute();

  @override
  void didPushNext() {
    _unfocusScannerRoute();
  }

  @override
  void didPop() {
    _unfocusScannerRoute();
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<LiveScannerBloc, LiveScannerState>(
        buildWhen: (previous, current) => previous != current,
        builder: (context, state) {
          final bloc = _bloc;
          _syncExternalInput(state);

          return LayoutBuilder(
            builder: (context, constraints) {
              final metrics = ScannerLayoutMetrics.fromConstraints(constraints);

              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: PrimaryAppBar(
                  title: _scannerTitle(
                    AppLocalizations.of(context),
                    state.activeMode,
                  ),
                  showSettingsButton: true,
                  onSettingsPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.settings);
                  },
                ),
                body: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: metrics.contentMaxWidth,
                      ),
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.all(metrics.pagePadding),
                        children: [
                          if (metrics.useSplitLayout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: ScannerPreviewSection(
                                    state: state,
                                    controller: bloc.controller,
                                    metrics: metrics,
                                    boundaryKey: _previewBoundaryKey,
                                    autoScan: AppSettingsScope.of(
                                      context,
                                    ).settings.scanner.autoScan,
                                    notice: _localizedNotice(context, state),
                                    cameraErrorMessage: _localizedCameraError(
                                      context,
                                      state.cameraError,
                                    ),
                                    onScanPressed: () => _handleScanPressed(
                                      context,
                                      state,
                                      bloc,
                                    ),
                                    onModeChanged: (mode) =>
                                        _handleModeChanged(mode, bloc),
                                    onDetect:
                                        (
                                          capture, {
                                          scanWindow,
                                          previewSize,
                                          previewFit = BoxFit.cover,
                                        }) => bloc.add(
                                          LiveScannerDetectionReceived(
                                            capture,
                                            scanWindow: scanWindow,
                                            previewSize: previewSize,
                                            previewFit: previewFit,
                                          ),
                                        ),
                                    onDetectError: () => bloc.add(
                                      const LiveScannerDetectionFailed(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: metrics.sectionGap),
                                Expanded(
                                  flex: 5,
                                  child: ScannerResultCard(
                                    state: state,
                                    controller: _merchandiseController,
                                    focusNode: _merchandiseFocusNode,
                                    onExternalInput: (value) =>
                                        _handleExternalScannerInput(
                                          value,
                                          context,
                                        ),
                                    sectionGap: metrics.sectionGap,
                                    componentGap: metrics.componentGap,
                                    cardRadius: metrics.cardRadius,
                                    innerRadius: metrics.innerRadius,
                                    cardPadding: metrics.cardPadding,
                                    inputHorizontalPadding:
                                        metrics.inputHorizontalPadding,
                                    inputVerticalPadding:
                                        metrics.inputVerticalPadding,
                                    inputMaxLines: metrics.inputMaxLines,
                                    searchButtonHeight:
                                        metrics.secondaryButtonHeight,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            ScannerPreviewSection(
                              state: state,
                              controller: bloc.controller,
                              metrics: metrics,
                              boundaryKey: _previewBoundaryKey,
                              autoScan: AppSettingsScope.of(
                                context,
                              ).settings.scanner.autoScan,
                              notice: _localizedNotice(context, state),
                              cameraErrorMessage: _localizedCameraError(
                                context,
                                state.cameraError,
                              ),
                              onScanPressed: () =>
                                  _handleScanPressed(context, state, bloc),
                              onModeChanged: (mode) =>
                                  _handleModeChanged(mode, bloc),
                              onDetect:
                                  (
                                    capture, {
                                    scanWindow,
                                    previewSize,
                                    previewFit = BoxFit.cover,
                                  }) => bloc.add(
                                    LiveScannerDetectionReceived(
                                      capture,
                                      scanWindow: scanWindow,
                                      previewSize: previewSize,
                                      previewFit: previewFit,
                                    ),
                                  ),
                              onDetectError: () =>
                                  bloc.add(const LiveScannerDetectionFailed()),
                            ),
                            SizedBox(height: metrics.sectionGap),
                            ScannerResultCard(
                              state: state,
                              controller: _merchandiseController,
                              focusNode: _merchandiseFocusNode,
                              onExternalInput: (value) =>
                                  _handleExternalScannerInput(value, context),
                              sectionGap: metrics.sectionGap,
                              componentGap: metrics.componentGap,
                              cardRadius: metrics.cardRadius,
                              innerRadius: metrics.innerRadius,
                              cardPadding: metrics.cardPadding,
                              inputHorizontalPadding:
                                  metrics.inputHorizontalPadding,
                              inputVerticalPadding:
                                  metrics.inputVerticalPadding,
                              inputMaxLines: metrics.inputMaxLines,
                              searchButtonHeight: metrics.secondaryButtonHeight,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _syncExternalInput(LiveScannerState state) {
    if (!state.isExternalScannerMode) {
      _inputPauseTimer?.cancel();
      _inputPauseTimer = null;
    }

    final wasExternalScannerMode = _wasExternalScannerMode;

    if (state.isExternalScannerMode && !wasExternalScannerMode) {
      _clearExternalScannerBuffer();
    }
    _wasExternalScannerMode = state.isExternalScannerMode;

    if (!state.isExternalScannerMode &&
        wasExternalScannerMode &&
        _merchandiseFocusNode.hasFocus) {
      _merchandiseFocusNode.unfocus();
    }

    if (state.scanToken != _syncedScanToken &&
        state.merchandiseValue.trim().isNotEmpty &&
        _merchandiseController.text != state.merchandiseValue) {
      _merchandiseController.value = TextEditingValue(
        text: state.merchandiseValue,
        selection: TextSelection.collapsed(
          offset: state.merchandiseValue.length,
        ),
      );
      _syncedScanToken = state.scanToken;
      _merchandiseFocusNode.unfocus();
    }
  }

  void _handleModeChanged(ScannerMode mode, LiveScannerBloc bloc) {
    if (mode == ScannerMode.scanner && !AppFeatureFlags.enableScannerMode) {
      return;
    }

    if (mode == ScannerMode.scanner) {
      _merchandiseFocusNode.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    }

    bloc.add(LiveScannerModeChanged(mode));

    if (mode == ScannerMode.scanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _bloc.state.activeMode != ScannerMode.scanner) {
          return;
        }

        _merchandiseFocusNode.requestFocus();
        SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      });
    }
  }

  Future<void> _handleScanPressed(
    BuildContext context,
    LiveScannerState state,
    LiveScannerBloc bloc,
  ) async {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    bloc.add(const LiveScannerScanRequested());

    if (state.isBrQrMode || state.isExternalScannerMode) {
      return;
    }

    await _waitForCameraReady(bloc);
    await WidgetsBinding.instance.endOfFrame;

    final ocrBitmap = await _capturePreviewBitmap(devicePixelRatio);
    if (!mounted || ocrBitmap == null) {
      bloc.add(const LiveScannerOcrCaptureFailed());
      return;
    }

    final croppedBitmap = _cropBitmapToFrameArea(ocrBitmap);
    bloc.add(
      LiveScannerOcrFrameCaptured(
        bitmap: croppedBitmap.bytes,
        width: croppedBitmap.width,
        height: croppedBitmap.height,
      ),
    );
  }

  Future<void> _waitForCameraReady(LiveScannerBloc bloc) async {
    if (bloc.controller.value.isRunning) {
      return;
    }

    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || bloc.controller.value.isRunning) {
        return;
      }
    }
  }

  void _handleExternalScannerInput(String value, BuildContext context) {
    if (!AppFeatureFlags.enableScannerMode) {
      return;
    }

    if (_isClearingExternalInput) {
      return;
    }

    _inputPauseTimer?.cancel();

    if (value.contains('\n') || value.contains('\r')) {
      _completeExternalScan(value, context);
      return;
    }

    if (value.isEmpty) {
      return;
    }

    _inputPauseTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || _merchandiseController.text.isEmpty) {
        _inputPauseTimer = null;
        return;
      }

      _completeExternalScan(_merchandiseController.text, context);
      _inputPauseTimer = null;
    });
  }

  void _completeExternalScan(String rawValue, BuildContext context) {
    final previousValue = context
        .read<LiveScannerBloc>()
        .state
        .merchandiseValue;
    var cleanValue = rawValue.replaceAll('\n', '').replaceAll('\r', '').trim();

    if (previousValue.isNotEmpty &&
        cleanValue.startsWith(previousValue) &&
        cleanValue.length > previousValue.length) {
      cleanValue = cleanValue.substring(previousValue.length).trim();
    }

    _clearExternalScannerBuffer();

    if (cleanValue.isEmpty) {
      return;
    }

    context.read<LiveScannerBloc>().add(
      LiveScannerExternalValueChanged(cleanValue),
    );
  }

  void _clearExternalScannerBuffer() {
    _inputPauseTimer?.cancel();
    _inputPauseTimer = null;

    if (_merchandiseController.text.isEmpty) {
      return;
    }

    _isClearingExternalInput = true;
    _merchandiseController.clear();
    _isClearingExternalInput = false;
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
