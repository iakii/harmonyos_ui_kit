// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_page_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 详情分页累积 Provider（按 URL）。

@ProviderFor(DetailPageAccumulator)
final detailPageAccumulatorProvider = DetailPageAccumulatorFamily._();

/// 详情分页累积 Provider（按 URL）。
final class DetailPageAccumulatorProvider
    extends
        $AsyncNotifierProvider<DetailPageAccumulator, DetailAccumulatorState> {
  /// 详情分页累积 Provider（按 URL）。
  DetailPageAccumulatorProvider._({
    required DetailPageAccumulatorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'detailPageAccumulatorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailPageAccumulatorHash();

  @override
  String toString() {
    return r'detailPageAccumulatorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DetailPageAccumulator create() => DetailPageAccumulator();

  @override
  bool operator ==(Object other) {
    return other is DetailPageAccumulatorProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailPageAccumulatorHash() =>
    r'afda831c78f2218490d0566d81e48dc23f9603f3';

/// 详情分页累积 Provider（按 URL）。

final class DetailPageAccumulatorFamily extends $Family
    with
        $ClassFamilyOverride<
          DetailPageAccumulator,
          AsyncValue<DetailAccumulatorState>,
          DetailAccumulatorState,
          FutureOr<DetailAccumulatorState>,
          String
        > {
  DetailPageAccumulatorFamily._()
    : super(
        retry: null,
        name: r'detailPageAccumulatorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 详情分页累积 Provider（按 URL）。

  DetailPageAccumulatorProvider call(String url) =>
      DetailPageAccumulatorProvider._(argument: url, from: this);

  @override
  String toString() => r'detailPageAccumulatorProvider';
}

/// 详情分页累积 Provider（按 URL）。

abstract class _$DetailPageAccumulator
    extends $AsyncNotifier<DetailAccumulatorState> {
  late final _$args = ref.$arg as String;
  String get url => _$args;

  FutureOr<DetailAccumulatorState> build(String url);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<DetailAccumulatorState>, DetailAccumulatorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<DetailAccumulatorState>,
                DetailAccumulatorState
              >,
              AsyncValue<DetailAccumulatorState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
