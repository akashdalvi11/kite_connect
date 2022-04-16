class Event{
  final DateTime dateTime;
  final double value;
  Event(this.dateTime,this.value);
  String toString(){
    return '$dateTime : $value';
  }
}