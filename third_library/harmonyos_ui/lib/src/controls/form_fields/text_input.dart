import 'package:flutter/material.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';

/// A HarmonyOS-style text input field.
///
/// A rounded text field with placeholder support, optional prefix/suffix
/// icons, and a clear button. The border uses HDS semantic colors and
/// animates on focus.
///
/// Example:
/// ```dart
/// HosTextInput(
///   placeholder: 'Enter your name',
///   onChanged: (value) => print(value),
/// )
/// ```
class HosTextInput extends StatefulWidget {
  /// Creates a HarmonyOS text input.
  const HosTextInput({
    super.key,
    this.controller,
    this.placeholder,
    this.prefixIcon,
    this.suffixIcon,
    this.showClearButton = true,
    this.obscureText = false,
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
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Placeholder text shown when the field is empty.
  final String? placeholder;

  /// Icon shown before the input text.
  final Widget? prefixIcon;

  /// Icon shown after the input text.
  final Widget? suffixIcon;

  /// Whether to show a clear button when text is not empty.
  final bool showClearButton;

  /// Whether to hide the text (for passwords).
  final bool obscureText;

  /// The maximum number of lines.
  final int? maxLines;

  /// The minimum number of lines.
  final int? minLines;

  /// The maximum number of characters.
  final int? maxLength;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// The keyboard type.
  final TextInputType? keyboardType;

  /// The text input action.
  final TextInputAction? textInputAction;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Called when editing is complete.
  final VoidCallback? onEditingComplete;

  /// Validator function.
  final FormFieldValidator<String>? validator;

  /// Auto-validation mode.
  final AutovalidateMode? autovalidateMode;

  /// Helper text shown below the field.
  final String? helperText;

  /// Error text shown below the field.
  final String? errorText;

  @override
  State<HosTextInput> createState() => _HosTextInputState();
}

class _HosTextInputState extends State<HosTextInput> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;
  bool _internalFocusNode = false;
  bool _isFocused = false;
  bool _hovering = false;

  bool _hasInternalController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasInternalController = widget.controller == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode = widget.focusNode == null;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_internalFocusNode) _focusNode.dispose();
    if (_hasInternalController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final tokens = theme.colorTokens;
    final isDark = theme.brightness == Brightness.dark;
    final showClear = widget.showClearButton && _controller.text.isNotEmpty;

    final Color borderColor;
    if (widget.errorText != null) {
      borderColor = HarmonyColors.errorColor;
    } else if (_isFocused) {
      borderColor = theme.accentColor.normal;
    } else if (_hovering) {
      borderColor = theme.accentColor.light;
    } else {
      borderColor = tokens.controlStrokeDefault;
    }

    final Color bgColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: AnimatedContainer(
            duration: theme.animationDuration,
            curve: theme.animationCurve,
            height: widget.maxLines != null && widget.maxLines! > 1 ? null : 40,
            decoration: ShapeDecoration(
              color: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side:
                    BorderSide(color: borderColor, width: _isFocused ? 1.5 : 1.0),
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: IconTheme(
                      data: IconThemeData(
                        size: 20,
                        color: _isFocused
                            ? theme.accentColor.normal
                            : theme.textSecondaryColor,
                      ),
                      child: widget.prefixIcon!,
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    maxLength: widget.maxLength,
                    readOnly: widget.readOnly,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onChanged: (value) {
                      widget.onChanged?.call(value);
                      setState(() {});
                    },
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: widget.onEditingComplete,
                    style: theme.typography.body?.copyWith(
                      color: theme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: theme.typography.body?.copyWith(
                        color: theme.textSecondaryColor,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                ),
                if (showClear)
                  GestureDetector(
                    onTap: _clearText,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.close,
                          size: 18, color: theme.textSecondaryColor),
                    ),
                  )
                else if (widget.suffixIcon != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconTheme(
                      data: IconThemeData(
                        size: 20,
                        color: theme.textSecondaryColor,
                      ),
                      child: widget.suffixIcon!,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.errorText!,
              style: theme.typography.caption?.copyWith(
                color: HarmonyColors.errorColor,
              ),
            ),
          )
        else if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.helperText!,
              style: theme.typography.caption?.copyWith(
                color: theme.textSecondaryColor,
              ),
            ),
          ),
      ],
    );
  }
}
