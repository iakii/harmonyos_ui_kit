// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$galleryIsolateHash() => r'66f53bdd93ab90d0f080e21f0abf2890b767fd9e';

/// 全局 Gallery isolate 管理器（单例，所有图集请求复用同一 isolate）。
///
/// `keepAlive: true` 确保 isolate 跨请求存活，但 dispose 时会被杀死。
///
/// Copied from [galleryIsolate].
@ProviderFor(galleryIsolate)
final galleryIsolateProvider =
    FutureProvider<IsolateManager<String, _GalleryParams>>.internal(
      galleryIsolate,
      name: r'galleryIsolateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$galleryIsolateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GalleryIsolateRef =
    FutureProviderRef<IsolateManager<String, _GalleryParams>>;
String _$galleryHash() => r'1f5f236d3f72294758fd75f814723378cfa60918';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
/// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
///
/// Copied from [gallery].
@ProviderFor(gallery)
const galleryProvider = GalleryFamily();

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
/// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
///
/// Copied from [gallery].
class GalleryFamily extends Family<AsyncValue<GalleryPageData>> {
  /// 图集列表 Provider（按 URL 和页码分页）。
  ///
  /// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
  /// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
  ///
  /// Copied from [gallery].
  const GalleryFamily();

  /// 图集列表 Provider（按 URL 和页码分页）。
  ///
  /// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
  /// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
  ///
  /// Copied from [gallery].
  GalleryProvider call({required String url, required int page}) {
    return GalleryProvider(url: url, page: page);
  }

  @override
  GalleryProvider getProviderOverride(covariant GalleryProvider provider) {
    return call(url: provider.url, page: provider.page);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'galleryProvider';
}

/// 图集列表 Provider（按 URL 和页码分页）。
///
/// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
/// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
///
/// Copied from [gallery].
class GalleryProvider extends AutoDisposeFutureProvider<GalleryPageData> {
  /// 图集列表 Provider（按 URL 和页码分页）。
  ///
  /// 依赖 [galleryIsolateProvider] 在后台 isolate 执行 JS eval，
  /// 不阻塞主 UI 线程。dispose 时不杀死共享 isolate，仅取消本次请求。
  ///
  /// Copied from [gallery].
  GalleryProvider({required String url, required int page})
    : this._internal(
        (ref) => gallery(ref as GalleryRef, url: url, page: page),
        from: galleryProvider,
        name: r'galleryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$galleryHash,
        dependencies: GalleryFamily._dependencies,
        allTransitiveDependencies: GalleryFamily._allTransitiveDependencies,
        url: url,
        page: page,
      );

  GalleryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
    required this.page,
  }) : super.internal();

  final String url;
  final int page;

  @override
  Override overrideWith(
    FutureOr<GalleryPageData> Function(GalleryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GalleryProvider._internal(
        (ref) => create(ref as GalleryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
        page: page,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<GalleryPageData> createElement() {
    return _GalleryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GalleryProvider && other.url == url && other.page == page;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);
    hash = _SystemHash.combine(hash, page.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GalleryRef on AutoDisposeFutureProviderRef<GalleryPageData> {
  /// The parameter `url` of this provider.
  String get url;

  /// The parameter `page` of this provider.
  int get page;
}

class _GalleryProviderElement
    extends AutoDisposeFutureProviderElement<GalleryPageData>
    with GalleryRef {
  _GalleryProviderElement(super.provider);

  @override
  String get url => (origin as GalleryProvider).url;
  @override
  int get page => (origin as GalleryProvider).page;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
