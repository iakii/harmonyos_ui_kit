import 'package:rohos_app/core/error/app_exception.dart';
import 'package:rohos_app/core/error/result.dart';
import 'package:rohos_app/data/datasources/remote/rust_daily_remote_datasource.dart';
import 'package:rohos_app/domain/entities/rust_daily_page_data.dart';
import 'package:rohos_app/domain/repositories/rust_daily_repository.dart';

/// RustDailyRepository 实现。
class RustDailyRepositoryImpl implements RustDailyRepository {
  final RustDailyRemoteDataSource _dataSource;

  const RustDailyRepositoryImpl(this._dataSource);

  @override
  Future<Result<RustDailyPageData>> getList({
    required String url,
    required int page,
    required String tabKey,
  }) async {
    try {
      final result = await _dataSource.getList(url: url, page: page);
      return Success(RustDailyPageData(
        html: result.html,
        liItems: result.liItems,
        totalPage: result.totalPage,
        currentPage: page,
      ));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      return Failure(UnknownException(e.toString(), stackTrace: stackTrace));
    }
  }

  @override
  Future<Result<RustDailyPageData>> getDetail({required String url}) async {
    try {
      final html = await _dataSource.getDetail(url: url);
      return Success(RustDailyPageData(
        html: html,
        liItems: [],
        totalPage: 1,
        currentPage: 1,
      ));
    } on AppException catch (e) {
      return Failure(e);
    } catch (e, stackTrace) {
      return Failure(UnknownException(e.toString(), stackTrace: stackTrace));
    }
  }
}
