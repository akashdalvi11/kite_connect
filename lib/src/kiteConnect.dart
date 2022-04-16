import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'authHelper.dart';
import 'instrumentsHelper.dart';
import 'wsHelper.dart' as wsHelper;
import 'consts.dart';
import 'event.dart';
import 'historicalData.dart';
class KiteConnect {
  final String _userID;
  final Set<Cookie> _cookies;
  final String _encToken;
  final Map<String, int> _instruments;
  final WebSocket _ws;
  final Map<int,StreamController<Event>> streams = {};
  KiteConnect._(
      this._userID, this._cookies, this._encToken, this._instruments, this._ws){
    _ws
      .where(wsHelper.isRelevent)
      .listen(
        (event) {
          var m = wsHelper.parse(event);
          var dateTime = DateTime.now();
          for (var token in m.keys) {
              streams[token]!.add(Event(dateTime,m[token]!));
          }
        }
      );
  }
  static Future<Either<String, KiteConnect>> create(
      String userID, String password, String twoFA,String instrumentsPath) async {
    try {
      String? encToken;
      var cookies = await authenticate(userID, password, twoFA);
      for (var x in cookies) if (x.name == 'enctoken') encToken = x.value;
      var instruments = await getInstruments(encToken!,instrumentsPath);
      var ws = await wsHelper.getWS(userID, encToken);
      return right(KiteConnect._(userID, cookies, encToken, instruments, ws));
    } on String catch (e) {
      return left(e);
    }
  }

  static String _getDate(DateTime dateTime) {
    return dateTime.toString().substring(0, 10);
  }

  Future<Either<String, HistoricalData>> getHistoricalData(
      String instrument, int interval, DateTime from, DateTime to) async {
    int token = _instruments[instrument]!;
    var uri = Uri(
        host: host,
        scheme: 'https',
        path: 'oms/instruments/historical/$token/${intervalMap[interval]}',
        queryParameters: {
          'from': _getDate(from),
          'to': _getDate(to),
          'user_id': _userID,
        });
    var httpClient = HttpClient();
    var request = await httpClient.getUrl(uri);
    request.cookies.addAll(_cookies);
    request.headers.add('authorization', 'enctoken ${_encToken}');
    var response = await request.close();
    httpClient.close();
    var responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      return right(HistoricalData.parsed(jsonDecode(responseBody)['data']['candles']!));
    }
    return left(responseBody);
  }
  Stream<Event> getStream(String instrument){
    int token = _instruments[instrument]!;
    if(!streams.containsKey(token)){
        _wsSubscribe(token);
        streams[token] = StreamController<Event>(onCancel:(){
            _wsUnSubscribe(token);
        });
    }
    return streams[token]!.stream;
  }
  _wsSubscribe(int token) {
    print('$token subscribed');
    _ws.add(jsonEncode({
      "a": "mode",
      "v": [
        "ltp",
        [token]
      ]
    }));
  }

  _wsUnSubscribe(int token) {
    print('$token unSubscribed');
    _ws.add(jsonEncode({
      "a": "unsubscribe",
      "v": [token]
    }));
  }

  close() {
    _ws.close();
  }
}
