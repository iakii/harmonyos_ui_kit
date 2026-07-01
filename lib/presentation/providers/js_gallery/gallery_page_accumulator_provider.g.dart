// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_page_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。

@ProviderFor(GalleryPageAccumulator)
final galleryPageAccumulatorProvider = GalleryPageAccumulatorFamily._();

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。
final class GalleryPageAccumulatorProvider
    extends
        $AsyncNotifierProvider<
          GalleryPageAccumulator,
          GalleryAccumulatorState
        > {
  /// 图集分页累积 Provider（按 URL）。
  ///
  /// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
  /// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
  /// 不再需要在 Widget 中手动维护可变字段。
  ///
  /// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
  /// 状态自然清零，无需额外重置。
  GalleryPageAccumulatorProvider._({
    required GalleryPageAccumulatorFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'galleryPageAccumulatorProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$galleryPageAccumulatorHash();

  @override
  String toString() {
    return r'galleryPageAccumulatorProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GalleryPageAccumulator create() => GalleryPageAccumulator();

  @override
  bool operator ==(Object other) {
    return other is GalleryPageAccumulatorProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$galleryPageAccumulatorHash() =>
    r'a20e4a26da36a51394658c357d2b5ed165e091c2';

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。

final class GalleryPageAccumulatorFamily extends $Family
    with
        $ClassFamilyOverride<
          GalleryPageAccumulator,
          AsyncValue<GalleryAccumulatorState>,
          GalleryAccumulatorState,
          FutureOr<GalleryAccumulatorState>,
          String
        > {
  GalleryPageAccumulatorFamily._()
    : super(
        retry: null,
        name: r'galleryPageAccumulatorProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 图集分页累积 Provider（按 URL）。
  ///
  /// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
  /// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
  /// 不再需要在 Widget 中手动维护可变字段。
  ///
  /// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
  /// 状态自然清零，无需额外重置。

  GalleryPageAccumulatorProvider call(String url) =>
      GalleryPageAccumulatorProvider._(argument: url, from: this);

  @override
  String toString() => r'galleryPageAccumulatorProvider';
}

/// 图集分页累积 Provider（按 URL）。
///
/// 封装分页累积逻辑：维护 items、currentPage、totalPage、isLoading 等状态，
/// 对外暴露 [loadNext] 和 [refresh] 两个操作。UI 通过 [ref.watch] 获取状态，
/// 不再需要在 Widget 中手动维护可变字段。
///
/// 当 url 变化时（例如切换菜单 Tab），Riverpod 自动调用 [build] 生成新实例，
/// 状态自然清零，无需额外重置。

abstract class _$GalleryPageAccumulator
    extends $AsyncNotifier<GalleryAccumulatorState> {
  late final _$args = ref.$arg as String;
  String get url => _$args;

  FutureOr<GalleryAccumulatorState> build(String url);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<GalleryAccumulatorState>,
              GalleryAccumulatorState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<GalleryAccumulatorState>,
                GalleryAccumulatorState
              >,
              AsyncValue<GalleryAccumulatorState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
