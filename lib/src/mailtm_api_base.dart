import 'dart:convert';
import 'package:http/http.dart' as http;

int _lastUse = DateTime.now().millisecondsSinceEpoch;
int _useCount = 0;
int _errorCount = 0;
bool _printError = false;
bool _slowRequests = true;

class _MyHttpClient {
  final http.Client _client = http.Client();

  /// Makes an HTTP request with the given URL, method, body, and token.
  /// Handles rate limiting and retries on certain errors.
  Future<Map<String, dynamic>> request(String url, String method,
      {Map<String, dynamic>? body, String? token}) async {
    ///The Mail TM API is limited to 8 requests per second. Exceed this
    ///limit and status code 429 returns, causing an error. To avoid this,
    ///I limit the package to 3 requests per second.
    ///But it keeps giving errors every now and then.
    ///So, make sure you handle any errors yourself.
    if (_slowRequests) {
      int diff = DateTime.now().millisecondsSinceEpoch - _lastUse;
      if (diff > 1000) {
        _lastUse = DateTime.now().millisecondsSinceEpoch;
        _useCount = 0;
      } else {
        if (_useCount < 3) {
          _useCount++;
        } else {
          await _waitFunction(duration: Duration(seconds: 1));
        }
      }
    } else {
      _useCount = 5;
    }

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

    try {
      _checkStatusError(response);
      return json.decode(response.body);
    } on Exception catch (e) {
      _errorCount++;
      if (_errorCount >= 2) {
        rethrow;
      }
      String forCheck = e.toString();
      if (forCheck.contains('429') ||
          forCheck.contains('500') ||
          forCheck.contains('418')) {
        _printErr(e);
        _printErr(
            "There has been an error. The request will be resent automatically in five seconds. \n");
        await _waitFunction(duration: Duration(seconds: 5));
        return request(url, method, token: token, body: body);
      } else {
        rethrow;
      }
    }
  }

  /// Closes the HTTP client and resets the error count.
  void close() {
    _errorCount = 0;
    _client.close();
  }
}

/// Checks the HTTP response status and throws an exception if there is an error.
void _checkStatusError(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
        'HTTP Error: ${response.statusCode}, \n${response.reasonPhrase.toString()}');
  }
}

/// Prints error messages if _printError is true.
_printErr(Object? object) {
  if (_printError) {
    print("\x1B[31m$object\x1B[0m");
  }
}

class TempMail {
  TempMail({bool printError = false, bool slowRequests = true}) {
    _printError = printError;
    _slowRequests = slowRequests;
  }

  ///api base url
  static const String baseUrl = "https://api.mail.tm";

  ///If params are null it creates a random [Mail]. Most of the time random is better.
  static Future<Mail> createMail(
      {String? addressName, String? addressPassword}) async {
    if (addressName != null && addressName.length > 255) {
      throw Exception('adress name is to large');
    }
    final client = _MyHttpClient();

    try {
      final domainsMap = await client.request('$baseUrl/domains', 'get');

      final String address =
          "${addressName ?? DateTime.now().microsecondsSinceEpoch.toRadixString(32)}@${domainsMap["hydra:member"][0]["domain"]}";
      final String password = addressPassword ??
          '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}fb';

      final accountMap = await client.request('$baseUrl/accounts', 'post',
          body: {"address": address, "password": password});

      final tokenMap = await client.request("$baseUrl/token", 'post',
          body: {"address": address, "password": password});

      return Mail(
          address: address,
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
    } on Exception catch (e) {
      if (_errorCount >= 3) {
        rethrow;
      }
      client.close();
      _errorCount = 5;
      _printErr(e);
      _printErr(
          'Experiencing repeated errors. Calling the function again to restart the process. This is the last recovery attempt.\n');
      await _waitFunction(duration: Duration(seconds: 5));
      return createMail();
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
Future<bool> _waitFunction({required Duration duration}) async {
  await Future.delayed(duration);
  return true;
}

class Mail {
  final String address;
  final String password;
  final String id;
  final String token;
  List? inBox;
  Info info;
  Mail({
    required this.address,
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
  for (var i = 0; i < 5; i++) {
    final mail = await TempMail.createMail(
        addressName: 'mahmuttuncer3$i', addressPassword: 'deneme123');
    print('address: ${mail.address}');
    print('password: ${mail.password}');
    print("quota: ${mail.info.quota}");
    print("used: ${mail.info.used}");
    print("is disabled: ${mail.info.isDisabled}");
    print("is deleted: ${mail.info.isDeleted}");
    print("created at: ${mail.info.createdAt}");
    print("update at: ${mail.info.updateAt}");
    await _waitFunction(duration: Duration(seconds: 25));
  }
}
