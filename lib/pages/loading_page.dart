import 'package:flutter/material.dart' show Scaffold;
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:rohos_app/widgets/loading.dart' show Loading;

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HosAppBar(title: '鸿蒙加载动画实现', leading: BackIcon()),
      body: ListView(
        children: [
          Loading(size: 230),
          Loading(size: 210),
          Loading(size: 190),
          Loading(size: 170),
          Loading(size: 150),
          Loading(size: 130),
          Loading(size: 110),
          Loading(size: 90),
          Loading(size: 70),
          Loading(size: 50),
          Loading(size: 30),
          Loading(size: 10),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
