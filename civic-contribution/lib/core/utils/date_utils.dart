import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class AppDateUtils {
  static String timeAgo(DateTime date) {
    return timeago.format(date);
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
