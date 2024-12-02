import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailService {
  // Replace these with your actual email credentials
  final String _username = 'capstonearalink@gmail.com'; // Your email address
  final String _password = 'ucns fsir gwcm knkg'; // Your email password (Use secure storage in production)

  // Singleton instance
  MailService._privateConstructor();
  static final MailService instance = MailService._privateConstructor();

  /// Sends an email with the specified message, subject, and recipient's email address.
  Future<void> sendMail(String message, String subject, String recipientEmail) async {
    // SMTP server setup for Gmail
    final smtpServer = gmail(_username, _password);

    // Create the email message
    final email = Message()
      ..from = Address(_username, 'Aralink Team') // From address with an optional display name
      ..recipients.add(recipientEmail) // Add recipient email
      ..subject = subject // Subject of the email
      ..text = message // Plain text body
      ..html = '<p>${message.replaceAll('\n', '<br>')}</p>'; // HTML body (optional)

    try {
      // Send the email
      final sendReport = await send(email, smtpServer);
      print('Message sent successfully: ${sendReport.toString()}');
    } on MailerException catch (e) {
      // Handle email sending errors
      print('Failed to send email: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
}
