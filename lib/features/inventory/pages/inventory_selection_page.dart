import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/features/inventory/bloc/inventory_bloc.dart';
import 'package:waretrack_mini/features/inventory/services/inventory_service.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/stocking/pages/stocking_scan_page.dart';

class InventorySelectionPage extends StatelessWidget {
  const InventorySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StockingScanPage(
      titleBuilder: inventoryTitle,
      blocFactory: _createInventoryBloc,
      scannerOption: _inventoryScannerOption,
    );
  }
}

InventoryBloc _createInventoryBloc() {
  final service = sl<InventoryService>();
  return InventoryBloc(
    recordScan: RecordReceivingScanUseCase(service),
    completeWork: service.completeSession,
    resetItem: ResetReceivingInspectionItemUseCase(service),
    deleteItem: DeleteReceivingInspectionItemUseCase(service),
    undoScan: UndoReceivingScanUseCase(service),
    discardTemporaryWork: service.discardTemporaryWork,
    feedbackService: sl<ScanFeedbackService>(),
  );
}

String inventoryTitle(AppLocalizations localizations) =>
    localizations.stocktaking;

const ScannerOption _inventoryScannerOption = ScannerOption(
  key: 'inventory',
  title: '棚卸',
  subtitle: '棚卸バーコード検品',
  formats: [
    ScannerFormat.qrCode,
    ScannerFormat.code39,
    ScannerFormat.codabar,
    ScannerFormat.code128,
    ScannerFormat.ean13,
    ScannerFormat.itf2of5,
    ScannerFormat.itf14,
  ],
  colorValue: 0xFF005F73,
  playDetectionSuccessSound: false,
);
