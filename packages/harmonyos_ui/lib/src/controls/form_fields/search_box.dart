import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// A HarmonyOS-style search box.
///
/// A text input with a search icon prefix and optional clear button.
/// The search icon animates to the accent color when focused.
///
/// Example:
/// ```dart
/// HosSearchBox(
///   placeholder: 'Search...',
///   onChanged: (value) => print(value),
///   onSubmitted: (value) => search(value),
/// )
/// ```
class HosSearchBox extends StatefulWidget {
  /// Creates a HarmonyOS search box.
  const HosSearchBox({
    super.key,
    this.controller,
    this.placeholder = 'Search',
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? placeholder;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Called when the clear button is pressed.
  final VoidCallback? onClear;

  @override
  State<HosSearchBox> createState() => _HosSearchBoxState();
}

class _HosSearchBoxState extends State<HosSearchBox> {
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
    widget.onClear?.call();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);
    final tokens = theme.colorTokens;
    final isDark = theme.brightness == Brightness.dark;
    final showClear = _controller.text.isNotEmpty;

    final Color borderColor;
    if (_isFocused) {
      borderColor = theme.accentColor.normal;
    } else if (_hovering) {
      borderColor = theme.accentColor.light;
    } else {
      borderColor = tokens.controlStrokeDefault;
    }

    final Color bgColor = isDark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: theme.animationDuration,
        curve: theme.animationCurve,
        height: 40,
        decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Pill shape for search
            side: BorderSide(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, right: 8),
              child: Icon(Icons.search, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  setState(() {});
                },
                onSubmitted: widget.onSubmitted,
                style: theme.typography.body?.copyWith(color: theme.textColor),
                decoration: InputDecoration(
                  hintText: widget.placeholder ?? 'Search',
                  hintStyle: theme.typography.body?.copyWith(
                    color: theme.textSecondaryColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (showClear)
              GestureDetector(
                onTap: _clearText,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.textSecondaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
