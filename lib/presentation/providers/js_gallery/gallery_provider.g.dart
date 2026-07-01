// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 通过 [jsGalleryRepositoryProvider] 经由 Repository → JsEngine 获取数据。

@ProviderFor(gallery)
final galleryProvider = GalleryFamily._();

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 通过 [jsGalleryRepositoryProvider] 经由 Repository → JsEngine 获取数据。

final class GalleryProvider
    extends
        $FunctionalProvider<
          AsyncValue<GalleryPageData>,
          GalleryPageData,
          FutureOr<GalleryPageData>
        >
    with $FutureModifier<GalleryPageData>, $FutureProvider<GalleryPageData> {
  /// 图集列表 Provider（按 URL 和页码分页）。
  ///
  /// 通过 [jsGalleryRepositoryProvider] 经由 Repository → JsEngine 获取数据。
  GalleryProvider._({
    required GalleryFamily super.from,
    required ({String url, int page}) super.argument,
  }) : super(
         retry: null,
         name: r'galleryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$galleryHash();

  @override
  String toString() {
    return r'galleryProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<GalleryPageData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GalleryPageData> create(Ref ref) {
    final argument = this.argument as ({String url, int page});
    return gallery(ref, url: argument.url, page: argument.page);
  }

  @override
  bool operator ==(Object other) {
    return other is GalleryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$galleryHash() => r'ea217e8383a2ed696643e5421e0aa69027d53b7a';

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 通过 [jsGalleryRepositoryProvider] 经由 Repository → JsEngine 获取数据。

final class GalleryFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<GalleryPageData>,
          ({String url, int page})
        > {
  GalleryFamily._()
    : super(
        retry: null,
        name: r'galleryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 图集列表 Provider（按 URL 和页码分页）。
  ///
  /// 通过 [jsGalleryRepositoryProvider] 经由 Repository → JsEngine 获取数据。

  GalleryProvider call({required String url, required int page}) =>
      GalleryProvider._(argument: (url: url, page: page), from: this);

  @override
  String toString() => r'galleryProvider';
}
