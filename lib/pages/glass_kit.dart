// ignore_for_file: deprecated_member_use

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart' show GlassContainer;
import 'package:harmonyos_ui/harmonyos_ui.dart';

class GlassKitPage extends HookWidget {
  const GlassKitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HosPage(
      showAppBar: false,
      // appBar: AppBar(title: Text('Glass Kit Page')),
      // backgroundColor: Colors.blueGrey[900],
      body: GlassContainer(
        height: 300,
        width: 400,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.40),
            Colors.white.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.60),
            Colors.white.withOpacity(0.10),
            Colors.lightBlueAccent.withOpacity(0.05),
            Colors.lightBlueAccent.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.39, 0.40, 1.0],
        ),
        blur: 15.0,
        borderWidth: 1.5,
        elevation: 3.0,
        isFrostedGlass: true,
        shadowColor: Colors.black.withOpacity(0.20),
        alignment: Alignment.center,
        frostedOpacity: 0.12,
        margin: EdgeInsets.all(8.0),
        padding: EdgeInsets.all(8.0),
      ),
    );
  }
}
