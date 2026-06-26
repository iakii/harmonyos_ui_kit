// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$jsIntroHash() => r'c7e882fe5f26dbfafe61ffe5869e0031dcd66938';

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

abstract class _$JsIntro extends BuildlessAutoDisposeNotifier<IntroData> {
  late final String url;

  IntroData build(String url);
}

/// See also [JsIntro].
@ProviderFor(JsIntro)
const jsIntroProvider = JsIntroFamily();

/// See also [JsIntro].
class JsIntroFamily extends Family<IntroData> {
  /// See also [JsIntro].
  const JsIntroFamily();

  /// See also [JsIntro].
  JsIntroProvider call(String url) {
    return JsIntroProvider(url);
  }

  @override
  JsIntroProvider getProviderOverride(covariant JsIntroProvider provider) {
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
  String? get name => r'jsIntroProvider';
}

/// See also [JsIntro].
class JsIntroProvider
    extends AutoDisposeNotifierProviderImpl<JsIntro, IntroData> {
  /// See also [JsIntro].
  JsIntroProvider(String url)
    : this._internal(
        () => JsIntro()..url = url,
        from: jsIntroProvider,
        name: r'jsIntroProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$jsIntroHash,
        dependencies: JsIntroFamily._dependencies,
        allTransitiveDependencies: JsIntroFamily._allTransitiveDependencies,
        url: url,
      );

  JsIntroProvider._internal(
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
  IntroData runNotifierBuild(covariant JsIntro notifier) {
    return notifier.build(url);
  }

  @override
  Override overrideWith(JsIntro Function() create) {
    return ProviderOverride(
      origin: this,
      override: JsIntroProvider._internal(
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
  AutoDisposeNotifierProviderElement<JsIntro, IntroData> createElement() {
    return _JsIntroProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JsIntroProvider && other.url == url;
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
mixin JsIntroRef on AutoDisposeNotifierProviderRef<IntroData> {
  /// The parameter `url` of this provider.
  String get url;
}

class _JsIntroProviderElement
    extends AutoDisposeNotifierProviderElement<JsIntro, IntroData>
    with JsIntroRef {
  _JsIntroProviderElement(super.provider);

  @override
  String get url => (origin as JsIntroProvider).url;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
