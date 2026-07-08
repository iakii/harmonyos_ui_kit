import 'package:rohos_app/data/datasources/local/js_source_local_datasource.dart';
import 'package:rohos_app/data/datasources/remote/js_config_remote_datasource.dart';
import 'package:rohos_app/domain/entities/site_config.dart';
import 'package:rohos_app/domain/repositories/js_config_repository.dart';

/// JsConfigRepository 实现。
///
/// 协调远程数据源（GitHub 获取 config 和 JS）和本地数据源（SharedPreferences）。
class JsConfigRepositoryImpl implements JsConfigRepository {
  final JsConfigRemoteDataSource _remoteDataSource;
  final JsSourceLocalDataSource _localDataSource;

  const JsConfigRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  Future<List<SiteConfig>> getSites() => _remoteDataSource.getSites();

  @override
  Future<String> loadJsContent(String assets) =>
      _remoteDataSource.loadJsContent(assets);

  @override
  Future<JsConfigData> select(String assets) async {
    await _localDataSource.saveSource(assets);
    final jsContent = await _remoteDataSource.loadJsContent(assets);
    final sites = await _remoteDataSource.getSites();
    return JsConfigData(sites, jsContent, assets);
  }

  @override
  Future<void> clear() async {
    await _localDataSource.clearSource();
  }
}
