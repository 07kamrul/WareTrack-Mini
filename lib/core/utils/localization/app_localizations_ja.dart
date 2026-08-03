// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'WareTrack Mini';

  @override
  String get brQrScanner => 'BR/QRスキャナー';

  @override
  String get ocrScanner => 'OCRスキャナー';

  @override
  String get scanner => 'スキャナー';

  @override
  String get settings => '設定';

  @override
  String get scan => 'スキャン';

  @override
  String get scanDetails => 'スキャン詳細';

  @override
  String get pleaseScan => '読み取ってください';

  @override
  String get scanBarcodeQr => 'バーコード／QRコード';

  @override
  String get scanOcrText => 'OCR対象の文字';

  @override
  String get scanExternal => '外部スキャナーで';

  @override
  String get productSearch => '商品\n検索';

  @override
  String get shuttleName => 'シャトル名';

  @override
  String get shuttleGate => 'シャトルゲート';

  @override
  String get merchandise => '商品';

  @override
  String get brQr => 'BR/QR';

  @override
  String get ocr => 'OCR';

  @override
  String get unableToOpenCamera => 'カメラを開けません。';

  @override
  String get scanningInProgress => 'スキャン中';

  @override
  String get scanningStopped => 'スキャン停止中';

  @override
  String get readyExternalScanner => '外部スキャナー入力を待機中です。';

  @override
  String get capturingOcr => '現在のカメラプレビューからOCRを取得しています...';

  @override
  String get externalScanReceived => '外部スキャンを受信しました。';

  @override
  String get unableCaptureOcr => 'OCR用に現在のカメラプレビューを取得できません。';

  @override
  String get unableProcessOcr => '現在のカメラプレビューからOCRを処理できません。';

  @override
  String get noReadableText => '読み取れる文字が見つかりませんでした。';

  @override
  String get ocrTextDetected => 'OCR文字を検出しました。';

  @override
  String get codeDetected => 'コードを検出しました。';

  @override
  String get scanFailed => 'スキャンに失敗しました。';

  @override
  String get noCompatibleCamera =>
      '対応するカメラが見つかりません。エミュレーターでは仮想背面カメラを有効にするか、実機でお試しください。';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get scannerSettings => 'スキャナー';

  @override
  String get saveTransfer => '保存・送信';

  @override
  String get appInformation => 'アプリ情報';

  @override
  String get appName => 'アプリ名';

  @override
  String get english => '英語';

  @override
  String get japanese => '日本語';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get scanSound => 'スキャン音';

  @override
  String get autoScan => '自動スキャン';

  @override
  String get duplicateProtection => '重複スキャン防止';

  @override
  String get cameraReset => '検出後にカメラをリセット';

  @override
  String get fastScanMode => '高速スキャンモード';

  @override
  String get saveFormat => '保存形式';

  @override
  String get csv => 'CSV';

  @override
  String get tsv => 'TSV';

  @override
  String get excel => 'Excel';

  @override
  String get transferMethod => '送信先設定';

  @override
  String get emailTransfer => 'メール転送';

  @override
  String get serverUpload => 'サーバーアップロード';

  @override
  String get emailAddress => 'メールアドレス';

  @override
  String get uploadUrl => 'アップロードURL';

  @override
  String get transferDestination => '転送先';

  @override
  String get appVersion => 'アプリバージョン';

  @override
  String get currentLanguage => '現在の言語';

  @override
  String get currentTheme => '現在のテーマ';

  @override
  String get deviceInformation => '端末情報';

  @override
  String get serialNumber => 'シリアル番号';

  @override
  String get optional => '任意';

  @override
  String get emailRequired => 'メールアドレスを入力してください。';

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください。';

  @override
  String get invalidUrl => '有効なアップロードURLを入力してください。';

  @override
  String get settingsSaved => '設定完了しました。';

  @override
  String get save => '保存';

  @override
  String get mainMenu => 'メインメニュー';

  @override
  String get receiving => '入荷検品';

  @override
  String get receivingSlip => '入荷伝票';

  @override
  String get receivingScanner => '入荷スキャナー';

  @override
  String get shelfPlacement => '棚入れ';

  @override
  String get stocktaking => '棚卸';

  @override
  String get movement => '棚移動検品';

  @override
  String get shipping => '出荷検品';

  @override
  String get savedFileList => '保存ファイル一覧';

  @override
  String get initialSettings => '初期設定';

  @override
  String get logout => 'ログアウト';

  @override
  String get systemTitle => 'WareTrack Mini';

  @override
  String get operationsDescription => 'バーコード・QR・OCR・検品業務';

  @override
  String get codeVerificationDescription =>
      'このアプリをダウンロードする前にコピーした承認コードを貼り付けてください。承認コードがわからない場合は、ダウンロードシステムでご確認ください。';

  @override
  String get signIn => 'サインイン';

  @override
  String get signUp => 'サインアップ';

  @override
  String get codeVerification => '承認コード確認';

  @override
  String get code => '承認コード';

  @override
  String get submit => '確認';

  @override
  String get employeeId => '社員ID';

  @override
  String get password => 'パスワード';

  @override
  String get fullName => '氏名';

  @override
  String get confirmPassword => 'パスワード確認';

  @override
  String get createNewAccount => '新規アカウント作成';

  @override
  String get backToSignIn => 'サインインへ戻る';

  @override
  String get currentOperator => 'プロフィール';

  @override
  String get slipOrderNumber => '伝票／発注番号';

  @override
  String get scanSlipOrderPrompt => '伝票/発生番号をスキャンしてください。';

  @override
  String get hide => '非表示';

  @override
  String get slipOnly => '伝票';

  @override
  String get all => '全て';

  @override
  String get noInspectionData => '検品データがありません。';

  @override
  String get edit => '編集';

  @override
  String get view => '表示';

  @override
  String get deleteAction => '削除';

  @override
  String get send => '送信';

  @override
  String get fileName => 'ファイル名';

  @override
  String get date => '日付';

  @override
  String get download => 'ダウンロード';

  @override
  String get open => '開く';

  @override
  String get action => '操作';

  @override
  String get inspectionReset => '修正';

  @override
  String get inspectionResetFirstRow => '選択';

  @override
  String get inspectionResetOtherRow => '選択';

  @override
  String get select => '選択';

  @override
  String get selectEdit => '選択';

  @override
  String get slipNumber => '伝票番号';

  @override
  String get barcodeQr => 'バーコード／QR';

  @override
  String get inspectionQuantity => '検品数';

  @override
  String get inspectionList => '検品一覧';

  @override
  String get excelOrderNo => '伝票番号';

  @override
  String get excelProductCode => '商品コード';

  @override
  String get excelDateTime => '日時';

  @override
  String get excelUserId => 'ユーザーID';

  @override
  String get savedWorkList => '保存ファイル一覧';

  @override
  String get totalItems => '合計明細数';

  @override
  String get totalQuantity => '合計数量';

  @override
  String selectedSlip(Object slipNumber) {
    return '伝票指定: $slipNumber';
  }

  @override
  String get status => '状態';

  @override
  String get completed => '完了';

  @override
  String get pending => '未完了';

  @override
  String get quantity => '数量';

  @override
  String get back => '戻る';

  @override
  String get closeAction => '閉じる';

  @override
  String get confirmAction => '確定';

  @override
  String get completeWork => '作業完了';

  @override
  String get undoOneScan => '1scan戻す';

  @override
  String get saveScannedFileConfirmation => 'スキャンしたファイルを保存しますか？';

  @override
  String get saveScannedDataConfirmation => 'スキャンしたデータを保存してよろしいですか？';

  @override
  String get unsavedFileBackConfirmation => 'スキャンしたデータを保存せずに戻りますか？';

  @override
  String get changeSlip => '伝票変更';

  @override
  String get slipRequired => '伝票／発注番号を入力してください。';

  @override
  String get barcodeRequired => '戻すデーターがありません。';

  @override
  String get quantityRequired => '数量は1以上を入力してください。';

  @override
  String get invalidSlip => '伝票／発注番号が正しくありません。';

  @override
  String get invalidBarcode => 'この伝票に含まれないバーコード／QRです。';

  @override
  String get slipLoaded => '入荷検品リストを読み込みました。';

  @override
  String get inspectionSaved => '入荷検品結果を保存しました。';

  @override
  String get scannedProductChanged => 'スキャンした商品が変更されました。';

  @override
  String get workCompleted => '作業を保存しました。';

  @override
  String get noScanDataToUndo => '戻すデーターがありません。';

  @override
  String get resetInspectionItemConfirmation => '数量を0にします。よろしいですか？';

  @override
  String get deleteInspectionItemConfirmation => '選択した行を削除します。よろしいですか？';

  @override
  String get deleteReceivingWorkConfirmation =>
      'この注文とすべての検品一覧データを削除してもよろしいですか？';

  @override
  String get deleteSavedFileConfirmation => 'このファイルを削除してもよろしいですか？';

  @override
  String get downloadExcelConfirmation => 'このExcelファイルをダウンロードしますか？';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get workDeleted => '保存済み作業を削除しました。';

  @override
  String get workDownloaded => 'Excelファイルをダウンロードしました。';

  @override
  String get emailAddressNotConfigured =>
      '送信先メールアドレスが設定されていません。初期設定メニューからメールアドレスを設定してください。';

  @override
  String get deviceVerificationNotFound => '端末認証情報が見つかりません。再度認証してください。';

  @override
  String get sendMailFileNotFound => '送信するファイルが見つかりません。';

  @override
  String get sendMailFileEmpty => '送信するファイルが空です。';

  @override
  String get sendMailSuccess => '設定済みのメールアドレスに送信が完了しました。';

  @override
  String get emailSendErrorTitle => '送信エラー';

  @override
  String get workSendFailed => 'メール送信に失敗しました。もう一度お試しください。';

  @override
  String get workDownloadFailed => 'Excelファイルをダウンロードできませんでした。';

  @override
  String get helpManual => 'ヘルプ';

  @override
  String get unableToOpenManual => 'マニュアルを開くことができません。';

  @override
  String get trialExpiredMessageJa =>
      '無料トライアル期間が終了しました。引き続きアプリをご利用いただくには、お問い合わせください。';

  @override
  String get closeAppButton => 'アプリを閉じる';
}
