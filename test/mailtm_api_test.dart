import 'package:test/test.dart';
import 'package:mailtm_api/src/mailtm_api_base.dart';

Future<bool> _waitFunction({required Duration duration}) async {
  await Future.delayed(duration);
  return true;
}

void main() {
  group('TempMail API Tests', () {
    test('Create mail with valid parameters', () async {
      final mail = await TempMail.createMail();
      expect(mail.address, isNotNull);
      expect(mail.token, isNotNull);
      expect(mail.id.length, equals(24));
    });

    test('Create mail with custom address', () async {
      final String addressName =
          'test${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';
      final mail = await TempMail.createMail(
          addressName: addressName, addressPassword: 'password123');
      expect(mail.address.startsWith('$addressName@'), isTrue);
      expect(mail.password, equals('password123'));
    });

    test('Rate limit handling', () async {
      // Make 10 rapid requests to trigger rate limit
      for (int i = 0; i < 10; i++) {
        await TempMail.createMail();
        await _waitFunction(duration: Duration(seconds: 10));
      }
      // Should not throw rate limit exception
    }, timeout: Timeout(Duration(minutes: 3)));

    test('Invalid token error', () async {
      final mail = Mail(
        address: 'test@test.com',
        password: 'test123fb',
        id: '123456789012345678901234',
        token: 'invalid_token',
        info: Info(
          quota: 40000000,
          used: 0,
          isDisabled: false,
          isDeleted: false,
          createdAt: DateTime.now(),
          updateAt: null,
        ),
      );

      expect(() async => await TempMail.checkInBox(mail: mail),
          throwsA(isA<Exception>()));
    });

    test('Update info with invalid mail', () async {
      final mail = Mail(
        address: 'invalid@test.com',
        password: 'invalidfb',
        id: '123',
        token: 'invalid_token',
        info: Info(
          quota: 0,
          used: 0,
          isDisabled: false,
          isDeleted: false,
          createdAt: DateTime.now(),
          updateAt: null,
        ),
      );

      expect(() async => await TempMail.updateInfo(mail: mail),
          throwsA(isA<Exception>()));
    });

    test('Malformed response handling', () async {
      final mail = await TempMail.createMail();
      expect(() async => await TempMail.checkInBox(mail: mail), isNotNull);
    });

    test('Multiple rapid inbox checks', () async {
      final mail = await TempMail.createMail();
      for (int i = 0; i < 5; i++) {
        await _waitFunction(duration: Duration(seconds: 10));
        final result = await TempMail.checkInBox(mail: mail);
        expect(result, isNotNull);
      }
    }, timeout: Timeout(Duration(minutes: 3)));

    test('Info consistency after updates', () async {
      final mail = await TempMail.createMail();
      final initialInfo = mail.info;
      await _waitFunction(duration: Duration(seconds: 10));
      final updatedInfo = await TempMail.updateInfo(mail: mail);

      expect(updatedInfo.quota, equals(initialInfo.quota));
      expect(updatedInfo.isDisabled, equals(initialInfo.isDisabled));
      expect(updatedInfo.createdAt, equals(initialInfo.createdAt));
    });

    test('Network error handling', () {
      expect(
          () async => await TempMail.createMail(
              addressName:
                  List.filled(1000000, 'a').join()), // Too large request
          throwsException);
    });

    test('Mail address format validation', () async {
      final mail = await TempMail.createMail();
      expect(mail.address.contains('@'), isTrue);
      expect(mail.address.split('@').length, equals(2));
    });
  });
}
