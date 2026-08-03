import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_state.dart';

void main() {
  test(
    'latest scanned value remains visible when transient input is cleared',
    () {
      const scannerOption = ScannerOption(
        key: 'test',
        title: 'Test scanner',
        subtitle: '',
        formats: [ScannerFormat.qrCode],
        colorValue: 0,
      );
      const state = LiveScannerState(
        scannerOption: scannerOption,
        activeMode: ScannerMode.brQr,
      );

      final scannedState = state.copyWith(
        merchandiseValue: 'LONG-QR-VALUE',
        latestScannedValue: 'LONG-QR-VALUE',
      );
      final nextScanState = scannedState.copyWith(merchandiseValue: '');

      expect(nextScanState.merchandiseValue, isEmpty);
      expect(nextScanState.latestScannedValue, 'LONG-QR-VALUE');
    },
  );
}
