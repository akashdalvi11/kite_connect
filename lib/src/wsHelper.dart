import 'dart:convert';
import 'dart:io';
import 'consts.dart';
import 'dart:typed_data';

Future<WebSocket> getWS(String userID,String encToken) async{
  var uri = Uri(
      host: wsHost,
      scheme: 'wss',
      queryParameters: {'user_id': userID, 'enctoken': encToken});
  return await WebSocket.connect(uri.toString());
}

Map<int, double> parse(Uint8List buffer) {
  var packets = _splitPackets(buffer);
  Map<int, double> output = {};
  for (var packet in packets) {
    var t = _bufferToInt(packet.sublist(0, 4));
    assert(packet.lengthInBytes == 8);
    output[t] = _bufferToInt(packet.sublist(4, 8)) / 100;
  }
  return output;
}

bool isRelevent(l) {
  if (l is Uint8List) return l.length != 1;
  print(l);
  return false;
}

int _bufferToInt(Uint8List buffer) {
  var output = 0;
  var l = buffer.length;
  for (var i = 0, r = l - 1; r >= 0; i++, r--) output += (buffer[r] << 8 * i).toInt();
  return output;
}

List<Uint8List> _splitPackets(Uint8List buffer) {
  var numberOfPackets = _bufferToInt(buffer.sublist(0, 2));
  var currentIndex = 2;
  List<Uint8List> packetList = [];
  for (var i = 0; i < numberOfPackets; i++) {
    var packetLength =
        _bufferToInt(buffer.sublist(currentIndex, currentIndex + 2));
    currentIndex += 2;
    var packet = buffer.sublist(currentIndex, currentIndex + packetLength);
    currentIndex += packetLength;
    packetList.add(packet);
  }
  return packetList;
}
