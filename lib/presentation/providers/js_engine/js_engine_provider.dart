import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/presentation/providers/js_gallery/config_provider.dart'
    show jsConfigProvider;

/// 公用的共享 JsEngine Provider，加载选中的 .cjs 文件并创建 JS 运行时。
///
/// 整个应用只有一个 JsEngine 实例，通过 [ref.onDispose] 在不再使用时释放。
/// 其他 provider 通过 [ref.watch(jsEngineProvider.future)] 依赖它。
final jsEngineProvider = FutureProvider<JsEngine>((ref) async {
  final config = await ref.watch(jsConfigProvider.future);

  final engine = JsEngine.create(
    runtimeOptions: JsRuntimeOptions(
      builtins: JsBuiltinOptions.all(), // Console + Fetch
      info: config.name,
    ),
    modules: [JsModule(name: 'client', source: config.jsContent)],
  );

  ref.onDispose(() => engine.close());
  return engine;
});
