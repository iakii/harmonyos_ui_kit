import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/core/storage/perfs.dart' show perfs;

/// RustLib 初始化 Provider —— 确保 Rust FFI 桥接在应用启动时初始化。
///
/// 其他需要 Rust 功能的 provider 可以 watch 此 provider 等待就绪：
/// ```dart
/// final rustReady = ref.watch(rustLibInitProvider);
/// if (rustReady.hasValue) { /* 调用 Rust 函数 */ }
/// ```
final rustLibInitProvider = FutureProvider<void>((ref) async {
  WidgetsFlutterBinding.ensureInitialized();
  await perfs.init();
  await JsRuntimeLib.init();
});
