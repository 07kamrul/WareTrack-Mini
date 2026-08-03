import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_loading_widget.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_overlay.dart';

typedef ScannerDetectCallback =
    void Function(
      BarcodeCapture capture, {
      Rect? scanWindow,
      Size? previewSize,
      BoxFit previewFit,
    });

class ScannerCameraPreview extends StatelessWidget {
  const ScannerCameraPreview({
    super.key,
    required this.boundaryKey,
    required this.controller,
    required this.isCameraReady,
    required this.isExternalScannerMode,
    required this.isOcrMode,
    required this.borderRadius,
    required this.previewHeight,
    required this.cameraErrorMessage,
    required this.onDetect,
    required this.onDetectError,
  });

  final GlobalKey boundaryKey;
  final MobileScannerController controller;
  final bool isCameraReady;
  final bool isExternalScannerMode;
  final bool isOcrMode;
  final double borderRadius;
  final double previewHeight;
  final String cameraErrorMessage;
  final ScannerDetectCallback onDetect;
  final VoidCallback onDetectError;

  @override
  Widget build(BuildContext context) {
    const previewFit = BoxFit.cover;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.black,
        border: Border.all(color: Colors.grey[800] ?? Colors.grey, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          height: previewHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: boundaryKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final previewSize = constraints.biggest;
                    final scanWindow = ScannerOverlayGeometry.frameRectFor(
                      previewSize,
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (isExternalScannerMode)
                          const ColoredBox(color: Colors.white)
                        else
                          Stack(
                            fit: StackFit.expand,
                            children: [
                              MobileScanner(
                                key: ObjectKey(controller),
                                controller: controller,
                                fit: previewFit,
                                tapToFocus: true,
                                onDetect: (capture) {
                                  onDetect(
                                    capture,
                                    scanWindow: scanWindow,
                                    previewSize: previewSize,
                                    previewFit: previewFit,
                                  );
                                },
                                onDetectError: (_, _) => onDetectError(),
                                placeholderBuilder: (_) =>
                                    const ScannerLoadingWidget(),
                                errorBuilder: (_, _) {
                                  return ScannerCameraErrorView(
                                    message: cameraErrorMessage,
                                  );
                                },
                              ),
                              if (!isCameraReady) const ScannerLoadingWidget(),
                            ],
                          ),
                        if (isOcrMode) ScannerOverlay(isOcrMode: isOcrMode),
                      ],
                    );
                  },
                ),
              ),
              if (!isExternalScannerMode && isCameraReady)
                Positioned(
                  top: 12,
                  right: 12,
                  child: ScannerTorchButton(controller: controller),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScannerTorchButton extends StatelessWidget {
  const ScannerTorchButton({super.key, required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        if (!state.isInitialized ||
            !state.isRunning ||
            state.torchState == TorchState.unavailable) {
          return const SizedBox.shrink();
        }

        final isTorchOn = state.torchState == TorchState.on;

        return Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: isTorchOn ? 'Turn flashlight off' : 'Turn flashlight on',
            color: isTorchOn ? Colors.amber : Colors.white,
            icon: Icon(isTorchOn ? Icons.flashlight_on : Icons.flashlight_off),
            onPressed: controller.toggleTorch,
          ),
        );
      },
    );
  }
}

class ScannerCameraErrorView extends StatelessWidget {
  const ScannerCameraErrorView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class ScannerStatusBanner extends StatelessWidget {
  const ScannerStatusBanner({
    super.key,
    required this.notice,
    required this.isScanning,
    required this.borderRadius,
    required this.minHeight,
  });

  final String notice;
  final bool isScanning;
  final double borderRadius;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    const statusMinHeight = 20.0;
    const statusVerticalPadding = 3.0;

    return Container(
      constraints: const BoxConstraints(minHeight: statusMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: statusVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: isScanning ? Colors.green[400] : Colors.red[400],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          notice,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
