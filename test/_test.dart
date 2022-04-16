import 'dart:io';
import 'package:test/test.dart';
import 'package:kite_connect/kite_connect.dart';

void main() async {
  late KiteConnect k;
  setUp(() async {
    var e = Platform.environment;
    var result = await KiteConnect.create(e['userName']!,e['password']!,e['twoFA']!,'./test');
    result.fold((l) {
      throw l;
    }, (r) {
      k = r;
    });
  });
  test('historicalData test', () async {
      dynamic data = (await k.getHistoricalData(
              "NIFTY BANK",5,DateTime.parse('2022-02-01'),DateTime.parse('2022-02-02')
      )).fold((l)=>l,(r)=>r);
      print(data.dateTimeList);
      print(data.ohlcList);
  });
  test('web socket test', () async {
    var bank = k.getStream('NIFTY BANK').listen((e){
      print('bank');
      print(e);
    });
    var n50 = k.getStream('NIFTY 50').listen((e){
      print('50');
      print(e);
    });
    await Future.delayed(Duration(seconds: 5));
    await n50.cancel();
    await Future.delayed(Duration(seconds: 2));
    await bank.cancel();
  });
  
}
