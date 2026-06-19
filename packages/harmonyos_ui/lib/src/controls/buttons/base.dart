import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../styles/color.dart';
import '../../styles/theme.dart';
import 'theme.dart';

// --------------------------------------------------------------------
// HosBaseButton
// --------------------------------------------------------------------

/// Abstract base for all HarmonyOS button variants.
///
/// Manages hover, press, and focus states, and provides the
/// three-layer style resolution (widget → theme → default).
///
/// Subclasses must implement [defaultStyleOf] and [themeStyleOf].
abstract class HosBaseButton extends StatefulWidget {
  /// Creates a [HosBaseButton].
  const HosBaseButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The widget below this button in the tree (typically [Text] or
  /// [Icon] or a [Row] combining both).
  final Widget child;

  /// Called when the button is tapped or otherwise activated.
  final VoidCallback? onPressed;

  /// Called when the button is long-pressed.
  final VoidCallback? onLongPress;

  /// Called when a pointer enters or exits the button.
  final ValueChanged<bool>? onHover;

  /// Called when the focus state changes.
  final ValueChanged<bool>? onFocusChange;

  /// The custom [HosButtonStyle] for this specific button instance.
  ///
  /// This has the highest priority in the style resolution chain.
  final HosButtonStyle? style;

  /// The [FocusNode] for this button.
  final FocusNode? focusNode;

  /// Whether this button should autofocus.
  final bool autofocus;

  /// Semantic label for accessibility.
  final String? semanticLabel;

  /// Whether this button is enabled.
  final bool enabled;

  // ------------------------------------------------------------------
  // Style resolution (subclasses override)
  // ------------------------------------------------------------------

  /// Returns the default style for this button variant.
  ///
  /// This is the lowest-priority layer — applied when neither a widget
  /// style nor a theme style is provided.
  HosButtonStyle defaultStyleOf(BuildContext context);

  /// Returns the theme-level style for this button variant.
  ///
  /// This is the mid-priority layer — applied when no widget style is
  /// provided for the specific property.
  HosButtonStyle? themeStyleOf(BuildContext context);

  // ------------------------------------------------------------------
  // Resolved state
  // ------------------------------------------------------------------

  /// Resolves the effective background color for the given [states].
  Color? resolveBackgroundColor(Set<WidgetState> states,
      HosButtonStyle? widgetStyle, HosButtonStyle? themeStyle,
      HosButtonStyle defaultStyle) {
    final widgetColor = widgetStyle?.backgroundColor?.resolve(states);
    if (widgetColor != null) return widgetColor;
    final themeColor = themeStyle?.backgroundColor?.resolve(states);
    if (themeColor != null) return themeColor;
    return defaultStyle.backgroundColor?.resolve(states);
  }

  /// Resolves the effective foreground color for the given [states].
  Color? resolveForegroundColor(Set<WidgetState> states,
      HosButtonStyle? widgetStyle, HosButtonStyle? themeStyle,
      HosButtonStyle defaultStyle) {
    final widgetColor = widgetStyle?.foregroundColor?.resolve(states);
    if (widgetColor != null) return widgetColor;
    final themeColor = themeStyle?.foregroundColor?.resolve(states);
    if (themeColor != null) return themeColor;
    return defaultStyle.foregroundColor?.resolve(states);
  }

  /// Resolves the effective shape for the given [states].
  OutlinedBorder? resolveShape(Set<WidgetState> states,
      HosButtonStyle? widgetStyle, HosButtonStyle? themeStyle,
      HosButtonStyle defaultStyle) {
    final widgetShape = widgetStyle?.shape?.resolve(states);
    if (widgetShape != null) return widgetShape;
    final themeShape = themeStyle?.shape?.resolve(states);
    if (themeShape != null) return themeShape;
    return defaultStyle.shape?.resolve(states);
  }

  /// Resolves the effective padding for the given [states].
  EdgeInsetsGeometry? resolvePadding(Set<WidgetState> states,
      HosButtonStyle? widgetStyle, HosButtonStyle? themeStyle,
      HosButtonStyle defaultStyle) {
    final widgetPadding = widgetStyle?.padding?.resolve(states);
    if (widgetPadding != null) return widgetPadding;
    final themePadding = themeStyle?.padding?.resolve(states);
    if (themePadding != null) return themePadding;
    return defaultStyle.padding?.resolve(states);
  }

  @override
  State<HosBaseButton> createState() => _HosBaseButtonState();
}

// --------------------------------------------------------------------
// _HosBaseButtonState
// --------------------------------------------------------------------

class _HosBaseButtonState extends State<HosBaseButton> {
  // Internal interaction state
  bool _hovering = false;
  bool _pressing = false;
  bool _shouldShowFocus = false;

  late FocusNode _focusNode;
  bool _internalFocusNode = false;

  Set<WidgetState> get _currentStates => <WidgetState>{
    if (!widget.enabled) WidgetState.disabled,
    if (_hovering) WidgetState.hovered,
    if (_pressing) WidgetState.pressed,
    if (_shouldShowFocus) WidgetState.focused,
  };

  bool get _isInteractive => widget.enabled && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode = widget.focusNode == null;
    if (widget.autofocus) {
      _focusNode.requestFocus();
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (_internalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    _shouldShowFocus = hasFocus && _focusNode.hasPrimaryFocus;
    widget.onFocusChange?.call(_shouldShowFocus);
    setState(() {});
  }

  void _handleHoverChange(bool hovering) {
    _hovering = hovering;
    widget.onHover?.call(hovering);
    setState(() {});
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isInteractive) {
      _pressing = true;
      setState(() {});
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_pressing) {
      _pressing = false;
      setState(() {});
    }
  }

  void _handleTapCancel() {
    if (_pressing) {
      _pressing = false;
      setState(() {});
    }
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  void _handleLongPress() {
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = HarmonyTheme.of(context);

    // Resolve styles
    final defaultStyle = widget.defaultStyleOf(context);
    final themeStyle = widget.themeStyleOf(context);
    final widgetStyle = widget.style;

    final states = _currentStates;

    final Color? backgroundColor =
        widget.resolveBackgroundColor(states, widgetStyle, themeStyle, defaultStyle);
    final Color? foregroundColor =
        widget.resolveForegroundColor(states, widgetStyle, themeStyle, defaultStyle);
    final OutlinedBorder? shape =
        widget.resolveShape(states, widgetStyle, themeStyle, defaultStyle);
    final EdgeInsetsGeometry? padding =
        widget.resolvePadding(states, widgetStyle, themeStyle, defaultStyle);

    final double? elevation =
        widgetStyle?.elevation?.resolve(states) ??
        themeStyle?.elevation?.resolve(states) ??
        defaultStyle.elevation?.resolve(states);

    final BorderSide? side =
        widgetStyle?.side?.resolve(states) ??
        themeStyle?.side?.resolve(states) ??
        defaultStyle.side?.resolve(states);

    final Size? minimumSize =
        widgetStyle?.minimumSize?.resolve(states) ??
        themeStyle?.minimumSize?.resolve(states) ??
        defaultStyle.minimumSize?.resolve(states);

    final Size? fixedSize =
        widgetStyle?.fixedSize?.resolve(states) ??
        themeStyle?.fixedSize?.resolve(states) ??
        defaultStyle.fixedSize?.resolve(states);

    final double? iconSize =
        widgetStyle?.iconSize ??
        themeStyle?.iconSize ??
        defaultStyle.iconSize;

    // Only enable semantics on the innermost focusable widget
    final Widget result = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: _isInteractive,
      skipTraversal: !_isInteractive,
      onKeyEvent: _onKeyEvent,
      child: GestureDetector(
        onTapDown: _isInteractive ? _handleTapDown : null,
        onTapUp: _isInteractive ? _handleTapUp : null,
        onTapCancel: _isInteractive ? _handleTapCancel : null,
        onTap: _isInteractive ? _handleTap : null,
        onLongPress: _isInteractive ? _handleLongPress : null,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        child: MouseRegion(
          onEnter: (_) => _handleHoverChange(true),
          onExit: (_) => _handleHoverChange(false),
          child: AnimatedContainer(
            duration: theme.animationDuration,
            curve: theme.animationCurve,
            decoration: ShapeDecoration(
              color: backgroundColor ?? HarmonyColors.transparent,
              shape: shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: side ?? BorderSide.none,
                  ),
              shadows: elevation != null && elevation > 0
                  ? [BoxShadow(
                      color: theme.shadowColor
                          .withValues(alpha: 0.15),
                      blurRadius: elevation,
                      offset: Offset(0, elevation / 2),
                    )]
                  : null,
            ),
            constraints: fixedSize != null
                ? BoxConstraints.tight(fixedSize)
                : BoxConstraints(
                    minWidth: minimumSize?.width ?? 0,
                    minHeight: minimumSize?.height ?? 0,
                  ),
            child: IconTheme(
              data: IconThemeData(
                size: iconSize ?? 18,
                color: foregroundColor ?? theme.textColor,
              ),
              child: DefaultTextStyle(
                style: theme.typography.title3!.copyWith(
                  color: foregroundColor ?? theme.textColor,
                ).merge(
                  widgetStyle?.textStyle?.resolve(states) ??
                      themeStyle?.textStyle?.resolve(states) ??
                      defaultStyle.textStyle?.resolve(states),
                ),
                child: Padding(
                  padding: padding ??
                      const EdgeInsetsDirectional.symmetric(
                          horizontal: 16, vertical: 8),
                  child: Semantics(
                    button: true,
                    enabled: _isInteractive,
                    label: widget.semanticLabel,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return result;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      if (_isInteractive) {
        widget.onPressed?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
