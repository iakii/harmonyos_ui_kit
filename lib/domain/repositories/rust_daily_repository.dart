import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';

/// Rust Daily 数据仓库接口。
abstract class RustDailyRepository {
  /// 获取 Rust Daily 分页列表。
  Future<Result<RustDailyPageData>> getList({
    required String url,
    required int page,
    required String tabKey,
  });

  /// 获取 Rust Daily 文章详情。
  Future<Result<RustDailyPageData>> getDetail({required String url});
}
