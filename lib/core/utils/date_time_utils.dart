import 'package:intl/intl.dart';

/// Utility class for timezone-aware date/time formatting.
/// All external API data arrives as UTC; this class handles JST conversion
/// and display formatting.
class DateTimeUtils {
  DateTimeUtils._();

  static const _jstOffset = Duration(hours: 9);

  /// Convert UTC [DateTime] to JST [DateTime]
  static DateTime toJst(DateTime utc) {
    return utc.toUtc().add(_jstOffset);
  }

  /// Format a UTC [DateTime] as a JST display string
  /// e.g. "2025年7月15日(火) 19:00"
  static String formatJst(DateTime utc, {String locale = 'ja'}) {
    final jst = toJst(utc);
    if (locale == 'ja') {
      final formatter = DateFormat('yyyy年M月d日(E) HH:mm', 'ja');
      return formatter.format(jst);
    }
    return DateFormat('MMM d, yyyy HH:mm').format(jst);
  }

  /// Format as ISO-like string for Firestore storage: "2025-07-15 19:00"
  static String toJstStorageString(DateTime utc) {
    final jst = toJst(utc);
    return DateFormat('yyyy-MM-dd HH:mm').format(jst);
  }

  /// Parse a JST storage string back to UTC [DateTime]
  static DateTime jstStorageStringToUtc(String jstString) {
    final jst = DateFormat('yyyy-MM-dd HH:mm').parse(jstString);
    return jst.subtract(_jstOffset);
  }

  /// Format date only (for grouping games by day)
  static String formatDateOnly(DateTime utc, {String locale = 'ja'}) {
    final jst = toJst(utc);
    if (locale == 'ja') {
      return DateFormat('M月d日(E)', 'ja').format(jst);
    }
    return DateFormat('MMM d').format(jst);
  }

  /// Format time only
  static String formatTimeOnly(DateTime utc) {
    final jst = toJst(utc);
    return DateFormat('HH:mm').format(jst);
  }

  /// Returns true if the game is today (JST)
  static bool isToday(DateTime utc) {
    final jst = toJst(utc);
    final now = toJst(DateTime.now().toUtc());
    return jst.year == now.year && jst.month == now.month && jst.day == now.day;
  }

  /// Returns true if the game is upcoming (in the future)
  static bool isUpcoming(DateTime utc) {
    return utc.isAfter(DateTime.now().toUtc());
  }
}
