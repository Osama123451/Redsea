import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  print('🚀 Starting email debug test...');

  const username = 'osamammm018@gmail.com';
  const password = 'pnjcjcygnskuziqa'; // App Password

  print('👤 Username: $username');
  print('🔑 Password length: ${password.length}');

  // Test 1: Simple gmail function
  print('\n🧪 Test 1: Using gmail() helper...');
  try {
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Debug Test')
      ..recipients.add(username) // Send to self
      ..subject = 'Test 1'
      ..text = 'This is a test email from debug script (Test 1).';

    final sendReport = await send(message, smtpServer);
    print('✅ Test 1 SUCCESS: ${sendReport.toString()}');
  } catch (e) {
    print('❌ Test 1 FAILED: $e');
  }

  // Test 2: Explicit SMTP with SSL
  print('\n🧪 Test 2: Using SmtpServer with SSL (465)...');
  try {
    final smtpServer = SmtpServer('smtp.gmail.com',
        username: username,
        password: password,
        port: 465,
        ssl: true,
        ignoreBadCertificate: true);

    final message = Message()
      ..from = Address(username, 'Debug Test')
      ..recipients.add(username)
      ..subject = 'Test 2'
      ..text = 'This is a test email from debug script (Test 2).';

    final sendReport = await send(message, smtpServer);
    print('✅ Test 2 SUCCESS: ${sendReport.toString()}');
  } catch (e) {
    print('❌ Test 2 FAILED: $e');
  }

  print('\n🏁 Debug test finished.');
}
