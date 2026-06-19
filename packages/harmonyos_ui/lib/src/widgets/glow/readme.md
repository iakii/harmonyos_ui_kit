# HarmonyImmersiveGlow — HDS 沉浸式发光系统

仿 HarmonyOS NEXT Design System 的沉浸式发光效果组件库。提供半透明毛玻璃材质面板和带弹簧物理交互的底部导航栏。

## 组件总览

| 组件 | 说明 |
|------|------|
| `HarmonyGlowMaterial` | 可复用的半透明发光材质面板 |
| `HarmonyImmersiveGlowNavigationBar` | 带沉浸式光效的浮动底部导航栏 |
| `HarmonyGlowMaterialLevel` | 材质质量等级枚举（4 档） |
| `HarmonyGlowEffectTuning` | 7 维效果微调器 |
| `HarmonyGlowPalette` | 6 组颜色的调色板配置 |
| `HarmonyGlowNavigationItem` | 导航项数据模型 |
| `harmonyGlowLevelForCapability()` | 设备能力 → 材质等级映射函数 |

## 视觉效果

### HarmonyGlowMaterial 的渲染层级（从底到顶）

```
┌──────────────────────────────────────┐
│  ⑤ 顶部装饰线（中间亮两端透明）       │
│  ④ 边缘描边（上亮下暗 1.1px）        │
│  ③ 镜面高光（横向扫过的白色椭圆）     │
│  ② 彩色光池（3 个径向渐变绕中心旋转） │
│  ① 表面填充（半透明基底色）           │
│  ⓪ 背景模糊（BackdropFilter 高斯模糊）│
│  ── 下方内容 ──                      │
└──────────────────────────────────────┘
```

## 快速开始

### 安装

```dart
import 'package:harmonyos_ui/harmonyos_ui.dart';
```

### 基础用法 — 发光材质面板

```dart
// 在图片/彩色背景上放置半透明发光面板
Stack(
  children: [
    // 下方的内容（图片、渐变背景等）
    Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
    ),
    // 发光材质面板
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: HarmonyGlowMaterial(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        materialLevel: HarmonyGlowMaterialLevel.gentle,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('毛玻璃面板内容'),
        ),
      ),
    ),
  ],
)
```

### 基础用法 — 沉浸式底部导航栏

```dart
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(),
          SearchPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: HarmonyImmersiveGlowNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: '搜索',
          ),
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
```

---

## API 参考

### HarmonyGlowMaterial

半透明发光材质面板。放在彩色或图片内容之上，自动采样背景并通过高斯模糊 + 多层光效绘制沉浸式毛玻璃效果。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `child` | `Widget` | **必填** | 材质面板内的子组件 |
| `borderRadius` | `BorderRadius` | `circular(28)` | 面板圆角 |
| `palette` | `HarmonyGlowPalette` | `HarmonyGlowPalette()` | 颜色配方 |
| `materialLevel` | `HarmonyGlowMaterialLevel` | `adaptive` | 材质等级 |
| `effectTuning` | `HarmonyGlowEffectTuning` | `HarmonyGlowEffectTuning()` | 效果微调 |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.zero` | 内边距 |
| `glowAlignment` | `Alignment` | `Alignment.center` | 最亮光池的中心位置 |
| `animationValue` | `double` | `0` | 归一化动画值 [0,1]，驱动光池旋转和高光位移 |

**光池位置说明**：`glowAlignment` 使用 Alignment 坐标系：
- `Alignment(-1, -1)` — 左上角
- `Alignment(0, 0)` — 中心
- `Alignment(1, 1)` — 右下角

### HarmonyImmersiveGlowNavigationBar

带沉浸式发光效果的浮动底部导航栏。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `items` | `List<HarmonyGlowNavigationItem>` | **必填** | 导航项（≥2 个） |
| `currentIndex` | `int` | **必填** | 当前选中索引 |
| `onTap` | `ValueChanged<int>` | **必填** | 点击回调 |
| `palette` | `HarmonyGlowPalette` | `HarmonyGlowPalette()` | 颜色配方 |
| `materialLevel` | `HarmonyGlowMaterialLevel` | `adaptive` | 材质等级 |
| `effectTuning` | `HarmonyGlowEffectTuning` | `HarmonyGlowEffectTuning()` | 效果微调 |
| `height` | `double` | `72` | 导航栏高度 |
| `widthFactor` | `double?` | `0.86` | 宽度因子（占父容器比例），null 则填满 |
| `margin` | `EdgeInsetsGeometry` | `LTRB(16,0,16,28)` | 外边距 |
| `borderRadius` | `BorderRadius` | `circular(32)` | 圆角半径 |
| `iconSize` | `double` | `28` | 图标尺寸 |
| `labelStyle` | `TextStyle?` | `null` | 标签文字样式 |
| `showLabels` | `bool` | `true` | 是否显示文字标签 |
| `includeBottomSafeArea` | `bool` | `true` | 是否包含底部安全区 |
| `enableInteractionEffect` | `bool` | `true` | 是否启用手势交互效果 |
| `interactionFadeDuration` | `Duration` | `260ms` | 交互光效过渡时长 |
| `animationDuration` | `Duration` | `360ms` | 索引切换动画时长 |
| `curve` | `Curve` | `easeOutCubic` | 切换动画曲线 |

### HarmonyGlowMaterialLevel

材质等级枚举，控制渲染质量和性能。

| 值 | 说明 | 模糊半径 | 适用场景 |
|----|------|----------|----------|
| `adaptive` | 自适应 | 运行时决定 | 默认值，根据设备自动选择 |
| `exquisite` | 精致 | 34px | 高端设备，最强效果 |
| `gentle` | 柔和 | 22px | 中等设备，平衡效果 |
| `smooth` | 流畅 | 8px | 低端设备/省电模式 |

**自适应规则**：`adaptive` 在动画禁用时降级为 `smooth`，否则使用 `gentle`。

### HarmonyGlowEffectTuning

微调 7 个视觉维度，所有乘数默认 `1.0`，设为 `0` 可完全禁用该效果。

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `blurScale` | `1` | 背景模糊强度 |
| `surfaceScale` | `1` | 表面填充不透明度 |
| `glowScale` | `1` | 光池（彩色径向渐变）亮度 |
| `shadowScale` | `1` | 投影深度 |
| `specularScale` | `1` | 镜面高光（白色椭圆扫描）强度 |
| `elasticScale` | `1` | 弹性形变幅度（仅导航栏） |
| `scatterScale` | `0` | 散射光幕强度（默认关闭，性能开销较大） |

```dart
// 示例：增强发光、减弱模糊、开启散射
HarmonyGlowEffectTuning(
  blurScale: 0.6,
  glowScale: 1.5,
  specularScale: 1.2,
  scatterScale: 0.8,
)
```

### HarmonyGlowPalette

颜色配方，一次定义全局复用。

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `surfaceTint` | `Color` | `Colors.white` | 材质面板基底色 |
| `edgeHighlight` | `Color` | `0xE6FFFFFF` | 上/外边缘亮色描边 |
| `edgeShadow` | `Color` | `0x24000000` | 下边缘暗色 + 投影 |
| `activeColor` | `Color` | `0xFF1476FF` | 选中图标/文字色 |
| `inactiveColor` | `Color` | `0xFF15171A` | 未选中图标/文字色 |
| `glowColors` | `List<Color>` | 青绿+蓝紫+暖橙 | 背景光池颜色列表 |

```dart
// 示例：暗色模式调色板
const darkPalette = HarmonyGlowPalette(
  surfaceTint: Color(0x4D000000),      // 深色半透明基底
  edgeHighlight: Color(0x1AFFFFFF),    // 微弱亮边
  edgeShadow: Color(0x33000000),       // 暗色投影
  activeColor: Color(0xFF4DA6FF),      // 亮蓝选中
  inactiveColor: Color(0xFFCCCCCC),    // 浅灰未选中
  glowColors: [
    Color(0xFF6366F1),  // 靛蓝
    Color(0xFF8B5CF6),  // 紫色
  ],
);
```

### harmonyGlowLevelForCapability()

根据设备能力选择合适的材质等级。

```dart
// 典型用法：从平台通道获取设备能力后映射
final bool supportsImmersive = await platformChannel.getCapability();
final level = harmonyGlowLevelForCapability(
  supportsImmersiveMaterial: supportsImmersive,
  preferExquisite: true,  // 偏好精致效果
);
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `supportsImmersiveMaterial` | `bool` | 宿主是否支持沉浸式材质 |
| `preferExquisite` | `bool` | 支持时是否偏好精致等级（默认 true） |

---

## 进阶用法

### 自定义光池颜色

```dart
HarmonyGlowMaterial(
  palette: const HarmonyGlowPalette(
    glowColors: [
      Color(0xFFFF6B6B),  // 红色光池
      Color(0xFFFFD93D),  // 黄色光池
      Color(0xFF6BCB77),  // 绿色光池
    ],
  ),
  child: /* ... */,
)
```

### 光池跟随滚动位置

```dart
final scrollController = ScrollController();
double animationValue = 0;

// 监听滚动偏移，映射到 [0, 1]
scrollController.addListener(() {
  final maxScroll = scrollController.position.maxScrollExtent;
  if (maxScroll > 0) {
    setState(() {
      animationValue = (scrollController.offset / maxScroll).clamp(0.0, 1.0);
    });
  }
});

HarmonyGlowMaterial(
  animationValue: animationValue,   // 光池和高光随滚动移动
  glowAlignment: Alignment.topCenter,
  child: /* ... */,
)
```

### 禁用交互动效（省电模式）

```dart
HarmonyImmersiveGlowNavigationBar(
  enableInteractionEffect: false,  // 关闭按压光效和弹性形变
  materialLevel: HarmonyGlowMaterialLevel.smooth,  // 最轻量材质
  effectTuning: HarmonyGlowEffectTuning(
    scatterScale: 0,     // 关闭散射层
    glowScale: 0.5,      // 减弱光池
    elasticScale: 0,     // 关闭弹性
  ),
  /* ... */
)
```

### 禁用动画时的自适应降级

当用户在系统设置中开启"减少动画"时，`adaptive` 等级自动降级为 `smooth`。无需手动处理：

```dart
// materialLevel: HarmonyGlowMaterialLevel.adaptive
// → 系统开启动画减弱时自动使用 smooth
// → 系统正常时使用 gentle
```

### 暗色模式自动适配

```dart
MaterialApp(
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,
  home: Builder(
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return HarmonyImmersiveGlowNavigationBar(
        palette: isDark ? darkPalette : lightPalette,
        /* ... */
      );
    },
  ),
)
```

---

## 性能指南

### 各材质等级的 GPU 开销

| 等级 | 模糊 radius | 散射层 | 相对开销 | 推荐设备 |
|------|------------|--------|----------|----------|
| `smooth` | 8px | 禁用 | ★☆☆☆☆ | 低端/旧设备 |
| `gentle` | 22px | 启用 (.9) | ★★★☆☆ | 中端设备 |
| `exquisite` | 34px | 启用 (.48) | ★★★★★ | 高端/新设备 |

### 优化建议

1. **默认关闭散射层**：`scatterScale` 默认为 `0`，因为它涉及多层 BackdropFilter，GPU 开销显著
2. **使用 `smooth` 等级**：在列表滚动、页面转场等高频重绘场景
3. **按需启用交互效果**：`enableInteractionEffect: false` 可减少每帧的弹簧物理计算
4. **自适应降级**：使用 `adaptive` 等级让组件在动画禁用时自动降级

---

## 交互状态机

导航栏的手势交互有以下状态：

```
        手指按下
    ┌──────────────►  按压态
    │                 - 光斑亮起（fade in 260ms）
    │                 - 弹簧物理启动
    │                 - 弹性形变（点击拉伸）
    │                    │
    │                    │ 拖拽 > 8px
    │                    ▼
    │                 拖拽态
    │                 - 光斑跟随手指
    │                 - 按压项清除
    │                 - 弹性形变（拖拽+边缘）
    │                    │
    │     手指抬起/取消  │  手指抬起/取消
    │◄───────────────────┘◄──────────────────
    ▼
   释放态
    - 光斑熄灭（fade out 260ms）
    - 弹簧回弹到零
    - 静止后停止 ticker
```

---

## 技术细节

### 弹簧物理模型

导航栏使用阻尼谐振子（damped harmonic oscillator）模拟交互形变：

```
加速度 = (目标位置 - 当前位置) × 刚度
新速度 = (当前速度 + 加速度 × dt) × e^(-阻尼 × dt)
新位置 = 当前位置 + 新速度 × dt
```

- **刚度** = 68 + elasticScale × 24
- **阻尼** = 14 + (1 - elasticScale) × 4

当位移 < 0.003px 且速度 < 0.01px/frame 时自动停止 ticker 以节省 CPU。

### 混合模式说明

| 混合模式 | 用途 | 效果 |
|----------|------|------|
| `BlendMode.plus` | 彩色光池 | 叠加增色，颜色加深 |
| `BlendMode.screen` | 镜面高光/散射光幕/弹性拖尾 | 只增亮不增暗，模拟光照 |

### 文件结构

```
harmony_immersive_glow.dart
├── enum HarmonyGlowMaterialLevel       # 材质等级枚举
├── class HarmonyGlowEffectTuning       # 效果微调器
├── function harmonyGlowLevelForCapability()  # 能力→等级映射
├── extension on HarmonyGlowMaterialLevel     # 等级参数+运行时解析
├── class HarmonyGlowPalette            # 调色板
├── class HarmonyGlowNavigationItem     # 导航项数据
├── class HarmonyGlowMaterial           # ★ 核心发光材质
├── class _HarmonyBackdropScatter       # 散射光幕（私有）
├── class _FilteredBackdrop             # 模糊+颜色叠加（私有）
├── class _ScatterVeilPainter           # 光幕画笔（私有）
├── class HarmonyImmersiveGlowNavigationBar      # ★ 导航栏
├── class _HarmonyImmersiveGlowNavigationBarState # 导航栏状态
├── class _NavigationButton             # 导航按钮（私有）
├── class _HarmonyGlowMaterialPainter   # 材质效果画笔（私有）
└── class _NavigationGlowPainter        # 导航交互光效画笔（私有）
```

---

## 与 HarmonyOS 原生的关系

本组件是 HarmonyOS NEXT 沉浸式材质的 **Flutter 纯原生实现**，不依赖 HarmonyOS 系统 API。

- **参考对象**：ArkUI 的 `immersive` 材质类型 + `getSystemMaterialTypes()`
- **实现方式**：Flutter 的 `BackdropFilter` + `CustomPainter` + `dart:ui` ImageFilter
- **兼容性**：跨平台可用（Android / iOS / Windows / Linux / macOS / Web），在非 HarmonyOS 平台上视觉效果一致

`harmonyGlowLevelForCapability()` 函数用于桥接：应用通过平台通道查询宿主能力后，将结果映射为 Flutter 端可用的材质等级。

---

## 环境要求

- Flutter SDK `>=1.17.0`
- Dart SDK `^3.9.2`
- 平台至少支持 `BackdropFilter`（ImageFilter.blur），所有 Flutter 目标平台均满足
