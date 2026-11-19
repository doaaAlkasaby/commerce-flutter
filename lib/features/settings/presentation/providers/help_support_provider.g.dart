// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_support_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(helpSupport)
final helpSupportProvider = HelpSupportProvider._();

final class HelpSupportProvider
    extends
        $FunctionalProvider<
          AsyncValue<HelpSupportModel>,
          HelpSupportModel,
          FutureOr<HelpSupportModel>
        >
    with $FutureModifier<HelpSupportModel>, $FutureProvider<HelpSupportModel> {
  HelpSupportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'helpSupportProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$helpSupportHash();

  @$internal
  @override
  $FutureProviderElement<HelpSupportModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<HelpSupportModel> create(Ref ref) {
    return helpSupport(ref);
  }
}

String _$helpSupportHash() => r'9d505f8d12639e08569651d7fb968ee7cfaa2db8';
