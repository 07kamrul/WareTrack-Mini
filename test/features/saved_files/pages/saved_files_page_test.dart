import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/services/app_bindings.dart';
import 'package:waretrack_mini/core/services/completed_work_service.dart';
import 'package:waretrack_mini/core/services/export_file_service.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/models/receiving_completed_work.dart';
import 'package:waretrack_mini/features/main_menu/widgets/menu_item.dart';
import 'package:waretrack_mini/features/saved_files/pages/saved_files_page.dart';
import 'package:waretrack_mini/core/utils/localization/app_localizations.dart';

Finder findVisibleText(String expected) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.data?.replaceAll('⁠', '') == expected,
  );
}

void main() {
  testWidgets('stocking View loads saved rows from SQLite details', (
    tester,
  ) async {
    final database = _FakeAppDatabase(showStockingWork: true);
    final storage = _FakeLocalStorage();
    final settingsController = AppSettingsController(
      repository: AppSettingsRepository(storage),
      initialSettings: const AppSettings(),
    );
    sl.registerSingleton<CompletedWorkService>(
      CompletedWorkService(
        database: database,
        exportFileService: const ExportFileService(),
        settingsController: settingsController,
        localStorage: storage,
      ),
    );
    addTearDown(sl.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('en'), Locale('bn')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: SavedFilesPage(
          arguments: SavedFilesArguments(action: MainMenuAction.savedFiles),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ShelfPlacement20260623143045'), findsOneWidget);
    final stockingCard = find.ancestor(
      of: find.text('ShelfPlacement20260623143045'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(of: stockingCard, matching: find.text('View')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shelf Number'), findsOneWidget);
    expect(find.text('Barcode / QR'), findsOneWidget);
    expect(find.text('Inspection Quantity'), findsOneWidget);
    expect(find.textContaining('Shelf match'), findsNothing);
    expect(find.text('Date/Time'), findsNothing);
    expect(find.text('User ID'), findsNothing);
    expect(find.text('abc'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('user-007'), findsNothing);
    expect(database.detailsReadCount, 1);
  });
}

final class _FakeAppDatabase implements AppDatabase {
  _FakeAppDatabase({this.showStockingWork = false});

  final bool showStockingWork;
  int detailsReadCount = 0;

  @override
  Future<List<ReceivingCompletedWorkDetail>> readCompletedWorkDetails(
    String slipNumber, {
    required InspectionWorkType workType,
  }) async {
    detailsReadCount++;
    if (showStockingWork && workType == InspectionWorkType.stocking) {
      return [
        ReceivingCompletedWorkDetail(
          slipNumber: 'abc',
          code: '123',
          quantity: 2,
          createdAt: DateTime(2026, 1, 2, 3, 4, 5),
          userId: 'user-007',
          workType: InspectionWorkType.stocking,
        ),
      ];
    }
    return const <ReceivingCompletedWorkDetail>[];
  }

  @override
  Future<List<ReceivingCompletedWork>> readCompletedWorks({
    required InspectionWorkType workType,
  }) async {
    if (showStockingWork && workType == InspectionWorkType.stocking) {
      return <ReceivingCompletedWork>[
        ReceivingCompletedWork(
          slipNumber: 'ShelfPlacement20260623143045',
          totalItems: 1,
          totalQuantity: 2,
          completedAt: DateTime(2026, 1, 2, 3, 4, 5),
          workType: InspectionWorkType.stocking,
        ),
      ];
    }
    if (workType != InspectionWorkType.receiving) {
      return const <ReceivingCompletedWork>[];
    }

    return <ReceivingCompletedWork>[
      ReceivingCompletedWork(
        slipNumber: '49100418503',
        totalItems: 1,
        totalQuantity: 1,
        completedAt: DateTime(2026, 1, 2, 3, 4, 5),
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLocalStorage implements LocalStorage {
  @override
  Future<bool?> readBool(String key) async => null;

  @override
  Future<String?> readString(String key) async => null;

  @override
  Future<void> remove(String key) async {}

  @override
  Future<void> writeBool(String key, bool value) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}
