import 'dart:convert';
import 'package:http/http.dart' as http;

class TempMail {
  ///api base url
  static const String baseUrl = "https://api.mail.tm";

  ///If params ara null its create random [Mail]. Most of my case random is batter.
  static Future<Mail> createMail(
      {String? adressName, String? adressPassword}) async {
    ///gets basic domain informations
    final http.Response domains = await http.get(Uri.parse('$baseUrl/domains'));
    final Map domainsMap = await json.decode(domains.body);
    final String adress =
        "${adressName ?? DateTime.now().microsecondsSinceEpoch.toRadixString(32)}@${domainsMap["hydra:member"][0]["domain"]}";
    final String password =
        '${adressPassword ?? DateTime.now().microsecondsSinceEpoch.toRadixString(16)}fb';
    final http.Response accaunt = await http.post(
        Uri.parse('$baseUrl/accounts'),
        body: json.encode({"address": adress, "password": password}),
        headers: {"content-type": "application/json"});
    final Map accauntMap = jsonDecode(accaunt.body);
    final http.Response token = await http.post(Uri.parse("$baseUrl/token"),
        body: json.encode({"address": adress, "password": password}),
        headers: {"content-type": "application/json"});
    final tokenMap = json.decode(token.body);
    return Mail(
        adress: adress,
        password: password,
        id: accauntMap["id"],
        token: tokenMap["token"]);
  }

  /// [checkInBox] chaks provided mail inbox and return in mail class.
  /// so if you have something in yor inbox you can see it in [mail.inBox]
  /// if yout inbox is emty [mail.inBox] is return null
  static Future<Mail> checkInBox({required Mail mail}) async {
    final http.Response response = await http
        .get(Uri.parse("$baseUrl/messages"), headers: {
      "Authorization": "Bearer ${mail.token}",
      "Content-Type": "application/json"
    });
    Map responseBodyMap = await json.decode(response.body);
    if (responseBodyMap["hydra:totalItems"] == 0) {
      mail.inBox = null;
      return mail;
    }

    final List? inBox = responseBodyMap['hydra:member'];

    mail.inBox = inBox;
    return mail;
  }
}

class Mail {
  final String adress;
  final String password;
  final String id;
  final String token;
  List? inBox;
  Mail(
      {required this.adress,
      required this.password,
      required this.id,
      required this.token,
      this.inBox});
}
