// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$detailLoadHash() => r'f97fa123e650c5aa6a5f85a9b1eaedd57ffa1edf';

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

abstract class _$DetailLoad
    extends BuildlessAutoDisposeStreamNotifier<DetailLoadState> {
  late final String url;

  Stream<DetailLoadState> build(String url);
}

/// 详情加载 Provider（按链接 URL）。
///
/// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
/// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
/// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
///
/// Copied from [DetailLoad].
@ProviderFor(DetailLoad)
const detailLoadProvider = DetailLoadFamily();

/// 详情加载 Provider（按链接 URL）。
///
/// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
/// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
/// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
///
/// Copied from [DetailLoad].
class DetailLoadFamily extends Family<AsyncValue<DetailLoadState>> {
  /// 详情加载 Provider（按链接 URL）。
  ///
  /// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
  /// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
  /// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
  ///
  /// Copied from [DetailLoad].
  const DetailLoadFamily();

  /// 详情加载 Provider（按链接 URL）。
  ///
  /// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
  /// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
  /// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
  ///
  /// Copied from [DetailLoad].
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
/// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
/// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
/// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
///
/// Copied from [DetailLoad].
class DetailLoadProvider
    extends AutoDisposeStreamNotifierProviderImpl<DetailLoad, DetailLoadState> {
  /// 详情加载 Provider（按链接 URL）。
  ///
  /// JS 执行（含 fetch）在后台 isolate 中进行，不阻塞 UI。
  /// [Isolate.kill] 同步杀死线程，dispose 可靠终止。
  /// 局部变量 + 字段双引用确保任意 await 间隙都不会漏杀。
  ///
  /// Copied from [DetailLoad].
  DetailLoadProvider(String url)
    : this._internal(
        () => DetailLoad()..url = url,
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
  Stream<DetailLoadState> runNotifierBuild(covariant DetailLoad notifier) {
    return notifier.build(url);
  }

  @override
  Override overrideWith(DetailLoad Function() create) {
    return ProviderOverride(
      origin: this,
      override: DetailLoadProvider._internal(
        () => create()..url = url,
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
  AutoDisposeStreamNotifierProviderElement<DetailLoad, DetailLoadState>
  createElement() {
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
mixin DetailLoadRef on AutoDisposeStreamNotifierProviderRef<DetailLoadState> {
  /// The parameter `url` of this provider.
  String get url;
}

class _DetailLoadProviderElement
    extends
        AutoDisposeStreamNotifierProviderElement<DetailLoad, DetailLoadState>
    with DetailLoadRef {
  _DetailLoadProviderElement(super.provider);

  @override
  String get url => (origin as DetailLoadProvider).url;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
