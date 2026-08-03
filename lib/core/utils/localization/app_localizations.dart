import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('ja')];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'WareTrack Mini'**
  String get appTitle;

  /// No description provided for @brQrScanner.
  ///
  /// In ja, this message translates to:
  /// **'BR/QRスキャナー'**
  String get brQrScanner;

  /// No description provided for @ocrScanner.
  ///
  /// In ja, this message translates to:
  /// **'OCRスキャナー'**
  String get ocrScanner;

  /// No description provided for @scanner.
  ///
  /// In ja, this message translates to:
  /// **'スキャナー'**
  String get scanner;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @scan.
  ///
  /// In ja, this message translates to:
  /// **'スキャン'**
  String get scan;

  /// No description provided for @scanDetails.
  ///
  /// In ja, this message translates to:
  /// **'スキャン詳細'**
  String get scanDetails;

  /// No description provided for @pleaseScan.
  ///
  /// In ja, this message translates to:
  /// **'読み取ってください'**
  String get pleaseScan;

  /// No description provided for @scanBarcodeQr.
  ///
  /// In ja, this message translates to:
  /// **'バーコード／QRコード'**
  String get scanBarcodeQr;

  /// No description provided for @scanOcrText.
  ///
  /// In ja, this message translates to:
  /// **'OCR対象の文字'**
  String get scanOcrText;

  /// No description provided for @scanExternal.
  ///
  /// In ja, this message translates to:
  /// **'外部スキャナーで'**
  String get scanExternal;

  /// No description provided for @productSearch.
  ///
  /// In ja, this message translates to:
  /// **'商品\n検索'**
  String get productSearch;

  /// No description provided for @shuttleName.
  ///
  /// In ja, this message translates to:
  /// **'シャトル名'**
  String get shuttleName;

  /// No description provided for @shuttleGate.
  ///
  /// In ja, this message translates to:
  /// **'シャトルゲート'**
  String get shuttleGate;

  /// No description provided for @merchandise.
  ///
  /// In ja, this message translates to:
  /// **'商品'**
  String get merchandise;

  /// No description provided for @brQr.
  ///
  /// In ja, this message translates to:
  /// **'BR/QR'**
  String get brQr;

  /// No description provided for @ocr.
  ///
  /// In ja, this message translates to:
  /// **'OCR'**
  String get ocr;

  /// No description provided for @unableToOpenCamera.
  ///
  /// In ja, this message translates to:
  /// **'カメラを開けません。'**
  String get unableToOpenCamera;

  /// No description provided for @scanningInProgress.
  ///
  /// In ja, this message translates to:
  /// **'スキャン中'**
  String get scanningInProgress;

  /// No description provided for @scanningStopped.
  ///
  /// In ja, this message translates to:
  /// **'スキャン停止中'**
  String get scanningStopped;

  /// No description provided for @readyExternalScanner.
  ///
  /// In ja, this message translates to:
  /// **'外部スキャナー入力を待機中です。'**
  String get readyExternalScanner;

  /// No description provided for @capturingOcr.
  ///
  /// In ja, this message translates to:
  /// **'現在のカメラプレビューからOCRを取得しています...'**
  String get capturingOcr;

  /// No description provided for @externalScanReceived.
  ///
  /// In ja, this message translates to:
  /// **'外部スキャンを受信しました。'**
  String get externalScanReceived;

  /// No description provided for @unableCaptureOcr.
  ///
  /// In ja, this message translates to:
  /// **'OCR用に現在のカメラプレビューを取得できません。'**
  String get unableCaptureOcr;

  /// No description provided for @unableProcessOcr.
  ///
  /// In ja, this message translates to:
  /// **'現在のカメラプレビューからOCRを処理できません。'**
  String get unableProcessOcr;

  /// No description provided for @noReadableText.
  ///
  /// In ja, this message translates to:
  /// **'読み取れる文字が見つかりませんでした。'**
  String get noReadableText;

  /// No description provided for @ocrTextDetected.
  ///
  /// In ja, this message translates to:
  /// **'OCR文字を検出しました。'**
  String get ocrTextDetected;

  /// No description provided for @codeDetected.
  ///
  /// In ja, this message translates to:
  /// **'コードを検出しました。'**
  String get codeDetected;

  /// No description provided for @scanFailed.
  ///
  /// In ja, this message translates to:
  /// **'スキャンに失敗しました。'**
  String get scanFailed;

  /// No description provided for @noCompatibleCamera.
  ///
  /// In ja, this message translates to:
  /// **'対応するカメラが見つかりません。エミュレーターでは仮想背面カメラを有効にするか、実機でお試しください。'**
  String get noCompatibleCamera;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get theme;

  /// No description provided for @scannerSettings.
  ///
  /// In ja, this message translates to:
  /// **'スキャナー'**
  String get scannerSettings;

  /// No description provided for @saveTransfer.
  ///
  /// In ja, this message translates to:
  /// **'保存・送信'**
  String get saveTransfer;

  /// No description provided for @appInformation.
  ///
  /// In ja, this message translates to:
  /// **'アプリ情報'**
  String get appInformation;

  /// No description provided for @appName.
  ///
  /// In ja, this message translates to:
  /// **'アプリ名'**
  String get appName;

  /// No description provided for @english.
  ///
  /// In ja, this message translates to:
  /// **'英語'**
  String get english;

  /// No description provided for @japanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @lightTheme.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get darkTheme;

  /// No description provided for @scanSound.
  ///
  /// In ja, this message translates to:
  /// **'スキャン音'**
  String get scanSound;

  /// No description provided for @autoScan.
  ///
  /// In ja, this message translates to:
  /// **'自動スキャン'**
  String get autoScan;

  /// No description provided for @duplicateProtection.
  ///
  /// In ja, this message translates to:
  /// **'重複スキャン防止'**
  String get duplicateProtection;

  /// No description provided for @cameraReset.
  ///
  /// In ja, this message translates to:
  /// **'検出後にカメラをリセット'**
  String get cameraReset;

  /// No description provided for @fastScanMode.
  ///
  /// In ja, this message translates to:
  /// **'高速スキャンモード'**
  String get fastScanMode;

  /// No description provided for @saveFormat.
  ///
  /// In ja, this message translates to:
  /// **'保存形式'**
  String get saveFormat;

  /// No description provided for @csv.
  ///
  /// In ja, this message translates to:
  /// **'CSV'**
  String get csv;

  /// No description provided for @tsv.
  ///
  /// In ja, this message translates to:
  /// **'TSV'**
  String get tsv;

  /// No description provided for @excel.
  ///
  /// In ja, this message translates to:
  /// **'Excel'**
  String get excel;

  /// No description provided for @transferMethod.
  ///
  /// In ja, this message translates to:
  /// **'送信先設定'**
  String get transferMethod;

  /// No description provided for @emailTransfer.
  ///
  /// In ja, this message translates to:
  /// **'メール転送'**
  String get emailTransfer;

  /// No description provided for @serverUpload.
  ///
  /// In ja, this message translates to:
  /// **'サーバーアップロード'**
  String get serverUpload;

  /// No description provided for @emailAddress.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get emailAddress;

  /// No description provided for @uploadUrl.
  ///
  /// In ja, this message translates to:
  /// **'アップロードURL'**
  String get uploadUrl;

  /// No description provided for @transferDestination.
  ///
  /// In ja, this message translates to:
  /// **'転送先'**
  String get transferDestination;

  /// No description provided for @appVersion.
  ///
  /// In ja, this message translates to:
  /// **'アプリバージョン'**
  String get appVersion;

  /// No description provided for @currentLanguage.
  ///
  /// In ja, this message translates to:
  /// **'現在の言語'**
  String get currentLanguage;

  /// No description provided for @currentTheme.
  ///
  /// In ja, this message translates to:
  /// **'現在のテーマ'**
  String get currentTheme;

  /// No description provided for @deviceInformation.
  ///
  /// In ja, this message translates to:
  /// **'端末情報'**
  String get deviceInformation;

  /// No description provided for @serialNumber.
  ///
  /// In ja, this message translates to:
  /// **'シリアル番号'**
  String get serialNumber;

  /// No description provided for @optional.
  ///
  /// In ja, this message translates to:
  /// **'任意'**
  String get optional;

  /// No description provided for @emailRequired.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスを入力してください。'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'有効なメールアドレスを入力してください。'**
  String get invalidEmail;

  /// No description provided for @invalidUrl.
  ///
  /// In ja, this message translates to:
  /// **'有効なアップロードURLを入力してください。'**
  String get invalidUrl;

  /// No description provided for @settingsSaved.
  ///
  /// In ja, this message translates to:
  /// **'設定完了しました。'**
  String get settingsSaved;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @mainMenu.
  ///
  /// In ja, this message translates to:
  /// **'メインメニュー'**
  String get mainMenu;

  /// No description provided for @receiving.
  ///
  /// In ja, this message translates to:
  /// **'入荷検品'**
  String get receiving;

  /// No description provided for @receivingSlip.
  ///
  /// In ja, this message translates to:
  /// **'入荷伝票'**
  String get receivingSlip;

  /// No description provided for @receivingScanner.
  ///
  /// In ja, this message translates to:
  /// **'入荷スキャナー'**
  String get receivingScanner;

  /// No description provided for @shelfPlacement.
  ///
  /// In ja, this message translates to:
  /// **'棚入れ'**
  String get shelfPlacement;

  /// No description provided for @stocktaking.
  ///
  /// In ja, this message translates to:
  /// **'棚卸'**
  String get stocktaking;

  /// No description provided for @movement.
  ///
  /// In ja, this message translates to:
  /// **'棚移動検品'**
  String get movement;

  /// No description provided for @shipping.
  ///
  /// In ja, this message translates to:
  /// **'出荷検品'**
  String get shipping;

  /// No description provided for @savedFileList.
  ///
  /// In ja, this message translates to:
  /// **'保存ファイル一覧'**
  String get savedFileList;

  /// No description provided for @initialSettings.
  ///
  /// In ja, this message translates to:
  /// **'初期設定'**
  String get initialSettings;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// No description provided for @systemTitle.
  ///
  /// In ja, this message translates to:
  /// **'WareTrack Mini'**
  String get systemTitle;

  /// No description provided for @operationsDescription.
  ///
  /// In ja, this message translates to:
  /// **'バーコード・QR・OCR・検品業務'**
  String get operationsDescription;

  /// No description provided for @codeVerificationDescription.
  ///
  /// In ja, this message translates to:
  /// **'このアプリをダウンロードする前にコピーした承認コードを貼り付けてください。承認コードがわからない場合は、ダウンロードシステムでご確認ください。'**
  String get codeVerificationDescription;

  /// No description provided for @signIn.
  ///
  /// In ja, this message translates to:
  /// **'サインイン'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In ja, this message translates to:
  /// **'サインアップ'**
  String get signUp;

  /// No description provided for @codeVerification.
  ///
  /// In ja, this message translates to:
  /// **'承認コード確認'**
  String get codeVerification;

  /// No description provided for @code.
  ///
  /// In ja, this message translates to:
  /// **'承認コード'**
  String get code;

  /// No description provided for @submit.
  ///
  /// In ja, this message translates to:
  /// **'確認'**
  String get submit;

  /// No description provided for @employeeId.
  ///
  /// In ja, this message translates to:
  /// **'社員ID'**
  String get employeeId;

  /// No description provided for @password.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In ja, this message translates to:
  /// **'氏名'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワード確認'**
  String get confirmPassword;

  /// No description provided for @createNewAccount.
  ///
  /// In ja, this message translates to:
  /// **'新規アカウント作成'**
  String get createNewAccount;

  /// No description provided for @backToSignIn.
  ///
  /// In ja, this message translates to:
  /// **'サインインへ戻る'**
  String get backToSignIn;

  /// No description provided for @currentOperator.
  ///
  /// In ja, this message translates to:
  /// **'プロフィール'**
  String get currentOperator;

  /// No description provided for @slipOrderNumber.
  ///
  /// In ja, this message translates to:
  /// **'伝票／発注番号'**
  String get slipOrderNumber;

  /// No description provided for @scanSlipOrderPrompt.
  ///
  /// In ja, this message translates to:
  /// **'伝票/発生番号をスキャンしてください。'**
  String get scanSlipOrderPrompt;

  /// No description provided for @hide.
  ///
  /// In ja, this message translates to:
  /// **'非表示'**
  String get hide;

  /// No description provided for @slipOnly.
  ///
  /// In ja, this message translates to:
  /// **'伝票'**
  String get slipOnly;

  /// No description provided for @all.
  ///
  /// In ja, this message translates to:
  /// **'全て'**
  String get all;

  /// No description provided for @noInspectionData.
  ///
  /// In ja, this message translates to:
  /// **'検品データがありません。'**
  String get noInspectionData;

  /// No description provided for @edit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In ja, this message translates to:
  /// **'表示'**
  String get view;

  /// No description provided for @deleteAction.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get deleteAction;

  /// No description provided for @send.
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get send;

  /// No description provided for @fileName.
  ///
  /// In ja, this message translates to:
  /// **'ファイル名'**
  String get fileName;

  /// No description provided for @date.
  ///
  /// In ja, this message translates to:
  /// **'日付'**
  String get date;

  /// No description provided for @download.
  ///
  /// In ja, this message translates to:
  /// **'ダウンロード'**
  String get download;

  /// No description provided for @open.
  ///
  /// In ja, this message translates to:
  /// **'開く'**
  String get open;

  /// No description provided for @action.
  ///
  /// In ja, this message translates to:
  /// **'操作'**
  String get action;

  /// No description provided for @inspectionReset.
  ///
  /// In ja, this message translates to:
  /// **'修正'**
  String get inspectionReset;

  /// No description provided for @inspectionResetFirstRow.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get inspectionResetFirstRow;

  /// No description provided for @inspectionResetOtherRow.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get inspectionResetOtherRow;

  /// No description provided for @select.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get select;

  /// No description provided for @selectEdit.
  ///
  /// In ja, this message translates to:
  /// **'選択'**
  String get selectEdit;

  /// No description provided for @slipNumber.
  ///
  /// In ja, this message translates to:
  /// **'伝票番号'**
  String get slipNumber;

  /// No description provided for @barcodeQr.
  ///
  /// In ja, this message translates to:
  /// **'バーコード／QR'**
  String get barcodeQr;

  /// No description provided for @inspectionQuantity.
  ///
  /// In ja, this message translates to:
  /// **'検品数'**
  String get inspectionQuantity;

  /// No description provided for @inspectionList.
  ///
  /// In ja, this message translates to:
  /// **'検品一覧'**
  String get inspectionList;

  /// No description provided for @excelOrderNo.
  ///
  /// In ja, this message translates to:
  /// **'伝票番号'**
  String get excelOrderNo;

  /// No description provided for @excelProductCode.
  ///
  /// In ja, this message translates to:
  /// **'商品コード'**
  String get excelProductCode;

  /// No description provided for @excelDateTime.
  ///
  /// In ja, this message translates to:
  /// **'日時'**
  String get excelDateTime;

  /// No description provided for @excelUserId.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーID'**
  String get excelUserId;

  /// No description provided for @savedWorkList.
  ///
  /// In ja, this message translates to:
  /// **'保存ファイル一覧'**
  String get savedWorkList;

  /// No description provided for @totalItems.
  ///
  /// In ja, this message translates to:
  /// **'合計明細数'**
  String get totalItems;

  /// No description provided for @totalQuantity.
  ///
  /// In ja, this message translates to:
  /// **'合計数量'**
  String get totalQuantity;

  /// No description provided for @selectedSlip.
  ///
  /// In ja, this message translates to:
  /// **'伝票指定: {slipNumber}'**
  String selectedSlip(Object slipNumber);

  /// No description provided for @status.
  ///
  /// In ja, this message translates to:
  /// **'状態'**
  String get status;

  /// No description provided for @completed.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get completed;

  /// No description provided for @pending.
  ///
  /// In ja, this message translates to:
  /// **'未完了'**
  String get pending;

  /// No description provided for @quantity.
  ///
  /// In ja, this message translates to:
  /// **'数量'**
  String get quantity;

  /// No description provided for @back.
  ///
  /// In ja, this message translates to:
  /// **'戻る'**
  String get back;

  /// No description provided for @closeAction.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get closeAction;

  /// No description provided for @confirmAction.
  ///
  /// In ja, this message translates to:
  /// **'確定'**
  String get confirmAction;

  /// No description provided for @completeWork.
  ///
  /// In ja, this message translates to:
  /// **'作業完了'**
  String get completeWork;

  /// No description provided for @undoOneScan.
  ///
  /// In ja, this message translates to:
  /// **'1scan戻す'**
  String get undoOneScan;

  /// No description provided for @saveScannedFileConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'スキャンしたファイルを保存しますか？'**
  String get saveScannedFileConfirmation;

  /// No description provided for @saveScannedDataConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'スキャンしたデータを保存してよろしいですか？'**
  String get saveScannedDataConfirmation;

  /// No description provided for @unsavedFileBackConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'スキャンしたデータを保存せずに戻りますか？'**
  String get unsavedFileBackConfirmation;

  /// No description provided for @changeSlip.
  ///
  /// In ja, this message translates to:
  /// **'伝票変更'**
  String get changeSlip;

  /// No description provided for @slipRequired.
  ///
  /// In ja, this message translates to:
  /// **'伝票／発注番号を入力してください。'**
  String get slipRequired;

  /// No description provided for @barcodeRequired.
  ///
  /// In ja, this message translates to:
  /// **'戻すデーターがありません。'**
  String get barcodeRequired;

  /// No description provided for @quantityRequired.
  ///
  /// In ja, this message translates to:
  /// **'数量は1以上を入力してください。'**
  String get quantityRequired;

  /// No description provided for @invalidSlip.
  ///
  /// In ja, this message translates to:
  /// **'伝票／発注番号が正しくありません。'**
  String get invalidSlip;

  /// No description provided for @invalidBarcode.
  ///
  /// In ja, this message translates to:
  /// **'この伝票に含まれないバーコード／QRです。'**
  String get invalidBarcode;

  /// No description provided for @slipLoaded.
  ///
  /// In ja, this message translates to:
  /// **'入荷検品リストを読み込みました。'**
  String get slipLoaded;

  /// No description provided for @inspectionSaved.
  ///
  /// In ja, this message translates to:
  /// **'入荷検品結果を保存しました。'**
  String get inspectionSaved;

  /// No description provided for @scannedProductChanged.
  ///
  /// In ja, this message translates to:
  /// **'スキャンした商品が変更されました。'**
  String get scannedProductChanged;

  /// No description provided for @workCompleted.
  ///
  /// In ja, this message translates to:
  /// **'作業を保存しました。'**
  String get workCompleted;

  /// No description provided for @noScanDataToUndo.
  ///
  /// In ja, this message translates to:
  /// **'戻すデーターがありません。'**
  String get noScanDataToUndo;

  /// No description provided for @resetInspectionItemConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'数量を0にします。よろしいですか？'**
  String get resetInspectionItemConfirmation;

  /// No description provided for @deleteInspectionItemConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'選択した行を削除します。よろしいですか？'**
  String get deleteInspectionItemConfirmation;

  /// No description provided for @deleteReceivingWorkConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'この注文とすべての検品一覧データを削除してもよろしいですか？'**
  String get deleteReceivingWorkConfirmation;

  /// No description provided for @deleteSavedFileConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'このファイルを削除してもよろしいですか？'**
  String get deleteSavedFileConfirmation;

  /// No description provided for @downloadExcelConfirmation.
  ///
  /// In ja, this message translates to:
  /// **'このExcelファイルをダウンロードしますか？'**
  String get downloadExcelConfirmation;

  /// No description provided for @yes.
  ///
  /// In ja, this message translates to:
  /// **'はい'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ja, this message translates to:
  /// **'いいえ'**
  String get no;

  /// No description provided for @workDeleted.
  ///
  /// In ja, this message translates to:
  /// **'保存済み作業を削除しました。'**
  String get workDeleted;

  /// No description provided for @workDownloaded.
  ///
  /// In ja, this message translates to:
  /// **'Excelファイルをダウンロードしました。'**
  String get workDownloaded;

  /// No description provided for @emailAddressNotConfigured.
  ///
  /// In ja, this message translates to:
  /// **'送信先メールアドレスが設定されていません。初期設定メニューからメールアドレスを設定してください。'**
  String get emailAddressNotConfigured;

  /// No description provided for @deviceVerificationNotFound.
  ///
  /// In ja, this message translates to:
  /// **'端末認証情報が見つかりません。再度認証してください。'**
  String get deviceVerificationNotFound;

  /// No description provided for @sendMailFileNotFound.
  ///
  /// In ja, this message translates to:
  /// **'送信するファイルが見つかりません。'**
  String get sendMailFileNotFound;

  /// No description provided for @sendMailFileEmpty.
  ///
  /// In ja, this message translates to:
  /// **'送信するファイルが空です。'**
  String get sendMailFileEmpty;

  /// No description provided for @sendMailSuccess.
  ///
  /// In ja, this message translates to:
  /// **'設定済みのメールアドレスに送信が完了しました。'**
  String get sendMailSuccess;

  /// No description provided for @emailSendErrorTitle.
  ///
  /// In ja, this message translates to:
  /// **'送信エラー'**
  String get emailSendErrorTitle;

  /// No description provided for @workSendFailed.
  ///
  /// In ja, this message translates to:
  /// **'メール送信に失敗しました。もう一度お試しください。'**
  String get workSendFailed;

  /// No description provided for @workDownloadFailed.
  ///
  /// In ja, this message translates to:
  /// **'Excelファイルをダウンロードできませんでした。'**
  String get workDownloadFailed;

  /// No description provided for @helpManual.
  ///
  /// In ja, this message translates to:
  /// **'ヘルプ'**
  String get helpManual;

  /// No description provided for @unableToOpenManual.
  ///
  /// In ja, this message translates to:
  /// **'マニュアルを開くことができません。'**
  String get unableToOpenManual;

  /// No description provided for @trialExpiredMessageJa.
  ///
  /// In ja, this message translates to:
  /// **'無料トライアル期間が終了しました。引き続きアプリをご利用いただくには、お問い合わせください。'**
  String get trialExpiredMessageJa;

  /// No description provided for @closeAppButton.
  ///
  /// In ja, this message translates to:
  /// **'アプリを閉じる'**
  String get closeAppButton;
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
      <String>['ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
