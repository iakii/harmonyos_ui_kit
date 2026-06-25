# RustDailyProvider 改为 @riverpod class

## Context

当前 `rust_daily_provider.dart` 使用旧式 `FutureProvider.family<RustDailyPageData, RustDailyParams>` 手动声明方式。项目中 `js_gallery` 模块已有 3 个 `@riverpod class` 示例（`JsConfig`、`DetailLoad`、`gallery`），应将此文件改为一致的 `@riverpod class` 风格，以保持代码风格统一、减少手动样板代码。

## 改动范围

### 修改 1 个文件

**`lib/presentation/providers/rust_daily/rust_daily_provider.dart`**

旧：
```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
// ...
final rustDailyProvider =
    FutureProvider.family<RustDailyPageData, RustDailyParams>((ref, params) async {
      // ... fetch & parse logic
    });

class RustDailyParams { ... }
```

新：
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ...
part 'rust_daily_provider.g.dart';

@riverpod
class RustDaily extends _$RustDaily {
  @override
  FutureOr<RustDailyPageData> build(RustDailyParams params) async {
    // ... same fetch & parse logic (body unchanged)
  }
}

class RustDailyParams { ... }  // unchanged
```

具体步骤：
1. 将 `hooks_riverpod` import 改为 `riverpod_annotation` import
2. 添加 `part 'rust_daily_provider.g.dart';`
3. 将 `final rustDailyProvider = FutureProvider.family<...>` 改为 `@riverpod class RustDaily extends _$RustDaily`
4. 原回调函数体原封不动移入 `build(RustDailyParams params)` 方法
5. `RustDailyParams` 类保持不变

### 生成代码

执行 `dart run build_runner build --delete-conflicting-outputs` 生成 `rust_daily_provider.g.dart`。

### 无需修改的文件

- `lib/presentation/pages/rust_daily/rust_daily_list_tab.dart` — `ref.watch(rustDailyProvider(params))`、`ref.invalidate(...)`、`ref.listen(...)` 等 API 与 `AsyncNotifierProvider.family` 完全兼容
- `lib/presentation/pages/rust_daily/rust_daily_detail_page.dart` — 同上

## 验证

1. `dart run build_runner build --delete-conflicting-outputs` 生成成功，无报错
2. `flutter analyze` 无新增错误
3. 生成的 `.g.dart` 文件中的 provider 名为 `rustDailyProvider`（与旧名一致，全局替换无需改动）
