// ignore_for_file: deprecated_member_use

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

class GlassKitPage extends HookWidget {
  const GlassKitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HosPage(
      showAppBar: false,

      // appBar: AppBar(title: Text('Glass Kit Page')),
      // backgroundColor: Colors.blueGrey[900],
    );
  }
}
