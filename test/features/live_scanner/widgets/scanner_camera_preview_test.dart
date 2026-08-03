import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:waretrack_mini/features/receiving/widgets/scanner_camera_preview.dart';

void main() {
  testWidgets('torch button is hidden until a supported camera is running', (
    tester,
  ) async {
    final controller = MobileScannerController(autoStart: false);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byType(IconButton), findsNothing);

    controller.value = _scannerState(torchState: TorchState.unavailable);
    await tester.pump();

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('torch button icon reflects the current torch state', (
    tester,
  ) async {
    final controller = MobileScannerController(autoStart: false);
    addTearDown(controller.dispose);

    controller.value = _scannerState(torchState: TorchState.off);
    await tester.pumpWidget(_TestApp(controller: controller));

    expect(find.byIcon(Icons.flashlight_off), findsOneWidget);
    expect(find.byIcon(Icons.flashlight_on), findsNothing);

    controller.value = _scannerState(torchState: TorchState.on);
    await tester.pump();

    expect(find.byIcon(Icons.flashlight_off), findsNothing);
    expect(find.byIcon(Icons.flashlight_on), findsOneWidget);
  });
}

MobileScannerState _scannerState({required TorchState torchState}) {
  return MobileScannerState(
    availableCameras: 1,
    cameraDirection: CameraFacing.back,
    cameraLensType: CameraLensType.any,
    isInitialized: true,
    isStarting: false,
    isRunning: true,
    size: const Size(1280, 720),
    torchState: torchState,
    zoomScale: 1,
    deviceOrientation: DeviceOrientation.portraitUp,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: ScannerTorchButton(controller: controller)),
    );
  }
}
