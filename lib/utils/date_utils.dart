import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
final DateFormat _shortDateFormat = DateFormat('MM/dd/yyyy');

String formatTaskDate(DateTime date) => _dateFormat.format(date);
String formatTaskDateTime(DateTime date) => _dateTimeFormat.format(date);
String formatShortDate(DateTime date) => _shortDateFormat.format(date);
