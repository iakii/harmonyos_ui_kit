// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intro_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(JsIntro)
final jsIntroProvider = JsIntroFamily._();

final class JsIntroProvider extends $NotifierProvider<JsIntro, IntroData> {
  JsIntroProvider._({
    required JsIntroFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'jsIntroProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$jsIntroHash();

  @override
  String toString() {
    return r'jsIntroProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  JsIntro create() => JsIntro();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IntroData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IntroData>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is JsIntroProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$jsIntroHash() => r'c7e882fe5f26dbfafe61ffe5869e0031dcd66938';

final class JsIntroFamily extends $Family
    with
        $ClassFamilyOverride<JsIntro, IntroData, IntroData, IntroData, String> {
  JsIntroFamily._()
    : super(
        retry: null,
        name: r'jsIntroProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  JsIntroProvider call(String url) =>
      JsIntroProvider._(argument: url, from: this);

  @override
  String toString() => r'jsIntroProvider';
}

abstract class _$JsIntro extends $Notifier<IntroData> {
  late final _$args = ref.$arg as String;
  String get url => _$args;

  IntroData build(String url);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<IntroData, IntroData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<IntroData, IntroData>,
              IntroData,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
