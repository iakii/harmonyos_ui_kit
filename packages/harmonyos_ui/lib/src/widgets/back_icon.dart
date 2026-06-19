import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

class BackIcon extends StatelessWidget {
  const BackIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: HarmonyTheme.of(context).surfaceColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        iconSize: 20,
        splashRadius: 20,
        icon: const Icon(Icons.arrow_back_ios_new),
        onPressed: () {
          Navigator.of(context).canPop() ? Navigator.of(context).pop() : null;
          // Navigator.of(context).pop();
        },
      ),
    );
  }
}
