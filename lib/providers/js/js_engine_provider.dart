import 'package:flutter/services.dart' show rootBundle;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/providers/js/settings_provider.dart'
    show jsSourceProvider;

/// 公用的共享 JsEngine Provider，加载 meitule.js 并创建 JS 运行时。
///
/// 整个应用只有一个 JsEngine 实例，通过 [ref.onDispose] 在不再使用时释放。
/// 其他 provider 通过 [ref.watch(jsEngineProvider.future)] 依赖它。
final jsEngineProvider = FutureProvider<JsEngine>((ref) async {
  final assets = ref.watch(jsSourceProvider);

  final jsFiles = await rootBundle.loadString(assets ?? "");

  final engine = JsEngine.create(
    runtimeOptions: JsRuntimeOptions(
      builtins: JsBuiltinOptions.web(), // Console + Fetch
      info: 'kaizty',
    ),
    modules: [JsModule(name: 'client', source: jsFiles)],
  );

  ref.onDispose(() => engine.close());
  return engine;
});
