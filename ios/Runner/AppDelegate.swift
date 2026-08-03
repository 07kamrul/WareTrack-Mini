import Flutter
import MessageUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, MFMailComposeViewControllerDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let channel = FlutterMethodChannel(
      name: "smartphone_handy_app/downloads",
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak controller] call, result in
      guard call.method == "shareExcelFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let filePath = arguments["filePath"] as? String,
        let fileName = arguments["fileName"] as? String,
        let emailAddress = arguments["emailAddress"] as? String,
        !emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        result(FlutterError(code: "invalid_args", message: "Excel file path or email address is missing.", details: nil))
        return
      }

      guard MFMailComposeViewController.canSendMail() else {
        result(FlutterError(code: "mail_unavailable", message: "Mail is not configured on this device.", details: nil))
        return
      }

      let normalizedEmailAddress = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)

      do {
        let fileURL = URL(fileURLWithPath: filePath)
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setToRecipients([normalizedEmailAddress])
        mailController.setSubject(arguments["subject"] as? String ?? "")
        mailController.setMessageBody(arguments["body"] as? String ?? "", isHTML: false)
        mailController.addAttachmentData(
          try Data(contentsOf: fileURL),
          mimeType: arguments["mimeType"] as? String
            ?? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          fileName: fileName
        )
        controller?.present(mailController, animated: true)
      } catch {
        result(FlutterError(code: "share_failed", message: error.localizedDescription, details: nil))
        return
      }
      result(nil)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func mailComposeController(
    _ controller: MFMailComposeViewController,
    didFinishWith result: MFMailComposeResult,
    error: Error?
  ) {
    controller.dismiss(animated: true)
  }
}
