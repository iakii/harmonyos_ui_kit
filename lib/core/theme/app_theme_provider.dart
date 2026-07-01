import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';

/// 主题模式 Provider —— 控制 light / dark / system。
///
/// 使用方式：
/// ```dart
/// final themeMode = ref.watch(themeModeProvider);
/// ```
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// 根据当前主题模式返回对应的 [HarmonyThemeData]。
///
/// 注意：system 模式下由 HarmonyOSApp 内部根据平台亮度自动选择，
/// 这里返回 light 作为 fallback。
final harmonyThemeDataProvider = Provider<HarmonyThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return switch (mode) {
    ThemeMode.light => HarmonyThemeData.light(),
    ThemeMode.dark => HarmonyThemeData.dark(),
    ThemeMode.system =>
      HarmonyThemeData.light(), // fallback，实际由 HarmonyOSApp 处理
  };
});
