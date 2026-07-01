import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

class JsLayout extends StatelessWidget {
  const JsLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          HosButton(
            onPressed: () => context.go('/js_parse'),
            child: const Text('JS Parse Page'),
          ),
          const SizedBox(height: 20),
          HosButton(
            onPressed: () => context.go('/quickjs'),
            child: const Text('JS Quickjs Page'),
          ),
        ],
      ),
    );
  }
}
