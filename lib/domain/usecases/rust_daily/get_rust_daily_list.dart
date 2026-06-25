import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/domain/repositories/rust_daily_repository.dart';

/// 获取 Rust Daily 分页列表用例。
class GetRustDailyList {
  final RustDailyRepository _repository;

  const GetRustDailyList(this._repository);

  Future<Result<RustDailyPageData>> call({
    required String url,
    required int page,
    required String tabKey,
  }) {
    return _repository.getList(url: url, page: page, tabKey: tabKey);
  }
}
