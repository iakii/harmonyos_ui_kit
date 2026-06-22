import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/services/perfs.dart';

/// JS 源文件选择 Provider —— 封装 SharedPreferences 中 KEY_JS 的读写。
///
/// 使用方式：
/// ```dart
/// // 读取
/// final selected = ref.watch(jsSourceProvider);
/// // 写入
/// ref.read(jsSourceProvider.notifier).set('assets/js/meitule.cjs');
/// ```
final jsSourceProvider = NotifierProvider<JsSourceNotifier, String?>(
  JsSourceNotifier.new,
);

class JsSourceNotifier extends Notifier<String?> {
  @override
  String? build() => perfs.getString(perfs.KEY_JS);

  /// 更新选中的 JS 源文件，同时持久化到 SharedPreferences。
  void set(String value) {
    state = value;
    perfs.putString(perfs.KEY_JS, value);
  }

  void clear() {
    state = '';
    perfs.putString(perfs.KEY_JS, '');
  }
}
