import 'package:mailtm_api/mailtm_api.dart';
import 'package:test/test.dart';

void main() async {
  final Mail mail = await TempMail.createMail();

  test('create temp mail', () async {
    print(
        "mail adress: ${mail.adress}\nmail id: ${mail.id}\nmail password: ${mail.password}\nmail token: ${mail.token}");
    expect(mail.adress, isNotNull);
    expect(mail.adress.contains('@'), true);
    expect(mail.password.endsWith('fb'), true);
    expect(mail.id.length, 24);
    expect(mail.token, isNotNull);
  });

  test('inbox chack', () async {
    expect((await TempMail.checkInBox(mail: mail)).inBox, equals(null));
  });
}
