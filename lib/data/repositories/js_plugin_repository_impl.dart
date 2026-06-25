import 'dart:convert';

import 'package:js_runtime/js_runtime.dart';

import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/plugin_info.dart';
import 'package:rohos_app/domain/repositories/js_plugin_repository.dart';

/// JsPluginRepository 实现。
///
/// 通过 JsEngine 执行 JS 代码获取插件元信息。
class JsPluginRepositoryImpl implements JsPluginRepository {
  final Future<JsEngine> Function() _engineProvider;

  const JsPluginRepositoryImpl(this._engineProvider);

  @override
  Future<Result<PluginInfo>> getPluginInfo() async {
    try {
      final engine = await _engineProvider();

      final result = await engine.eval(
        code: '''
      (async () => {
        const { default: client } = await import('client');
        return JSON.stringify(client.pluginInfo);
      })()
    ''',
      );

      final jsonStr = result.asStringSync ?? '';

      if (jsonStr.isEmpty || jsonStr == 'undefined') {
        return Failure(ParseException('获取插件信息失败：返回为空'));
      }

      final info = PluginInfo.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
      return Success(info);
    } on AppException catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      return Failure(UnknownException(e.toString(), stackTrace: stackTrace));
    }
  }
}
