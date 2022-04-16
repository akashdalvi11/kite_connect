
class HistoricalData {
  final List<DateTime> dateTimeList;
  final List<List<double>> ohlcList;
  HistoricalData._(this.dateTimeList,this.ohlcList);

  static HistoricalData parsed(List<dynamic> list) {
    List<List<double>> ohlcList = [];
    List<DateTime> timeFrameList = [];
    for (int i = 0; i < list.length; i++) {
      var data = list[i];
      timeFrameList.add(_createTimeFrame(data[0]));
      ohlcList.add(_createOHLC(data));
    }
    return HistoricalData._(timeFrameList, ohlcList);
  }

  static DateTime _createTimeFrame(dateTimeString) {
    return DateTime.parse(dateTimeString.substring(0, 19));
  }

  static List<double> _createOHLC(data) {
    double o = _ifInt(data[1]);
    double h = _ifInt(data[2]);
    double l = _ifInt(data[3]);
    double c = _ifInt(data[4]);
    return [o, h, l, c];
  }

  static double _ifInt(intOrDouble) {
    if (intOrDouble is int) return intOrDouble.toDouble();
    return intOrDouble;
  }
  String toString(){
    return dateTimeList.toString();
  }
}
