import 'package:pinyin/pinyin.dart' show PinyinHelper;

extension ExtensionString on String {
  String get pinyin {
    return PinyinHelper.getPinyin(this, separator: "");
  }
}
