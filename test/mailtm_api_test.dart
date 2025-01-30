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
    expect(mail.info, isNotNull);
    expect(mail.info.quota, 40000000);
    expect(mail.info.used, 0);
    expect(mail.info.isDisabled, false);
    expect(mail.info.isDeleted, false);
    expect(mail.info.createdAt, isNotNull);
    expect(mail.info.updateAt, null);
  });

  test('inbox chack', () async {
    expect((await TempMail.checkInBox(mail: mail)).inBox, equals(null));
  });
}
