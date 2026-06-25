import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/domain/repositories/rust_daily_repository.dart';

/// 获取 Rust Daily 文章详情用例。
class GetRustDailyDetail {
  final RustDailyRepository _repository;

  const GetRustDailyDetail(this._repository);

  Future<Result<RustDailyPageData>> call({required String url}) {
    return _repository.getDetail(url: url);
  }
}
