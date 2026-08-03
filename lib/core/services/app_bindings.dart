import 'package:waretrack_mini/core/services/export_file_service.dart';
import 'package:waretrack_mini/core/services/completed_work_service.dart';
import 'package:waretrack_mini/core/database/app_database.dart';
import 'package:waretrack_mini/core/models/inspection_work_type.dart';
import 'package:waretrack_mini/core/services/scan_feedback_service.dart';
import 'package:waretrack_mini/core/services/local_storage_update_service.dart';
import 'package:waretrack_mini/core/utils/app_settings.dart';
import 'package:waretrack_mini/core/services/storage_service.dart';
import 'package:waretrack_mini/data/local/ocr_repository_service.dart';
import 'package:waretrack_mini/data/local/receiving_repository_service.dart';
import 'package:waretrack_mini/data/local/text_recognition_local_data_source.dart';
import 'package:waretrack_mini/data/models/scanner_option.dart';
import 'package:waretrack_mini/data/local/ocr_repository.dart';
import 'package:waretrack_mini/data/local/receiving_repository.dart';
import 'package:waretrack_mini/features/inventory/services/inventory_service.dart';
import 'package:waretrack_mini/core/services/process_ocr_image_use_case.dart';
import 'package:waretrack_mini/features/receiving/complete_receiving_work_use_case.dart';
import 'package:waretrack_mini/features/receiving/delete_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/load_receiving_completed_work_items_use_case.dart';
import 'package:waretrack_mini/features/receiving/record_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/reset_receiving_inspection_item_use_case.dart';
import 'package:waretrack_mini/features/receiving/undo_receiving_scan_use_case.dart';
import 'package:waretrack_mini/features/receiving/bloc/live_scanner_bloc.dart';
import 'package:waretrack_mini/features/receiving/bloc/receiving_bloc.dart';
import 'package:waretrack_mini/features/settings/bloc/settings_bloc.dart';
import 'package:waretrack_mini/features/shipping/services/shipping_service.dart';
import 'package:waretrack_mini/features/stocking/services/stocking_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  if (sl.isRegistered<ProcessOcrImageUseCase>()) {
    return;
  }

  final preferences = await SharedPreferences.getInstance();
  await LocalStorageUpdateService.clearAfterAppUpdate(preferences);
  await LocalStorageUpdateService.clearOnEnvironmentChange(preferences);
  final localStorage = SharedPreferencesLocalStorage(preferences);
  final settingsRepository = AppSettingsRepository(localStorage);
  final settings = await settingsRepository.load();

  sl.registerLazySingleton<ScanFeedbackService>(() => ScanFeedbackService());
  sl.registerLazySingleton<ExportFileService>(() => const ExportFileService());
  sl.registerLazySingleton<LocalStorage>(() => localStorage);
  sl.registerLazySingleton<AppSettingsRepository>(() => settingsRepository);
  sl.registerLazySingleton<AppSettingsController>(
    () => AppSettingsController(
      repository: sl<AppSettingsRepository>(),
      initialSettings: settings,
    ),
  );

  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(settingsController: sl<AppSettingsController>()),
  );

  sl.registerFactory<TextRecognitionLocalDataSource>(
    () => TextRecognitionLocalDataSourceImpl(),
  );

  sl.registerFactory<OcrRepository>(
    () => OcrRepositoryImpl(
      localDataSource: sl<TextRecognitionLocalDataSource>(),
    ),
  );

  sl.registerFactory<ProcessOcrImageUseCase>(
    () => ProcessOcrImageUseCase(sl<OcrRepository>()),
  );

  sl.registerLazySingleton<AppDatabase>(() => SqfliteAppDatabase());
  sl.registerLazySingleton<CompletedWorkService>(
    () => CompletedWorkService(
      database: sl<AppDatabase>(),
      exportFileService: sl<ExportFileService>(),
      settingsController: sl<AppSettingsController>(),
      localStorage: sl<LocalStorage>(),
    ),
  );

  sl.registerLazySingleton<ReceivingRepository>(
    () => ReceivingRepositoryImpl(
      localStorage: sl<LocalStorage>(),
      database: sl<AppDatabase>(),
    ),
  );

  sl.registerLazySingleton<ShippingService>(
    () => ShippingService(
      repository: ReceivingRepositoryImpl(
        localStorage: sl<LocalStorage>(),
        database: sl<AppDatabase>(),
        workType: InspectionWorkType.shipping,
      ),
    ),
  );

  sl.registerLazySingleton<StockingService>(
    () => StockingService(
      repository: ReceivingRepositoryImpl(
        localStorage: sl<LocalStorage>(),
        database: sl<AppDatabase>(),
        workType: InspectionWorkType.stocking,
      ),
      database: sl<AppDatabase>(),
      localStorage: sl<LocalStorage>(),
    ),
  );

  sl.registerLazySingleton<InventoryService>(
    () => InventoryService(
      repository: ReceivingRepositoryImpl(
        localStorage: sl<LocalStorage>(),
        database: sl<AppDatabase>(),
        workType: InspectionWorkType.inventory,
      ),
      database: sl<AppDatabase>(),
      localStorage: sl<LocalStorage>(),
    ),
  );

  sl.registerFactory<RecordReceivingScanUseCase>(
    () => RecordReceivingScanUseCase(sl<ReceivingRepository>()),
  );
  sl.registerFactory<CompleteReceivingWorkUseCase>(
    () => CompleteReceivingWorkUseCase(sl<ReceivingRepository>()),
  );
  sl.registerFactory<LoadReceivingCompletedWorkItemsUseCase>(
    () => LoadReceivingCompletedWorkItemsUseCase(sl<ReceivingRepository>()),
  );
  sl.registerFactory<ResetReceivingInspectionItemUseCase>(
    () => ResetReceivingInspectionItemUseCase(sl<ReceivingRepository>()),
  );
  sl.registerFactory<DeleteReceivingInspectionItemUseCase>(
    () => DeleteReceivingInspectionItemUseCase(sl<ReceivingRepository>()),
  );
  sl.registerFactory<UndoReceivingScanUseCase>(
    () => UndoReceivingScanUseCase(sl<ReceivingRepository>()),
  );
  sl.registerFactory<ReceivingBloc>(
    () => ReceivingBloc(
      recordScan: sl<RecordReceivingScanUseCase>(),
      completeWork: sl<CompleteReceivingWorkUseCase>(),
      loadCompletedWorkItems: sl<LoadReceivingCompletedWorkItemsUseCase>(),

      resetItem: sl<ResetReceivingInspectionItemUseCase>(),
      deleteItem: sl<DeleteReceivingInspectionItemUseCase>(),
      undoScan: sl<UndoReceivingScanUseCase>(),

      discardTemporaryWork: sl<ReceivingRepository>().discardTemporaryWork,
      readCompletedWorks: sl<ReceivingRepository>().readCompletedWorks,

      feedbackService: sl<ScanFeedbackService>(),
    ),
  );

  sl.registerFactoryParam<LiveScannerBloc, ScannerOption, void>(
    (scannerOption, _) => LiveScannerBloc(
      scannerOption,
      settingsController: sl<AppSettingsController>(),
      scanFeedbackService: sl<ScanFeedbackService>(),
      processOcrImageUseCase: sl<ProcessOcrImageUseCase>(),
    ),
  );
}
