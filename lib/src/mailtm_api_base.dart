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

    //createing mail, useing adress name and password
    final String adress =
        "${adressName ?? DateTime.now().microsecondsSinceEpoch.toRadixString(32)}@${domainsMap["hydra:member"][0]["domain"]}";
    final String password =
        '${adressPassword ?? DateTime.now().microsecondsSinceEpoch.toRadixString(16)}fb';
    final http.Response accaunt = await http.post(
        Uri.parse('$baseUrl/accounts'),
        body: json.encode({"address": adress, "password": password}),
        headers: {"content-type": "application/json"});
    final Map accauntMap = jsonDecode(accaunt.body);

    //gets token for auth
    final http.Response token = await http.post(Uri.parse("$baseUrl/token"),
        body: json.encode({"address": adress, "password": password}),
        headers: {"content-type": "application/json"});
    final tokenMap = json.decode(token.body);

    return Mail(
        adress: adress,
        password: password,
        id: accauntMap["id"],
        token: tokenMap["token"],
        info: Info(
            quota: accauntMap["quota"],
            used: accauntMap["used"],
            isDisabled: accauntMap["isDisabled"],
            isDeleted: accauntMap["isDeleted"],
            createdAt: DateTime.parse(accauntMap["createdAt"]),
            updateAt: accauntMap["updateAt"] == null
                ? null
                : DateTime.parse(accauntMap["updateAt"])));
  }

  ///[updateInfo] updates info.
  updateInfo({required Mail mail}) async {
    //gets basic info like quota
    final http.Response info = await http.get(Uri.parse("$baseUrl/me"),
        headers: {
          "Authorization": "Bearer ${mail.token}",
          "content-type": "application/json"
        });
    Map infoMap = jsonDecode(info.body);
    return mail.info = Info(
        quota: infoMap["quota"],
        used: infoMap["used"],
        isDisabled: infoMap["isDisabled"],
        isDeleted: infoMap["isDeleted"],
        createdAt: DateTime.parse(infoMap["createdAt"]),
        updateAt: infoMap["updateAt"] == null
            ? null
            : DateTime.parse(infoMap["updateAt"]));
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
  Info info;
  Mail({
    required this.adress,
    required this.password,
    required this.id,
    required this.token,
    this.inBox,
    required this.info,
  });
}

class Info {
  final int quota;
  final int used;
  final bool isDisabled;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updateAt;
  Info(
      {required this.quota,
      required this.used,
      required this.isDisabled,
      required this.isDeleted,
      required this.createdAt,
      required this.updateAt});
}

void main() async {
  final mail = await TempMail.createMail();
  print("quota: ${mail.info.quota}");
  print("used: ${mail.info.used}");
  print("id disabled: ${mail.info.isDisabled}");
  print("id deleted: ${mail.info.isDeleted}");
  print("created at: ${mail.info.createdAt}");
  print("update at: ${mail.info.updateAt}");
}
