import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 计数器状态管理 —— 演示 Riverpod StateNotifier 用法。
///
/// 替代原来 HarmonyOSPage 中的 `_counter` + `setState`。
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}
