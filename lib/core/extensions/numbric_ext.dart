import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

extension ExtensionNum on num {
  Widget get W => Gap(double.parse('$this'));
  Widget get H => Gap(double.parse('$this'));

  String get mb {
    if (this < 1024) {
      return "${this}Byte";
    }

    if (this > 1024 && this < 1024 * 1024) {
      return "${(this / 1024).toStringAsFixed(2)}Kb";
    }

    if (this < 1024 * 1024 * 1024 && this > 1024 * 1024) {
      return "${(this / (1024 * 1024)).toStringAsFixed(2)}Mb";
    }

    return "${(this / (1024 * 1024)).toStringAsFixed(2)}Mb";
  }

  /// A method returns a human readable string representing a file _size
  String get filesize {
    int round = 3;

    /**
   * [size] can be passed as number or as string
   *
   * the optional parameter [round] specifies the number
   * of digits after comma/point (default is 2)
   */
    var divider = 1024;
    // ignore: no_leading_underscores_for_local_identifiers
    int _size;
    try {
      _size = int.parse(toString());
    } catch (e) {
      return '0 B';
    }

    if (_size < divider) {
      return '$_size B';
    }

    if (_size < divider * divider && _size % divider == 0) {
      return '${(_size / divider).toStringAsFixed(0)} KB';
    }

    if (_size < divider * divider) {
      return '${(_size / divider).toStringAsFixed(round)} KB';
    }

    if (_size < divider * divider * divider && _size % divider == 0) {
      return '${(_size / (divider * divider)).toStringAsFixed(0)} MB';
    }

    if (_size < divider * divider * divider) {
      return '${(_size / divider / divider).toStringAsFixed(round)} MB';
    }

    if (_size < divider * divider * divider * divider && _size % divider == 0) {
      return '${(_size / (divider * divider * divider)).toStringAsFixed(0)} GB';
    }

    if (_size < divider * divider * divider * divider) {
      return '${(_size / divider / divider / divider).toStringAsFixed(round)} GB';
    }

    if (_size < divider * divider * divider * divider * divider &&
        _size % divider == 0) {
      num r = _size / divider / divider / divider / divider;
      return '${r.toStringAsFixed(0)} TB';
    }

    if (_size < divider * divider * divider * divider * divider) {
      num r = _size / divider / divider / divider / divider;
      return '${r.toStringAsFixed(round)} TB';
    }

    if (_size < divider * divider * divider * divider * divider * divider &&
        _size % divider == 0) {
      num r = _size / divider / divider / divider / divider / divider;
      return '${r.toStringAsFixed(0)} PB';
    } else {
      num r = _size / divider / divider / divider / divider / divider;
      return '${r.toStringAsFixed(round)} PB';
    }
  }

  /// Utility to delay some callback (or code execution).
  /// to stop it.
  ///
  /// Sample:
  /// ```
  /// void main() async {
  ///   print('+ wait for 2 seconds');
  ///   await 2.delay();
  ///   print('- 2 seconds completed');
  ///   print('+ callback in 1.2sec');
  ///   1.delay(() => print('- 1.2sec callback called'));
  ///   print('currently running callback 1.2sec');
  /// }
  ///```
  Future delay([FutureOr Function()? callback]) async =>
      Future.delayed(Duration(milliseconds: (this * 1000).round()), callback);

  /// Easy way to make Durations from numbers.
  ///
  /// Sample:
  /// ```
  /// print(1.seconds + 200.milliseconds);
  /// print(1.hours + 30.minutes);
  /// print(1.5.hours);
  ///```
  // Duration get milliseconds => Duration(microseconds: (this * 1000).round());

  // Duration get seconds => Duration(milliseconds: (this * 1000).round());

  // Duration get minutes => Duration(seconds: (this * Duration.secondsPerMinute).round());

  // Duration get hours => Duration(minutes: (this * Duration.minutesPerHour).round());

  // Duration get days => Duration(hours: (this * Duration.hoursPerDay).round());
}

extension ExtInt on int {
  WindowType get windowType {
    switch (this) {
      case 1:
        return WindowType.settings;
      case 2:
        return WindowType.properties;
      case 3:
        return WindowType.process;
      case 4:
        return WindowType.finished;
      default:
        return WindowType.other;
    }
  }

  Duration get milliseconds => Duration(microseconds: this * 1000);
  Duration get seconds => Duration(milliseconds: this * 1000);
  Duration get minutes => Duration(seconds: this * Duration.secondsPerMinute);
  Duration get hours => Duration(minutes: this * Duration.minutesPerHour);
  Duration get days => Duration(hours: this * Duration.hoursPerDay);
}

enum WindowType { settings, properties, process, finished, other }
