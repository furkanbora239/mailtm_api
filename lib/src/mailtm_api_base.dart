import 'dart:convert';
import 'package:http/http.dart' as http;

class _MyHttpClient {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> request(String url, String method,
      {Map<String, dynamic>? body, String? token}) async {
    final headers = {"content-type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    http.Response response;

    if (method == 'get') {
      response = await _client.get(Uri.parse(url), headers: headers);
    } else if (method == 'post') {
      response = await _client.post(Uri.parse(url),
          body: json.encode(body), headers: headers);
    } else {
      throw Exception('Invalid HTTP method');
    }

    _chackStatusError(response);
    return json.decode(response.body);
  }

  void close() {
    _client.close();
  }
}

void _chackStatusError(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
        'HTTP Error: ${response.statusCode}, Body: ${response.body}');
  }
}

class TempMail {
  ///api base url
  static const String baseUrl = "https://api.mail.tm";

  ///If params are null it creates a random [Mail]. Most of the time random is better.
  static Future<Mail> createMail(
      {String? adressName, String? adressPassword}) async {
    final client = _MyHttpClient();

    try {
      final domainsMap = await client.request('$baseUrl/domains', 'get');

      final String adress =
          "${adressName ?? DateTime.now().microsecondsSinceEpoch.toRadixString(32)}@${domainsMap["hydra:member"][0]["domain"]}";
      final String password =
          '${adressPassword ?? DateTime.now().microsecondsSinceEpoch.toRadixString(16)}fb';

      final accountMap = await client.request('$baseUrl/accounts', 'post',
          body: {"address": adress, "password": password});

      final tokenMap = await client.request("$baseUrl/token", 'post',
          body: {"address": adress, "password": password});

      return Mail(
          adress: adress,
          password: password,
          id: accountMap["id"],
          token: tokenMap["token"],
          info: Info(
              quota: accountMap["quota"],
              used: accountMap["used"],
              isDisabled: accountMap["isDisabled"],
              isDeleted: accountMap["isDeleted"],
              createdAt: DateTime.parse(accountMap["createdAt"]),
              updateAt: accountMap["updateAt"] == null
                  ? null
                  : DateTime.parse(accountMap["updateAt"])));
    } finally {
      client.close();
    }
  }

  ///[updateInfo] updates info.
  static Future<Info> updateInfo({required Mail mail}) async {
    final client = _MyHttpClient();
    try {
      final infoMap =
          await client.request("$baseUrl/me", 'get', token: mail.token);

      return mail.info = Info(
          quota: infoMap["quota"],
          used: infoMap["used"],
          isDisabled: infoMap["isDisabled"],
          isDeleted: infoMap["isDeleted"],
          createdAt: DateTime.parse(infoMap["createdAt"]),
          updateAt: infoMap["updateAt"] == null
              ? null
              : DateTime.parse(infoMap["updateAt"]));
    } finally {
      client.close();
    }
  }

  /// [checkInBox] checks provided mail inbox and return in mail class.
  /// so if you have something in your inbox you can see it in [mail.inBox]
  /// if your inbox is empty [mail.inBox] returns null
  static Future<Mail> checkInBox({required Mail mail}) async {
    final client = _MyHttpClient();
    try {
      final responseBodyMap =
          await client.request("$baseUrl/messages", 'get', token: mail.token);

      if (responseBodyMap["hydra:totalItems"] == 0) {
        mail.inBox = null;
        return mail;
      }

      final List? inBox = responseBodyMap['hydra:member'];
      mail.inBox = inBox;
      return mail;
    } finally {
      client.close();
    }
  }
}

/// [_waitFunction] can be used with await to create an effect similar to sleep in other programming languages.
/// It can be used to wait in asynchronous operations.
/// However, due to its asynchronous nature, it will not work in non-asynchronous contexts.
Future<void> _waitFunction({required Duration duration}) async {
  await Future.delayed(duration);
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
