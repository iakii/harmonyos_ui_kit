import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/data/datasources/local/js_source_local_datasource.dart';

/// JS 源文件选择 Provider —— 通过 [JsSourceLocalDataSource] 访问 SharedPreferences。
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
  final _localSource = JsSourceLocalDataSource();

  @override
  String? build() => _localSource.getSavedSource();

  /// 更新选中的 JS 源文件，同时持久化到 SharedPreferences。
  void set(String value) {
    state = value;
    _localSource.saveSource(value);
  }

  void clear() {
    state = '';
    _localSource.clearSource();
  }
}
