import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/stocking/bloc/stocking_bloc.dart';
import 'package:waretrack_mini/features/stocking/pages/stocking_scan_page.dart';
import 'package:waretrack_mini/features/stocking/services/stocking_service.dart';

/// Entry point for 棚入れ (Shelf Storage) feature.
class StockingSelectionPage extends StatelessWidget {
  const StockingSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StockingScanPage(
      titleBuilder: (l10n) => l10n.shelfPlacement,
      blocFactory: _createStockingBloc,
    );
  }
}

StockingBloc _createStockingBloc() {
  final service = sl<StockingService>();
  return StockingBloc(
    recordScan: RecordReceivingScanUseCase(service),
    completeWork: service.completeSession,
    resetItem: ResetReceivingInspectionItemUseCase(service),
    deleteItem: DeleteReceivingInspectionItemUseCase(service),
    undoScan: UndoReceivingScanUseCase(service),
    discardTemporaryWork: service.discardTemporaryWork,
    feedbackService: sl<ScanFeedbackService>(),
  );
}

String stockingTitle(AppLocalizations localizations) =>
    localizations.shelfPlacement;
