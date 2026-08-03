import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'WareTrack Mini'**
  String get appTitle;

  /// No description provided for @brQrScanner.
  ///
  /// In en, this message translates to:
  /// **'BR/QR Scanner'**
  String get brQrScanner;

  /// No description provided for @ocrScanner.
  ///
  /// In en, this message translates to:
  /// **'OCR Scanner'**
  String get ocrScanner;

  /// No description provided for @scanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scanner;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get scan;

  /// No description provided for @scanDetails.
  ///
  /// In en, this message translates to:
  /// **'Scan Details'**
  String get scanDetails;

  /// No description provided for @pleaseScan.
  ///
  /// In en, this message translates to:
  /// **'Please scan'**
  String get pleaseScan;

  /// No description provided for @scanBarcodeQr.
  ///
  /// In en, this message translates to:
  /// **'Barcode / QR Code'**
  String get scanBarcodeQr;

  /// No description provided for @scanOcrText.
  ///
  /// In en, this message translates to:
  /// **'Text for OCR'**
  String get scanOcrText;

  /// No description provided for @scanExternal.
  ///
  /// In en, this message translates to:
  /// **'With external scanner'**
  String get scanExternal;

  /// No description provided for @productSearch.
  ///
  /// In en, this message translates to:
  /// **'Product\nSearch'**
  String get productSearch;

  /// No description provided for @shuttleName.
  ///
  /// In en, this message translates to:
  /// **'Shuttle Name'**
  String get shuttleName;

  /// No description provided for @shuttleGate.
  ///
  /// In en, this message translates to:
  /// **'Shuttle Gate'**
  String get shuttleGate;

  /// No description provided for @merchandise.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get merchandise;

  /// No description provided for @brQr.
  ///
  /// In en, this message translates to:
  /// **'BR/QR'**
  String get brQr;

  /// No description provided for @ocr.
  ///
  /// In en, this message translates to:
  /// **'OCR'**
  String get ocr;

  /// No description provided for @unableToOpenCamera.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the camera.'**
  String get unableToOpenCamera;

  /// No description provided for @scanningInProgress.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanningInProgress;

  /// No description provided for @scanningStopped.
  ///
  /// In en, this message translates to:
  /// **'Scanning stopped'**
  String get scanningStopped;

  /// No description provided for @readyExternalScanner.
  ///
  /// In en, this message translates to:
  /// **'Waiting for external scanner input.'**
  String get readyExternalScanner;

  /// No description provided for @capturingOcr.
  ///
  /// In en, this message translates to:
  /// **'Capturing OCR from the current camera preview...'**
  String get capturingOcr;

  /// No description provided for @externalScanReceived.
  ///
  /// In en, this message translates to:
  /// **'External scan received.'**
  String get externalScanReceived;

  /// No description provided for @unableCaptureOcr.
  ///
  /// In en, this message translates to:
  /// **'Unable to capture the current camera preview for OCR.'**
  String get unableCaptureOcr;

  /// No description provided for @unableProcessOcr.
  ///
  /// In en, this message translates to:
  /// **'Unable to process OCR from the current camera preview.'**
  String get unableProcessOcr;

  /// No description provided for @noReadableText.
  ///
  /// In en, this message translates to:
  /// **'No readable text was found.'**
  String get noReadableText;

  /// No description provided for @ocrTextDetected.
  ///
  /// In en, this message translates to:
  /// **'OCR text detected.'**
  String get ocrTextDetected;

  /// No description provided for @codeDetected.
  ///
  /// In en, this message translates to:
  /// **'Code detected.'**
  String get codeDetected;

  /// No description provided for @scanFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed.'**
  String get scanFailed;

  /// No description provided for @noCompatibleCamera.
  ///
  /// In en, this message translates to:
  /// **'No compatible camera was found. On an emulator, enable the virtual back camera, or try on a physical device.'**
  String get noCompatibleCamera;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @scannerSettings.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scannerSettings;

  /// No description provided for @saveTransfer.
  ///
  /// In en, this message translates to:
  /// **'Save & Transfer'**
  String get saveTransfer;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'App Name'**
  String get appName;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get bangla;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @scanSound.
  ///
  /// In en, this message translates to:
  /// **'Scan Sound'**
  String get scanSound;

  /// No description provided for @autoScan.
  ///
  /// In en, this message translates to:
  /// **'Auto Scan'**
  String get autoScan;

  /// No description provided for @duplicateProtection.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Scan Protection'**
  String get duplicateProtection;

  /// No description provided for @cameraReset.
  ///
  /// In en, this message translates to:
  /// **'Reset camera after detection'**
  String get cameraReset;

  /// No description provided for @fastScanMode.
  ///
  /// In en, this message translates to:
  /// **'Fast Scan Mode'**
  String get fastScanMode;

  /// No description provided for @saveFormat.
  ///
  /// In en, this message translates to:
  /// **'Save Format'**
  String get saveFormat;

  /// No description provided for @csv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get csv;

  /// No description provided for @tsv.
  ///
  /// In en, this message translates to:
  /// **'TSV'**
  String get tsv;

  /// No description provided for @excel.
  ///
  /// In en, this message translates to:
  /// **'Excel'**
  String get excel;

  /// No description provided for @transferMethod.
  ///
  /// In en, this message translates to:
  /// **'Transfer Destination Settings'**
  String get transferMethod;

  /// No description provided for @emailTransfer.
  ///
  /// In en, this message translates to:
  /// **'Email Transfer'**
  String get emailTransfer;

  /// No description provided for @serverUpload.
  ///
  /// In en, this message translates to:
  /// **'Server Upload'**
  String get serverUpload;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @uploadUrl.
  ///
  /// In en, this message translates to:
  /// **'Upload URL'**
  String get uploadUrl;

  /// No description provided for @transferDestination.
  ///
  /// In en, this message translates to:
  /// **'Transfer Destination'**
  String get transferDestination;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current Language'**
  String get currentLanguage;

  /// No description provided for @currentTheme.
  ///
  /// In en, this message translates to:
  /// **'Current Theme'**
  String get currentTheme;

  /// No description provided for @deviceInformation.
  ///
  /// In en, this message translates to:
  /// **'Device Information'**
  String get deviceInformation;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address.'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid upload URL.'**
  String get invalidUrl;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved.'**
  String get settingsSaved;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;

  /// No description provided for @receiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving'**
  String get receiving;

  /// No description provided for @receivingSlip.
  ///
  /// In en, this message translates to:
  /// **'Receiving Slip'**
  String get receivingSlip;

  /// No description provided for @receivingScanner.
  ///
  /// In en, this message translates to:
  /// **'Receiving Scanner'**
  String get receivingScanner;

  /// No description provided for @shelfPlacement.
  ///
  /// In en, this message translates to:
  /// **'Shelf Placement'**
  String get shelfPlacement;

  /// No description provided for @stocktaking.
  ///
  /// In en, this message translates to:
  /// **'Stocktaking'**
  String get stocktaking;

  /// No description provided for @movement.
  ///
  /// In en, this message translates to:
  /// **'Shelf Movement Inspection'**
  String get movement;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @savedFileList.
  ///
  /// In en, this message translates to:
  /// **'Saved File List'**
  String get savedFileList;

  /// No description provided for @initialSettings.
  ///
  /// In en, this message translates to:
  /// **'Initial Setup'**
  String get initialSettings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @systemTitle.
  ///
  /// In en, this message translates to:
  /// **'WareTrack Mini'**
  String get systemTitle;

  /// No description provided for @operationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Barcode, QR, OCR & Inspection Operations'**
  String get operationsDescription;

  /// No description provided for @codeVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Please paste the approval code you copied before downloading this app. If you don\'t know your approval code, check the download system.'**
  String get codeVerificationDescription;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @codeVerification.
  ///
  /// In en, this message translates to:
  /// **'Approval Code Verification'**
  String get codeVerification;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Approval Code'**
  String get code;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get submit;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @currentOperator.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get currentOperator;

  /// No description provided for @slipOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Slip / Order Number'**
  String get slipOrderNumber;

  /// No description provided for @scanSlipOrderPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please scan the slip/order number.'**
  String get scanSlipOrderPrompt;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @slipOnly.
  ///
  /// In en, this message translates to:
  /// **'Slip'**
  String get slipOnly;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noInspectionData.
  ///
  /// In en, this message translates to:
  /// **'No inspection data.'**
  String get noInspectionData;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @inspectionReset.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get inspectionReset;

  /// No description provided for @inspectionResetFirstRow.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get inspectionResetFirstRow;

  /// No description provided for @inspectionResetOtherRow.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get inspectionResetOtherRow;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectEdit.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectEdit;

  /// No description provided for @slipNumber.
  ///
  /// In en, this message translates to:
  /// **'Slip Number'**
  String get slipNumber;

  /// No description provided for @barcodeQr.
  ///
  /// In en, this message translates to:
  /// **'Barcode / QR'**
  String get barcodeQr;

  /// No description provided for @inspectionQuantity.
  ///
  /// In en, this message translates to:
  /// **'Inspection Quantity'**
  String get inspectionQuantity;

  /// No description provided for @inspectionList.
  ///
  /// In en, this message translates to:
  /// **'Inspection List'**
  String get inspectionList;

  /// No description provided for @excelOrderNo.
  ///
  /// In en, this message translates to:
  /// **'Slip Number'**
  String get excelOrderNo;

  /// No description provided for @excelProductCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get excelProductCode;

  /// No description provided for @excelDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date/Time'**
  String get excelDateTime;

  /// No description provided for @excelUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get excelUserId;

  /// No description provided for @savedWorkList.
  ///
  /// In en, this message translates to:
  /// **'Saved Work List'**
  String get savedWorkList;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @totalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get totalQuantity;

  /// No description provided for @selectedSlip.
  ///
  /// In en, this message translates to:
  /// **'Selected Slip: {slipNumber}'**
  String selectedSlip(Object slipNumber);

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmAction;

  /// No description provided for @completeWork.
  ///
  /// In en, this message translates to:
  /// **'Complete Work'**
  String get completeWork;

  /// No description provided for @undoOneScan.
  ///
  /// In en, this message translates to:
  /// **'Undo 1 Scan'**
  String get undoOneScan;

  /// No description provided for @saveScannedFileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save the scanned file?'**
  String get saveScannedFileConfirmation;

  /// No description provided for @saveScannedDataConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to save the scanned data?'**
  String get saveScannedDataConfirmation;

  /// No description provided for @unsavedFileBackConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Go back without saving the scanned data?'**
  String get unsavedFileBackConfirmation;

  /// No description provided for @changeSlip.
  ///
  /// In en, this message translates to:
  /// **'Change Slip'**
  String get changeSlip;

  /// No description provided for @slipRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the slip/order number.'**
  String get slipRequired;

  /// No description provided for @barcodeRequired.
  ///
  /// In en, this message translates to:
  /// **'There is no data to revert.'**
  String get barcodeRequired;

  /// No description provided for @quantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quantity of 1 or more.'**
  String get quantityRequired;

  /// No description provided for @invalidSlip.
  ///
  /// In en, this message translates to:
  /// **'The slip/order number is incorrect.'**
  String get invalidSlip;

  /// No description provided for @invalidBarcode.
  ///
  /// In en, this message translates to:
  /// **'This barcode/QR is not included in this slip.'**
  String get invalidBarcode;

  /// No description provided for @slipLoaded.
  ///
  /// In en, this message translates to:
  /// **'The receiving inspection list has been loaded.'**
  String get slipLoaded;

  /// No description provided for @inspectionSaved.
  ///
  /// In en, this message translates to:
  /// **'The receiving inspection result has been saved.'**
  String get inspectionSaved;

  /// No description provided for @scannedProductChanged.
  ///
  /// In en, this message translates to:
  /// **'The scanned product has been changed.'**
  String get scannedProductChanged;

  /// No description provided for @workCompleted.
  ///
  /// In en, this message translates to:
  /// **'The work has been saved.'**
  String get workCompleted;

  /// No description provided for @noScanDataToUndo.
  ///
  /// In en, this message translates to:
  /// **'There is no data to revert.'**
  String get noScanDataToUndo;

  /// No description provided for @resetInspectionItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'The quantity will be set to 0. Are you sure?'**
  String get resetInspectionItemConfirmation;

  /// No description provided for @deleteInspectionItemConfirmation.
  ///
  /// In en, this message translates to:
  /// **'The selected row will be deleted. Are you sure?'**
  String get deleteInspectionItemConfirmation;

  /// No description provided for @deleteReceivingWorkConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this order and all its inspection list data?'**
  String get deleteReceivingWorkConfirmation;

  /// No description provided for @deleteSavedFileConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get deleteSavedFileConfirmation;

  /// No description provided for @downloadExcelConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to download this Excel file?'**
  String get downloadExcelConfirmation;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @workDeleted.
  ///
  /// In en, this message translates to:
  /// **'The saved work has been deleted.'**
  String get workDeleted;

  /// No description provided for @workDownloaded.
  ///
  /// In en, this message translates to:
  /// **'The Excel file has been downloaded.'**
  String get workDownloaded;

  /// No description provided for @emailAddressNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The destination email address is not configured. Please set it from the Initial Setup menu.'**
  String get emailAddressNotConfigured;

  /// No description provided for @deviceVerificationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Device verification information not found. Please verify again.'**
  String get deviceVerificationNotFound;

  /// No description provided for @sendMailFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'The file to send could not be found.'**
  String get sendMailFileNotFound;

  /// No description provided for @sendMailFileEmpty.
  ///
  /// In en, this message translates to:
  /// **'The file to send is empty.'**
  String get sendMailFileEmpty;

  /// No description provided for @sendMailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sent successfully to the configured email address.'**
  String get sendMailSuccess;

  /// No description provided for @emailSendErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Error'**
  String get emailSendErrorTitle;

  /// No description provided for @workSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send the email. Please try again.'**
  String get workSendFailed;

  /// No description provided for @workDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download the Excel file.'**
  String get workDownloadFailed;

  /// No description provided for @helpManual.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpManual;

  /// No description provided for @unableToOpenManual.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the manual.'**
  String get unableToOpenManual;

  /// No description provided for @trialExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your free trial period has ended. Please contact us to continue using the app.'**
  String get trialExpiredMessage;

  /// No description provided for @closeAppButton.
  ///
  /// In en, this message translates to:
  /// **'Close App'**
  String get closeAppButton;

  /// No description provided for @authCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the authentication code.'**
  String get authCodeRequired;

  /// No description provided for @authCodeInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter the authentication code as 8 digits.'**
  String get authCodeInvalidFormat;

  /// No description provided for @approvalCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the approval code.'**
  String get approvalCodeRequired;

  /// No description provided for @approvalCodeVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'The approval code has been verified successfully.'**
  String get approvalCodeVerifiedMessage;

  /// No description provided for @codeVerificationSettingDescription.
  ///
  /// In en, this message translates to:
  /// **'If your registered device is removed from the download system, you do not need to re-download or reinstall the app. Enter the approval code for the currently installed app to re-register the device.'**
  String get codeVerificationSettingDescription;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.\nPlease check your connection and try again.'**
  String get offlineMessage;

  /// No description provided for @deviceIdRetrievalFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to retrieve the device ID.\nPlease try again.'**
  String get deviceIdRetrievalFailed;

  /// No description provided for @authenticationFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authenticationFailedRetry;

  /// No description provided for @trialStatusCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to check the trial status.'**
  String get trialStatusCheckFailed;

  /// No description provided for @emailSubjectExport.
  ///
  /// In en, this message translates to:
  /// **'Smartphone Handy Export File'**
  String get emailSubjectExport;

  /// No description provided for @emailBodyExport.
  ///
  /// In en, this message translates to:
  /// **'The export file is attached. Please review it.'**
  String get emailBodyExport;

  /// No description provided for @shelfNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Shelf Number'**
  String get shelfNumberLabel;

  /// No description provided for @scanShelfNumberFirst.
  ///
  /// In en, this message translates to:
  /// **'Please scan the shelf number first.'**
  String get scanShelfNumberFirst;

  /// No description provided for @invalidShelfNumberEntry.
  ///
  /// In en, this message translates to:
  /// **'The shelf number is incorrect.'**
  String get invalidShelfNumberEntry;

  /// No description provided for @incompleteShelfPlacementData.
  ///
  /// In en, this message translates to:
  /// **'There is incomplete shelf placement data.'**
  String get incompleteShelfPlacementData;

  /// No description provided for @shelfPlacementSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the shelf placement data.'**
  String get shelfPlacementSaveFailed;

  /// No description provided for @shelfPlacementScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shelf Placement Barcode Inspection'**
  String get shelfPlacementScanSubtitle;

  /// No description provided for @stocktakingScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stocktaking Barcode Inspection'**
  String get stocktakingScanSubtitle;

  /// No description provided for @shelfMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'Shelf match:'**
  String get shelfMatchLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
