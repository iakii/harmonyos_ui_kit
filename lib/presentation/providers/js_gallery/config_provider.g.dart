// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JsConfig)
final jsConfigProvider = JsConfigProvider._();

final class JsConfigProvider
    extends $AsyncNotifierProvider<JsConfig, JsConfigData> {
  JsConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'jsConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$jsConfigHash();

  @$internal
  @override
  JsConfig create() => JsConfig();
}

String _$jsConfigHash() => r'bac00126f3101982fbe689281ef8523f683497c3';

abstract class _$JsConfig extends $AsyncNotifier<JsConfigData> {
  FutureOr<JsConfigData> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<JsConfigData>, JsConfigData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<JsConfigData>, JsConfigData>,
              AsyncValue<JsConfigData>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
