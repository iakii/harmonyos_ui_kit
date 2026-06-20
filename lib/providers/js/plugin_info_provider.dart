import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';

import '../../models/app_exception.dart';
import '../../models/plugin/plugin_info.dart';
import 'js_engine_provider.dart';

/// 插件信息 Provider，从 meitule.js 的 client.pluginInfo 读取。
///
/// 依赖 [jsEngineProvider]，返回 [PluginInfo]（含站点名称、菜单列表等）。
final pluginInfoProvider = FutureProvider<PluginInfo>((ref) async {
  final engine = await ref.watch(jsEngineProvider.future);

  final result = engine.eval(
    code: '''
    (async () => {
      const { default: client } = await import('client');
      return client.pluginInfo;
    })()
  ''',
  );

  final jsonStr = result.asStringSync;
  if (jsonStr == null) {
    throw ParseException('pluginInfo 返回非字符串');
  }

  return PluginInfo.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
});
