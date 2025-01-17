import 'package:mailtm_api/mailtm_api.dart';

void main() async {
  //You can create a random email like this
  final Mail mailOne = await TempMail.createMail();

  //Or you can be more specific
  final Mail mailTwo = await TempMail.createMail(
      adressName: "furkanbora", adressPassword: 'mySimplePassword123');

  //And you can do email inbox checks like this
  final Mail mailOneWithInBoxInfo = await TempMail.checkInBox(mail: mailOne);
  //This is Retuning Mail with Inbox Info. So this is Retuning Mail.
  //so mailOne and mailOneWithInBoxInfo is samething
  print(mailOne.inBox); //null
  print(mailOneWithInBoxInfo
      .inBox); //if something arrives in your inbox, this will print it. if its not, it will print null

  //You can also print other information such as
  print(mailTwo.adress);
  print(mailTwo.id);
  print(mailTwo.password);
  print(mailTwo.token);
  //So you can keep it for later or use it in other programmes.
}
