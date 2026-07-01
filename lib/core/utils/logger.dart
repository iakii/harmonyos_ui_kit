import 'dart:async';
import 'dart:io';

import 'package:day/day.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rohos_app/core/extensions/file_ext.dart'
    show ExtensionFileSystemEntity;
import 'package:rohos_app/core/utils/date.dart' show formatDateTime;

part 'logger.g.dart';

/// Logger 实例的 Riverpod Provider。
///
/// 可通过此 Provider 注入 Logger，便于测试时替换为 mock 实现：
/// ```dart
/// ref.read(loggerProvider).d('message');
/// ```
@riverpod
Logger logger(Ref ref) {
  return Logger(
    level: Logger.level,
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      printEmojis: false,
      colors: true,
      methodCount: 1,
      noBoxingByDefault: false,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    output: MultiOutput([ConsoleOutput(), _BufferedLogStorage()]),
  );
}

/// 便捷全局访问（无需 Riverpod ref 时的 fallback）。
///
/// 在 Provider 场景中优先使用 `ref.read(loggerProvider)`。
final Logger iLogger = _earlyLogger;

/// 在 Riverpod 初始化前的早期阶段使用的 Logger 实例。
final Logger _earlyLogger = Logger(
  level: Logger.level,
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    printEmojis: false,
    colors: true,
    methodCount: 1,
    noBoxingByDefault: false,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
  output: MultiOutput([ConsoleOutput(), _BufferedLogStorage()]),
);

/// 带缓冲区的日志文件写入器。
///
/// 日志行先写入 [StringBuffer]，每 500ms 或 [flush] 时批量写入文件。
/// 避免每条日志都触发一次磁盘 I/O。
class _BufferedLogStorage extends LogOutput {
  static const _expiredHours = 24;
  static const _flushInterval = Duration(milliseconds: 500);

  final StringBuffer _buffer = StringBuffer();
  Timer? _flushTimer;
  File? _file;
  String? _logDir;
  String? _logName;

  @override
  Future<void> init() async {
    deleteExpiredLogs();
  }

  @override
  Future<void> destroy() async {
    await _flushNow();
    deleteExpiredLogs();
  }

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      _buffer.writeln(line.toString());
    }
    _flushTimer ??= Timer(_flushInterval, _flush);
  }

  /// 定时 flush：写入文件并重置计时器。
  Future<void> _flush() async {
    _flushTimer = null;
    await _flushNow();
  }

  /// 立即将缓冲区内容写入文件。
  Future<void> _flushNow() async {
    if (_buffer.isEmpty) return;

    final content = _buffer.toString();
    _buffer.clear();

    _file ??= await _createFile();
    await _file!.writeAsString(content, mode: FileMode.writeOnlyAppend);
  }

  Future<File> _createFile() async {
    _logDir ??= await logPath();
    _logName ??= "${formatDateTime(DateTime.now(), format: 'YYYY-MM-DD')}.log";
    final path = '$_logDir${Platform.pathSeparator}$_logName';

    if (kDebugMode) {
      debugPrint('日志存储路径：$path');
    }

    final file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }

  void deleteExpiredLogs() {
    final dirPath = _logDir;
    if (dirPath == null) return;

    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    for (final element in dir.listSync()) {
      if (!element.path.endsWith('.log')) continue;
      final fileCreateDay = Day.fromString(
        element.fileName.replaceAll('.log', ''),
      );
      final hours = Day().diff(fileCreateDay, 'hour');
      if (hours > _expiredHours) {
        element.deleteSync();
      }
    }
  }
}

Future<String> logPath() async {
  Directory documentsDirectory;
  try {
    documentsDirectory = await getApplicationSupportDirectory();
  } catch (e) {
    documentsDirectory = Directory.systemTemp;
  }

  final path =
      '${documentsDirectory.path}${Platform.pathSeparator}Logs${Platform.pathSeparator}${kDebugMode ? 'Debug' : 'Release'}';
  final dir = Directory(path);
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return path;
}
