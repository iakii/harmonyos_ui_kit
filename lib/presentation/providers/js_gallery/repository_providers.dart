import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/data/datasources/local/js_source_local_datasource.dart';
import 'package:rohos_app/data/datasources/remote/js_config_remote_datasource.dart';
import 'package:rohos_app/data/datasources/remote/rust_daily_remote_datasource.dart';
import 'package:rohos_app/data/repositories/js_config_repository_impl.dart';
import 'package:rohos_app/data/repositories/js_gallery_repository_impl.dart';
import 'package:rohos_app/data/repositories/js_plugin_repository_impl.dart';
import 'package:rohos_app/data/repositories/rust_daily_repository_impl.dart';
import 'package:rohos_app/domain/repositories/js_config_repository.dart';
import 'package:rohos_app/domain/repositories/js_gallery_repository.dart';
import 'package:rohos_app/domain/repositories/js_plugin_repository.dart';
import 'package:rohos_app/domain/repositories/rust_daily_repository.dart';
import 'package:rohos_app/presentation/providers/init/dio_provider.dart';
import 'package:rohos_app/presentation/providers/js_engine/js_engine_provider.dart';

/// JsGalleryRepository 的 Riverpod Provider。
///
/// [ref.watch(jsEngineProvider)] 在 builder 中建立依赖链：
/// jsConfig 变化 → jsEngine 重建 → 本 Provider 重建。
/// 闭包中 [ref.read] 获取最新引擎 future（builder 外安全）。
final jsGalleryRepositoryProvider = Provider<JsGalleryRepository>((ref) {
  ref.watch(jsEngineProvider);
  return JsGalleryRepositoryImpl(
    () => ref.read(jsEngineProvider.future),
  );
});

/// JsPluginRepository 的 Riverpod Provider。
final jsPluginRepositoryProvider = Provider<JsPluginRepository>((ref) {
  ref.watch(jsEngineProvider);
  return JsPluginRepositoryImpl(
    () => ref.read(jsEngineProvider.future),
  );
});

/// JsConfigRepository 的 Riverpod Provider。
///
/// 组合远程数据源（GitHub 拉取）和本地数据源（SharedPreferences 持久化）。
final jsConfigRepositoryProvider = Provider<JsConfigRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return JsConfigRepositoryImpl(
    JsConfigRemoteDataSource(dio),
    JsSourceLocalDataSource(),
  );
});

/// RustDailyRepository 的 Riverpod Provider。
final rustDailyRepositoryProvider = Provider<RustDailyRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RustDailyRepositoryImpl(
    RustDailyRemoteDataSource(dio),
  );
});
