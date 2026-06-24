import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';

/// 应用入口。
///
/// 职责：
/// 1. 用 [ProviderScope] 包裹整个应用（Riverpod 依赖注入根节点）
/// 2. 启动 [MyApp]
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
