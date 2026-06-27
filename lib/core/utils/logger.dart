import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:day/day.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rohos_app/core/extensions/file_ext.dart'
    show ExtensionFileSystemEntity;
import 'package:rohos_app/core/utils/date.dart' show formatDateTime;

ConsoleOutput consoleOutput = ConsoleOutput();

Logger _logger = Logger(
  level: Logger.level,
  filter: ProductionFilter(),
  printer: PrettyPrinter(
    printEmojis: false,
    colors: true,
    methodCount: 1,
    noBoxingByDefault: false,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
  output: MultiOutput([consoleOutput, _LogStorage()]),
);

Logger get iLogger => _logger;

class _LogStorage extends LogOutput {
  // 默认的日志文件过期时间，以小时为单位
  static const _logExpiredTime = 24;

  /// 日志文件操作对象
  File? _file;

  /// 日志目录
  String? logDir;

  /// 日志名称
  String? logName;

  _LogStorage();

  @override
  Future<void> destroy() async {
    deleteExpiredLogs(_logExpiredTime);
  }

  @override
  Future<void> init() async {
    deleteExpiredLogs(_logExpiredTime);
  }

  Future<void> deleteExpiredLogs(int logExpiredTime) async {
    String documentsDirectory = await logPath();

    var dir = Directory(documentsDirectory);
    if (dir.existsSync()) {
      dir.listSync().forEach((element) {
        if (element.path.endsWith('.log')) {
          final fileCreateDay = Day.fromString(
            element.fileName.replaceAll(".log", ""),
          );
          var hours = Day().diff(fileCreateDay, "hour");
          if (hours > logExpiredTime) {
            iLogger.d('日志文件：${element.fileName}，已经超过$logExpiredTime小时，现在删除.');
            element.deleteSync();
          }
        }
      });
    }
  }

  @override
  void output(OutputEvent event) async {
    _file ??= await createFile();
    for (var line in event.lines) {
      await _file!.writeAsString(
        '${line.toString()}\n',
        mode: FileMode.writeOnlyAppend,
      );
    }
  }

  Future<File> createFile() async {
    logDir ??= await logPath();
    logName ??= "${formatDateTime(DateTime.now(), format: 'YYYY-MM-DD')}.log";
    String path = '$logDir${Platform.pathSeparator}$logName';

    if (kDebugMode) {
      debugPrint('日志存储路径：$path');
    }

    File file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }
}

Future<String> logPath() async {
  Directory documentsDirectory;
  try {
    documentsDirectory = await getApplicationSupportDirectory();
  } catch (e) {
    // print(e);
    documentsDirectory = Directory.systemTemp;
  }
  // return documentsDirectory.path;
  var path =
      "${documentsDirectory.path}${Platform.pathSeparator}Logs${Platform.pathSeparator}${kDebugMode ? 'Debug' : 'Release'}";

  var logDir = Directory(path);

  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }
  return path;
}
