import 'package:mailtm_api/mailtm_api.dart';

void main() async {
  // SECTION 1: Advanced Configuration Example
  print('1. Advanced Configuration Example');
  print('--------------------------------');

  // Configure error printing and request timing
  TempMail(
      printError: true, // Will print API errors to console
      slowRequests: true // Enables built-in rate limiting
      );

  // Method 1: Create a random temporary email
  Mail randomMail = await TempMail.createMail();
  print('Random email address: ${randomMail.address}');
  print('Random email password: ${randomMail.password}');

  // Method 2: Create an email with custom address and password
  final Mail customMail = await TempMail.createMail(
    addressName: "johndoe",
    addressPassword: 'mySecurePass123',
  );
  print('\nCustom email address: ${customMail.address}');
  print('Custom email password: ${customMail.password}');

  // Inbox checking
  final Mail mailWithInbox = await TempMail.checkInBox(mail: customMail);
  if (mailWithInbox.inBox == null) {
    print('No messages in inbox');
  } else {
    print('You have ${mailWithInbox.inBox!.length} messages');

    // Print message details
    for (var message in mailWithInbox.inBox!) {
      print('\nMessage Details:');
      print('From: ${message['from']['address']}');
      print('Subject: ${message['subject']}');
      print('Received At: ${message['createdAt']}');
    }
  }

  // Periodic inbox checking with error handling
  try {
    for (int i = 0; i < 3; i++) {
      if (i > 0) await Future.delayed(Duration(seconds: 2));
      randomMail = await TempMail.checkInBox(mail: randomMail);
      print('Check #${i + 1}: ${randomMail.inBox ?? "No messages"}');
    }
  } catch (e) {
    print('Error occurred: $e');
  }

  // SECTION 2: Simple Basic Usage Example
  print('\n2. Simple Basic Usage Example');
  print('----------------------------');

  // Most basic way to create and use temporary email
  try {
    // Create email
    Mail simpleMail = await TempMail.createMail();
    print('Email address: ${simpleMail.address}');
    print('Password: ${simpleMail.password}');

    // Check inbox
    simpleMail = await TempMail.checkInBox(mail: simpleMail);
    print('Inbox status: ${simpleMail.inBox ?? "Empty"}');
  } catch (e) {
    print('Error: $e');
  }

  // SECTION 3: Different Configuration Examples
  print('\n3. Configuration Options');
  print('----------------------');

  // Example 1: Default settings (recommended for most users)
  TempMail(printError: true, slowRequests: true);
  print('Default settings: Error printing ON, Rate limiting ON');

  // Example 2: Debug mode (development)
  TempMail(printError: true, slowRequests: false);
  print('Debug mode: Error printing ON, Rate limiting OFF');

  // Example 3: Production mode (minimal logging)
  TempMail(printError: false, slowRequests: true);
  print('Production mode: Error printing OFF, Rate limiting ON');

  // Example 4: Performance mode (use with caution)
  TempMail(printError: false, slowRequests: false);
  print('Performance mode: Error printing OFF, Rate limiting OFF');
}
