import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:js_runtime/js_runtime.dart';
import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/domain/entities/plugin_info.dart';
import 'package:rohos_app/presentation/providers/js_engine/js_engine_provider.dart';

/// 插件信息 Provider，从 meitule.js 的 client.pluginInfo 读取。
///
/// 依赖 [jsEngineProvider]，返回 [PluginInfo]（含站点名称、菜单列表等）。
final pluginInfoProvider = FutureProvider<PluginInfo>((ref) async {
  final engine = await ref.watch(jsEngineProvider.future);

  final result = await engine.eval(
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
