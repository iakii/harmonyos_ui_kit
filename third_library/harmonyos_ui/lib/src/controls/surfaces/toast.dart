import 'package:flutter/material.dart';

import '../../styles/theme.dart';

/// Shows a HarmonyOS-style toast message at the bottom of the screen.
///
/// A non-modal, auto-dismissing notification. The toast slides up from
/// the bottom and fades out after a duration.
///
/// Example:
/// ```dart
/// showHosToast(context: context, message: 'Saved successfully');
/// ```
void showHosToast({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  final theme = HarmonyTheme.of(context);
  final overlay = Overlay.of(context);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _HosToastWidget(
      message: message,
      theme: theme,
      onDismiss: () {
        entry.remove();
      },
    ),
  );

  overlay.insert(entry);

  Future.delayed(duration, () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

class _HosToastWidget extends StatefulWidget {
  const _HosToastWidget({
    required this.message,
    required this.theme,
    required this.onDismiss,
  });

  final String message;
  final HarmonyThemeData theme;
  final VoidCallback onDismiss;

  @override
  State<_HosToastWidget> createState() => _HosToastWidgetState();
}

class _HosToastWidgetState extends State<_HosToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 80,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _opacityAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: ShapeDecoration(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF333333)
                            : const Color(0xE5333333),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.message,
                        style: theme.typography.body?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
