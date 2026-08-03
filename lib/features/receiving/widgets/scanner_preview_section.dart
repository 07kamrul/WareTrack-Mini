import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_camera_preview.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_layout_metrics.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_scan_button.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_toolbar.dart';

class ScannerPreviewSection extends StatelessWidget {
  const ScannerPreviewSection({
    super.key,
    required this.state,
    required this.controller,
    required this.metrics,
    required this.boundaryKey,
    required this.autoScan,
    required this.notice,
    required this.cameraErrorMessage,
    required this.onScanPressed,
    required this.onModeChanged,
    required this.onDetect,
    required this.onDetectError,
    this.instruction,
    this.inlineNotice,
    this.showScannedValue = true,
    this.leadingAction,
    this.trailingAction,
  });

  final LiveScannerState state;
  final MobileScannerController controller;
  final ScannerLayoutMetrics metrics;
  final GlobalKey boundaryKey;
  final bool autoScan;
  final String notice;
  final String cameraErrorMessage;
  final VoidCallback onScanPressed;
  final ValueChanged<ScannerMode> onModeChanged;
  final ScannerDetectCallback onDetect;
  final VoidCallback onDetectError;
  final String? instruction;
  final String? inlineNotice;
  final bool showScannedValue;
  final Widget? leadingAction;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!state.isExternalScannerMode) ...[
          ScannerCameraPreview(
            boundaryKey: boundaryKey,
            controller: controller,
            isCameraReady: state.isCameraReady,
            isExternalScannerMode: state.isExternalScannerMode,
            isOcrMode: state.isOcrMode,
            borderRadius: metrics.cardRadius,
            previewHeight: metrics.previewHeight,
            cameraErrorMessage: cameraErrorMessage,
            onDetect: onDetect,
            onDetectError: onDetectError,
          ),
          SizedBox(height: metrics.componentGap),
          ScannerStatusBanner(
            notice: notice,
            isScanning: state.isScanning,
            borderRadius: metrics.innerRadius,
            minHeight: metrics.bannerHeight,
          ),
          SizedBox(height: metrics.componentGap),
        ],
        if (inlineNotice case final notice?) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(metrics.innerRadius),
            ),
            child: Text(
              notice,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: metrics.componentGap),
        ],
        if (showScannedValue) ...[
          ScannerValueDisplay(
            value: state.latestScannedValue,
            borderRadius: metrics.innerRadius,
          ),
          SizedBox(height: metrics.componentGap),
        ],
        ScannerToolbar(
          activeMode: state.activeMode,
          enableScannerMode: state.canUseExternalScannerMode,
          onModeChanged: onModeChanged,
          gap: metrics.modeGap,
          buttonHeight: metrics.buttonHeight,
          borderRadius: metrics.innerRadius,
        ),
        if (!state.isExternalScannerMode) ...[
          SizedBox(height: metrics.componentGap),
          if (instruction != null) ...[
            Text(
              instruction!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: metrics.componentGap),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: leadingAction,
                ),
              ),
              const SizedBox(width: 8),
              ScannerScanButton(
                label: AppLocalizations.of(context).scan,
                onPressed: autoScan ? null : onScanPressed,
                borderRadius: metrics.innerRadius,
                minHeight: metrics.buttonHeight + 10,
                minWidth: 150,
                horizontalPadding: 20,
                verticalPadding: 12,
                fontSize: 30,
                expandHorizontally: false,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: trailingAction,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class ScannerValueDisplay extends StatelessWidget {
  const ScannerValueDisplay({
    super.key,
    required this.value,
    required this.borderRadius,
  });

  final String value;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        value,
        softWrap: true,
        overflow: TextOverflow.visible,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      ),
    );
  }
}
