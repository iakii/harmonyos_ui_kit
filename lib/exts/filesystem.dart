import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

extension ExtensionFile on File {
  String get fileName => p.basename(path);
  String get ext => p.extension(path);
  String get base64 => base64Encode(readAsBytesSync());
}

extension ExtensionFileSystemEntity on FileSystemEntity {
  String get fileName => p.basename(path);
  String get ext => p.extension(path);
  String get filename => p.extension(path).replaceAll(ext, "");
}
