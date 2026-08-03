import 'package:flutter/material.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_bloc.dart';
import 'package:waretrack_mini/features/receiving/complete_receiving_work_use_case.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/load_receiving_completed_work_items_use_case.dart';
import 'package:waretrack_mini/features/receiving/pages/receiving_selection_page.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/shipping/services/shipping_service.dart';

class ShippingSelectionPage extends StatelessWidget {
  const ShippingSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ReceivingSelectionPage(
      titleBuilder: (localizations) => localizations.shipping,
      blocFactory: createShippingBloc,
    );
  }
}

ReceivingBloc createShippingBloc() {
  final service = sl<ShippingService>();
  return ReceivingBloc(
    recordScan: RecordReceivingScanUseCase(service),
    completeWork: CompleteReceivingWorkUseCase(service),
    loadCompletedWorkItems: LoadReceivingCompletedWorkItemsUseCase(service),
    resetItem: ResetReceivingInspectionItemUseCase(service),
    deleteItem: DeleteReceivingInspectionItemUseCase(service),
    undoScan: UndoReceivingScanUseCase(service),
    discardTemporaryWork: service.discardTemporaryWork,
    readCompletedWorks: service.readCompletedWorks,
    feedbackService: sl<ScanFeedbackService>(),
  );
}

String shippingTitle(AppLocalizations localizations) => localizations.shipping;
