import 'dart:io';
import 'dart:convert';
import 'consts.dart';

Future<HttpClientResponse> _makeRequest(Set<Cookie> cookies,
    HttpClient httpClient, String address, String body) async {
  var uri = Uri.parse(address);
  var request = await httpClient.postUrl(uri);
  request.cookies.addAll(cookies);
  request.headers.add('content-type', 'application/x-www-form-urlencoded');
  request.add(utf8.encode(body));
  var response = await request.close();
  cookies.addAll(response.cookies);
  return response;
}

Future<Set<Cookie>> authenticate(
    String userID, String password, String twoFA) async {
  Set<Cookie> cookies = {};
  var httpClient = HttpClient();
  var loginResponse = await _makeRequest(cookies, httpClient,
      'https://$host/api/login', 'user_id=${userID}&password=${password}');
  var loginResponseBody = await loginResponse.transform(utf8.decoder).join();
  if (loginResponse.statusCode == 200) {
    var parsed = jsonDecode(loginResponseBody);
    String requestID = parsed['data']['request_id']!;
    var twoFABody =
        'user_id=${userID}&request_id=${requestID}&twofa_value=${twoFA}';
    var twoFAResponse = await _makeRequest(
        cookies, httpClient, 'https://$host/api/twofa', twoFABody);
    if (twoFAResponse.statusCode == 200) {
      await twoFAResponse.drain();
      return cookies;
    } else {
      throw await twoFAResponse.transform(utf8.decoder).join();
    }
  } else {
    throw loginResponseBody;
  }
}
