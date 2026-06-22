import 'package:day/day.dart';
import 'package:day/i18n/zh_cn.dart' as zh_cn_locale;

String format(String? dateStr, {String format = "YYYY-MM-DD HH:mm"}) {
  if (dateStr == null) return "-";
  return Day.fromString(
    dateStr,
  ).toLocal().useLocale(zh_cn_locale.locale).format(format);
}

String formatDateTime(
  DateTime createTime, {
  String format = "YYYY-MM-DD HH:mm:ss:SSS",
}) {
  return Day.fromDateTime(
    createTime,
  ).toLocal().useLocale(zh_cn_locale.locale).format(format);
}

Future<void> waitTime([int milliseconds = 500]) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
}

String get today {
  return Day().toLocal().useLocale(zh_cn_locale.locale).format("YYYYMMDD");
}

String formatTimeAgo(String time) {
  final now = DateTime.now();
  final difference = now.difference(Day.fromString(time).toDateTime());
  // 几年前
  if (difference.inDays >= 365) {
    final years = (difference.inDays / 365).floor();
    return '$years 年前';
  }
  // 几个月前
  if (difference.inDays >= 30) {
    final months = (difference.inDays / 30).floor();
    return '$months 月前';
  } else if (difference.inDays >= 7) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks 周前';
  } else if (difference.inDays >= 1) {
    return '${difference.inDays} 天前';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} 小时前';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} 分钟前';
  } else {
    return '刚刚';
  }
}
