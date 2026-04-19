import 'package:timeago/timeago.dart';

class TeluguMessages implements LookupMessages {
  @override String prefixAgo() => '';
  @override String prefixFromNow() => '';
  @override String suffixAgo() => 'క్రితం';
  @override String suffixFromNow() => 'నుండి';
  @override String lessThanOneMinute(int seconds) => 'ఇప్పుడే';
  @override String aboutAMinute(int minutes) => 'ఒక నిమిషం';
  @override String minutes(int minutes) => '$minutes నిమిషాల';
  @override String aboutAnHour(int minutes) => 'ఒక గంట';
  @override String hours(int hours) => '$hours గంటల';
  @override String aDay(int hours) => 'ఒక రోజు';
  @override String days(int days) => '$days రోజుల';
  @override String aboutAMonth(int days) => 'ఒక నెల';
  @override String months(int months) => '$months నెలల';
  @override String aboutAYear(int year) => 'ఒక సంవత్సరం';
  @override String years(int years) => '$years సంవత్సరాల';
  @override String wordSeparator() => ' ';
}
