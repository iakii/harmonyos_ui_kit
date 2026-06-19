import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:t_lib/lib.dart';
import 'app.dart';

/// 应用入口。
///
/// 职责：
/// 1. 确保 Flutter 绑定初始化
/// 2. 初始化 Rust FFI 桥接（flutter_rust_bridge）
/// 3. 用 [ProviderScope] 包裹整个应用（Riverpod 依赖注入根节点）
/// 4. 启动 [MyApp]
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 在 runApp 之前初始化 Rust FFI，避免组件树中的 FutureProvider 竞态
  // await RustLib.init();

  runApp(const ProviderScope(child: MyApp()));
}
