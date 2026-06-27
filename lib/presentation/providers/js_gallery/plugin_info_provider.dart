import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/plugin_info.dart';
import 'package:rohos_app/presentation/providers/js_gallery/repository_providers.dart';

/// 插件信息 Provider，从 meitule.js 的 client.pluginInfo 读取。
///
/// 依赖 [jsPluginRepositoryProvider]，经由 Repository → JsEngine 获取数据。
final pluginInfoProvider = FutureProvider<PluginInfo>((ref) async {
  final repo = ref.watch(jsPluginRepositoryProvider);
  final result = await repo.getPluginInfo();

  return result.when(success: (info) => info, failure: (error) => throw error);
});
