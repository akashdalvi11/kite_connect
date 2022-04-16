import 'dart:io';
import 'dart:convert';
import 'consts.dart';

Future<Map<String, int>> getInstruments(String encToken,String path) async {
  File file = File('$path/instruments.csv');
  if (!await file.exists() ||
      DateTime.now().difference(await file.lastModified()) >
          Duration(hours: 24)) {
    var h = HttpClient();
    var request =
        await h.getUrl(Uri.parse('https://$instrumentHost/instruments'));
    request.headers.add('authorization', 'token $encToken');
    var response = await request.close();
    if (response.statusCode == 200) {
      var bytes = await response.fold<List<int>>(<int>[], (combine, element) {
        combine.addAll(element);
        return combine;
      });
      await file.writeAsBytes(bytes);
    } else {
      throw await response.transform(utf8.decoder).join();
    }
  }
  return await file
      .openRead()
      .transform(utf8.decoder)
      .transform(LineSplitter())
      .skip(1)
      .fold(<String, int>{}, (combine, element) {
    var splitted = element.split(",");
    combine[splitted[2]] = int.parse(splitted[0]);
    return combine;
  });
}
