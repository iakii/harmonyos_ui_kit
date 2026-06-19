import 'package:flutter/material.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';

/// A HarmonyOS-style password input field.
///
/// A text input with a visibility toggle button to show/hide the
/// password. Supports all standard text input features plus
/// password-specific behavior.
///
/// Example:
/// ```dart
/// HosPasswordInput(
///   placeholder: 'Enter password',
///   onChanged: (value) => print(value),
/// )
/// ```
class HosPasswordInput extends StatefulWidget {
  /// Creates a HarmonyOS password input.
  const HosPasswordInput({
    super.key,
    this.controller,
    this.placeholder,
    this.prefixIcon,
    this.showVisibilityToggle = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autovalidateMode,
    this.helperText,
    this.errorText,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? placeholder;

  /// Icon shown before the input text.
  final Widget? prefixIcon;

  /// Whether to show a visibility toggle button.
  final bool showVisibilityToggle;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Validator function.
  final FormFieldValidator<String>? validator;

  /// Auto-validation mode.
  final AutovalidateMode? autovalidateMode;

  /// Helper text shown below.
  final String? helperText;

  /// Error text shown below.
  final String? errorText;

  @override
  State<HosPasswordInput> createState() => _HosPasswordInputState();
}

class _HosPasswordInputState extends State<HosPasswordInput> {
  late final TextEditingController _controller;
  late FocusNode _focusNode;
  bool _internalFocusNode = false;
  bool _obscureText = true;
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

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final tokens = theme.colorTokens;
    final isDark = theme.brightness == Brightness.dark;

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
            height: 40,
            decoration: ShapeDecoration(
              color: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: borderColor, width: _isFocused ? 1.5 : 1.0),
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
                    obscureText: _obscureText,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
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
                    ),
                  ),
                ),
                if (widget.showVisibilityToggle)
                  GestureDetector(
                    onTap: _toggleVisibility,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        _obscureText
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                        color: _isFocused
                            ? theme.accentColor.normal
                            : theme.textSecondaryColor,
                      ),
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
