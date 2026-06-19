import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS form field wrapping [HosTextInput].
///
/// Integrates with Flutter's [Form] and [FormField] validation system while
/// maintaining the HarmonyOS visual style. Use this inside a [Form] widget
/// when you need form-level validation and submission.
///
/// Example:
/// ```dart
/// final _formKey = GlobalKey<FormState>();
///
/// Form(
///   key: _formKey,
///   child: HosTextFormInput(
///     placeholder: 'Email',
///     validator: (v) => v?.contains('@') == true ? null : 'Invalid email',
///     onSaved: (v) => _email = v,
///   ),
/// )
/// ```
class HosTextFormInput extends FormField<String> {
  /// Creates a HarmonyOS text form input.
  HosTextFormInput({
    super.key,
    super.initialValue,
    super.validator,
    super.onSaved,
    super.autovalidateMode,
    super.enabled,
    super.restorationId,
    this.controller,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.helperText,
  }) : super(
         builder: (FormFieldState<String> state) {
           final effectiveErrorText = state.errorText;

           // We import HosTextInput via a dynamic import or use a builder
           return _HosTextFormInputBuilder(
             state: state,
             controller: controller,
             placeholder: placeholder,
             prefixIcon: prefixIcon,
             suffixIcon: suffixIcon,
             showClearButton: showClearButton,
             maxLines: maxLines,
             minLines: minLines,
             maxLength: maxLength,
             readOnly: readOnly,
             autofocus: autofocus,
             focusNode: focusNode,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             onChanged: onChanged,
             onSubmitted: onSubmitted,
             onEditingComplete: onEditingComplete,
             helperText: helperText,
             errorText: effectiveErrorText,
           );
         },
       );

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? placeholder;

  /// Icon before input.
  final Widget? prefixIcon;

  /// Icon after input.
  final Widget? suffixIcon;

  /// Show clear button.
  final bool showClearButton;

  /// Max lines.
  final int? maxLines;

  /// Min lines.
  final int? minLines;

  /// Max length.
  final int? maxLength;

  /// Read-only.
  final bool readOnly;

  /// Autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// On changed callback.
  final ValueChanged<String>? onChanged;

  /// On submitted callback.
  final ValueChanged<String>? onSubmitted;

  /// On editing complete callback.
  final VoidCallback? onEditingComplete;

  /// Helper text.
  final String? helperText;

  @override
  FormFieldState<String> createState() => _HosTextFormInputState();
}

class _HosTextFormInputState extends FormFieldState<String> {
  @override
  void didChange(String? value) {
    super.didChange(value);
    (widget as HosTextFormInput).onChanged?.call(value ?? '');
  }
}

// Internal widget to build the actual UI, avoiding direct imports
// of HosTextInput to prevent circular dependency issues.
class _HosTextFormInputBuilder extends StatelessWidget {
  const _HosTextFormInputBuilder({
    required this.state,
    this.controller,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.helperText,
    this.errorText,
  });

  final FormFieldState<String> state;
  final TextEditingController? controller;
  final String? placeholder;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showClearButton;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final String? helperText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    // Use a standard Flutter TextFormField styled with HOS theme
    // as a simpler approach for Form integration
    return TextFormField(
      controller: controller,
      initialValue: state.value,
      onChanged: (value) {
        state.didChange(value);
        onChanged?.call(value);
      },
      onSaved: (_) {},
      validator: (_) => null, // Validation handled by FormField
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      readOnly: readOnly,
      autofocus: autofocus,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        hintText: placeholder,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        errorText: errorText,
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: HarmonyTheme.of(context).accentColor,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }
}
