// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$detailLoadHash() => r'64b9676cc39b6902e4961c59239fb3aef963e199';

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

/// 详情加载 Provider（按链接 URL）。
///
/// 每次请求在独立 isolate 中执行，通过 [Stream] 渐进式回传进度和结果。
/// [ref.onDispose] 确保 isolate 被杀死，不残留后台线程。
///
/// Copied from [detailLoad].
@ProviderFor(detailLoad)
const detailLoadProvider = DetailLoadFamily();

/// 详情加载 Provider（按链接 URL）。
///
/// 每次请求在独立 isolate 中执行，通过 [Stream] 渐进式回传进度和结果。
/// [ref.onDispose] 确保 isolate 被杀死，不残留后台线程。
///
/// Copied from [detailLoad].
class DetailLoadFamily extends Family<AsyncValue<DetailLoadState>> {
  /// 详情加载 Provider（按链接 URL）。
  ///
  /// 每次请求在独立 isolate 中执行，通过 [Stream] 渐进式回传进度和结果。
  /// [ref.onDispose] 确保 isolate 被杀死，不残留后台线程。
  ///
  /// Copied from [detailLoad].
  const DetailLoadFamily();

  /// 详情加载 Provider（按链接 URL）。
  ///
  /// 每次请求在独立 isolate 中执行，通过 [Stream] 渐进式回传进度和结果。
  /// [ref.onDispose] 确保 isolate 被杀死，不残留后台线程。
  ///
  /// Copied from [detailLoad].
  DetailLoadProvider call(String url) {
    return DetailLoadProvider(url);
  }

  @override
  DetailLoadProvider getProviderOverride(
    covariant DetailLoadProvider provider,
  ) {
    return call(provider.url);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'detailLoadProvider';
}

/// 详情加载 Provider（按链接 URL）。
///
/// 每次请求在独立 isolate 中执行，通过 [Stream] 渐进式回传进度和结果。
/// [ref.onDispose] 确保 isolate 被杀死，不残留后台线程。
///
/// Copied from [detailLoad].
class DetailLoadProvider extends AutoDisposeStreamProvider<DetailLoadState> {
  /// 详情加载 Provider（按链接 URL）。
  ///
  /// 每次请求在独立 isolate 中执行，通过 [Stream] 渐进式回传进度和结果。
  /// [ref.onDispose] 确保 isolate 被杀死，不残留后台线程。
  ///
  /// Copied from [detailLoad].
  DetailLoadProvider(String url)
    : this._internal(
        (ref) => detailLoad(ref as DetailLoadRef, url),
        from: detailLoadProvider,
        name: r'detailLoadProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$detailLoadHash,
        dependencies: DetailLoadFamily._dependencies,
        allTransitiveDependencies: DetailLoadFamily._allTransitiveDependencies,
        url: url,
      );

  DetailLoadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.url,
  }) : super.internal();

  final String url;

  @override
  Override overrideWith(
    Stream<DetailLoadState> Function(DetailLoadRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DetailLoadProvider._internal(
        (ref) => create(ref as DetailLoadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        url: url,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<DetailLoadState> createElement() {
    return _DetailLoadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DetailLoadProvider && other.url == url;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, url.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DetailLoadRef on AutoDisposeStreamProviderRef<DetailLoadState> {
  /// The parameter `url` of this provider.
  String get url;
}

class _DetailLoadProviderElement
    extends AutoDisposeStreamProviderElement<DetailLoadState>
    with DetailLoadRef {
  _DetailLoadProviderElement(super.provider);

  @override
  String get url => (origin as DetailLoadProvider).url;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
