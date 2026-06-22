import 'dart:collection';
import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:rohos_app/services/logger.dart' show iLogger;

final _rgbRegExp = RegExp(
  r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$',
);
final _rgbaRegExp = RegExp(
  r'^rgba\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(0|1|0?\.\d+)\s*\)$',
);
final _hexColor7RegExp = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$');
final _hexColor6RegExp = RegExp(r'^[A-Fa-f0-9]{6}$');
final _asciiRegExp = RegExp(r'^[\x00-\x7F]+$', multiLine: true, dotAll: true);
final _numericRegExp = RegExp(r'^[0-9]*$');
final _signedNumericRegExp = RegExp(r'^[+-]?[0-9]*$');

extension ExtensionString on String {
  void get log {
    iLogger.d(this);
  }

  double get toDouble => double.tryParse(this) ?? 1;
  int get toInt => int.tryParse(this) ?? 1;

  String get fileName => p.basename(this);
  bool get isZipFileName => endsWith(".zip");
  bool get isRarFileName => endsWith(".rar") || endsWith(".7z");
  bool get isVectorFileName => toLowerCase().endsWith(".svg");

  bool get isImageFileName =>
      ext.endsWith(".jpg") ||
      ext.endsWith(".jpeg") ||
      ext.endsWith(".png") ||
      ext.endsWith(".gif") ||
      ext.endsWith(".bmp");

  bool get isAudioFileName =>
      ext.endsWith(".mp3") ||
      ext.endsWith(".wav") ||
      ext.endsWith(".wma") ||
      ext.endsWith(".amr") ||
      ext.endsWith(".ogg");

  bool get isVideoFileName =>
      ext.endsWith(".mp4") ||
      ext.endsWith(".avi") ||
      ext.endsWith(".wmv") ||
      ext.endsWith(".rmvb") ||
      ext.endsWith(".mpg") ||
      ext.endsWith(".mpeg") ||
      ext.endsWith(".3gp");

  bool get isTxtFileName => toLowerCase().endsWith(".txt");

  bool get isDocumentFileName => ext.endsWith(".doc") || ext.endsWith(".docx");

  bool get isExcelFileName => ext.endsWith(".xls") || ext.endsWith(".xlsx");

  bool get isPPTFileName => ext.endsWith(".ppt") || ext.endsWith(".pptx");

  bool get isAPKFileName => toLowerCase().endsWith(".apk");

  bool get isPDFFileName => toLowerCase().endsWith(".pdf");

  bool get isHTMLFileName => toLowerCase().endsWith(".html");

  bool get isDir {
    return Directory(this).existsSync();
  }

  bool get isFile {
    return File(this).existsSync();
  }

  bool get isValidRGBColor {
    if (_rgbRegExp.hasMatch(this)) {
      final match = _rgbRegExp.firstMatch(this);
      if (match != null) {
        return int.parse(match.group(1)!) <= 255 &&
            int.parse(match.group(2)!) <= 255 &&
            int.parse(match.group(3)!) <= 255;
      }
    }

    if (_rgbaRegExp.hasMatch(this)) {
      final match = _rgbaRegExp.firstMatch(this);
      if (match != null) {
        return int.parse(match.group(1)!) <= 255 &&
            int.parse(match.group(2)!) <= 255 &&
            int.parse(match.group(3)!) <= 255 &&
            double.parse(match.group(4)!) >= 0 &&
            double.parse(match.group(4)!) <= 1;
      }
    }

    return false;
  }

  bool get isValidHexColor {
    return isValidHexColor6 || isValidHexColor7;
  }

  Color? get colorFromHex {
    if (!isValidHexColor) return null;

    var hexColor = this;

    // 去除开头的 '#' 符号
    hexColor = hexColor.replaceAll('#', '');

    // 处理6位十六进制颜色值（默认透明度为FF）
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // 添加FF，表示不透明
    }

    // 检查是否是8位十六进制颜色值
    if (hexColor.length == 8) {
      // 将十六进制字符串转换为整数
      return Color(int.parse(hexColor, radix: 16));
    }

    // 如果格式不正确，返回null
    return null;
  }

  Color? get colorFromRGB {
    if (_rgbRegExp.hasMatch(this)) {
      final match = _rgbRegExp.firstMatch(this);
      if (match != null) {
        final int r = int.parse(match.group(1)!);
        final int g = int.parse(match.group(2)!);
        final int b = int.parse(match.group(3)!);
        return Color.fromRGBO(r, g, b, 1.0);
      }
    }

    if (_rgbaRegExp.hasMatch(this)) {
      final match = _rgbaRegExp.firstMatch(this);
      if (match != null) {
        final int r = int.parse(match.group(1)!);
        final int g = int.parse(match.group(2)!);
        final int b = int.parse(match.group(3)!);
        final double a = double.parse(match.group(4)!);
        return Color.fromRGBO(r, g, b, a);
      }
    }

    return null;
  }

  bool get isValidHexColor7 {
    return _hexColor7RegExp.hasMatch(this);
  }

  bool get isValidHexColor6 {
    return _hexColor6RegExp.hasMatch(this);
  }

  String get pureName => p.basenameWithoutExtension(this);

  String get ext => p.extension(this);

  String get parent {
    return File(this).parent.path;
  }

  bool get isASCII => _asciiRegExp.hasMatch(this);

  bool isNumeric() => contains(_numericRegExp);

  bool isSignedNumeric() => contains(_signedNumericRegExp);

  String? find(String regexp, [int group = 0]) {
    var matches = RegExp(regexp).firstMatch(this);
    return matches?.group(group);
  }

  /// Maps folding repeated entries per key
  Map<K, V> foldToMap<K, V>(
    String regexp,
    K Function(RegExpMatch match) key,
    V Function(RegExpMatch match, V? prev) value,
  ) {
    Map<K, V> map = {};
    for (var m in RegExp(regexp).allMatches(this)) {
      map.update(key(m), (v) => value(m, v), ifAbsent: () => value(m, null));
    }
    return map;
  }

  /// Maps the string, assumes a single match per key
  Map<K, V> toMap<K, V>(
    String regexp,
    K Function(RegExpMatch match) key,
    V Function(RegExpMatch match) value,
  ) {
    return {for (var m in RegExp(regexp).allMatches(this)) key(m): value(m)};
  }

  /// Maps the string, assumes a single match per key
  Set<E> toSet<E>(
    String regexp,
    E? Function(RegExpMatch match) value, [
    int Function(E key1, E key2)? compare,
  ]) {
    final Set<E> set = compare != null ? SplayTreeSet(compare) : <E>{};
    for (var m in RegExp(regexp).allMatches(this)) {
      var nv = value(m);
      if (nv != null) {
        set.add(nv);
      } else if (null is E) {
        // ignore: unnecessary_cast
        (set as Set<E?>).add(nv);
      }
    }
    return set;
  }

  Iterable<String> findAll(String regexp, [int group = 0]) {
    return RegExp(regexp).allMatches(this).map((m) => m.group(group)!);
  }

  Iterable<R> findAllAnd<R>(
    String regexp,
    R Function(RegExpMatch match) provider,
  ) {
    return RegExp(regexp).allMatches(this).map((m) => provider(m));
  }

  R? findAnd<R>(String regexp, R Function(RegExpMatch match) provider) {
    final match = RegExp(regexp).firstMatch(this);
    return match != null ? provider(match) : null;
  }
}
