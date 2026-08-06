import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailService {
  Future<bool> sendExcelReport({
    required String recipientEmail,
    required File excelFile,
    String? subject,
    String? body,
  }) async {
    final host = dotenv.env['SMTP_HOST'] ?? '';
    final portStr = dotenv.env['SMTP_PORT'] ?? '587';
    final port = int.tryParse(portStr) ?? 587;
    final username = dotenv.env['SMTP_USERNAME'] ?? '';
    final password = dotenv.env['SMTP_PASSWORD'] ?? '';
    final senderEmail = dotenv.env['SMTP_SENDER_EMAIL'] ?? '';
    final senderName = dotenv.env['SMTP_SENDER_NAME'] ?? '';
    final useTls = (dotenv.env['SMTP_USE_TLS'] ?? 'true').toLowerCase() == 'true';

    final smtpServer = SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      ssl: useTls,
      ignoreBadCertificate: false,
    );

    final message = Message()
      ..from = Address(senderEmail, senderName)
      ..recipients.add(recipientEmail)
      ..subject = subject ?? 'WareTrack Mini Export'
      ..text = body ?? 'Attached is your Excel report.'
      ..attachments.add(FileAttachment(excelFile));

    try {
      final sendReport = await send(message, smtpServer);
      return sendReport.isNotEmpty;
    } on MailerException catch (e) {
      throw Exception('Failed to send email: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }
}
