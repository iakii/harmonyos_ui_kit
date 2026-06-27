// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detail_page_accumulator_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$detailPageAccumulatorHash() =>
    r'0befd316b7f26b189e4a3ce1ac3eb9e3951f5fac';

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

abstract class _$DetailPageAccumulator
    extends BuildlessAutoDisposeAsyncNotifier<DetailAccumulatorState> {
  late final String url;

  FutureOr<DetailAccumulatorState> build(String url);
}

/// 详情分页累积 Provider（按 URL）。
///
/// Copied from [DetailPageAccumulator].
@ProviderFor(DetailPageAccumulator)
const detailPageAccumulatorProvider = DetailPageAccumulatorFamily();

/// 详情分页累积 Provider（按 URL）。
///
/// Copied from [DetailPageAccumulator].
class DetailPageAccumulatorFamily
    extends Family<AsyncValue<DetailAccumulatorState>> {
  /// 详情分页累积 Provider（按 URL）。
  ///
  /// Copied from [DetailPageAccumulator].
  const DetailPageAccumulatorFamily();

  /// 详情分页累积 Provider（按 URL）。
  ///
  /// Copied from [DetailPageAccumulator].
  DetailPageAccumulatorProvider call(String url) {
    return DetailPageAccumulatorProvider(url);
  }

  @override
  DetailPageAccumulatorProvider getProviderOverride(
    covariant DetailPageAccumulatorProvider provider,
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
  String? get name => r'detailPageAccumulatorProvider';
}

/// 详情分页累积 Provider（按 URL）。
///
/// Copied from [DetailPageAccumulator].
class DetailPageAccumulatorProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          DetailPageAccumulator,
          DetailAccumulatorState
        > {
  /// 详情分页累积 Provider（按 URL）。
  ///
  /// Copied from [DetailPageAccumulator].
  DetailPageAccumulatorProvider(String url)
    : this._internal(
        () => DetailPageAccumulator()..url = url,
        from: detailPageAccumulatorProvider,
        name: r'detailPageAccumulatorProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$detailPageAccumulatorHash,
        dependencies: DetailPageAccumulatorFamily._dependencies,
        allTransitiveDependencies:
            DetailPageAccumulatorFamily._allTransitiveDependencies,
        url: url,
      );

  DetailPageAccumulatorProvider._internal(
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
  FutureOr<DetailAccumulatorState> runNotifierBuild(
    covariant DetailPageAccumulator notifier,
  ) {
    return notifier.build(url);
  }

  @override
  Override overrideWith(DetailPageAccumulator Function() create) {
    return ProviderOverride(
      origin: this,
      override: DetailPageAccumulatorProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<
    DetailPageAccumulator,
    DetailAccumulatorState
  >
  createElement() {
    return _DetailPageAccumulatorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DetailPageAccumulatorProvider && other.url == url;
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
mixin DetailPageAccumulatorRef
    on AutoDisposeAsyncNotifierProviderRef<DetailAccumulatorState> {
  /// The parameter `url` of this provider.
  String get url;
}

class _DetailPageAccumulatorProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          DetailPageAccumulator,
          DetailAccumulatorState
        >
    with DetailPageAccumulatorRef {
  _DetailPageAccumulatorProviderElement(super.provider);

  @override
  String get url => (origin as DetailPageAccumulatorProvider).url;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
