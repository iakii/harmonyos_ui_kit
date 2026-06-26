# js_intro 页面 UI 美化计划

## 背景

美化 `lib/presentation/pages/js_gallery/intro/js_intro.dart`（漫画简介页面），遵循 HarmonyOS UI 设计规范，与项目中已有的 `detail_page.dart` 和 `grid_item_card.dart` 保持风格一致。

**范围**：仅修改 `js_intro.dart` 一个文件，不改变 provider 数据结构，不改动路由和行为逻辑。

---

## 当前问题

1. 封面图全宽无约束，可能过矮或过高，与页面无缝衔接
2. 信息卡片（作者/分类/状态）使用 Flutter 原生 `Divider`，无图标，缺少视觉层次
3. 标签 chips 未设置 `fontFamily: "HarmonyOs Sans SC"`
4. 简介区为纯文本，缺卡片包裹和展开/收起
5. 章节列表无序号，标题字体未统一
6. 整体间距不统一（8/12/16/24 混用）

---

## 美化计划（5 个步骤）

### 步骤 1：封面区域美化

- 将 `ExtendedImage.network` 包裹在 `SizedBox(height: 240)` 内，使用 `BoxFit.cover` 裁剪
- 用 `Stack` + `Positioned` 在封面底部叠加渐变遮罩（从透明渐变到 `theme.scaffoldBackgroundColor`），平滑过渡到页面背景
- 应用 `ClipRRect(BorderRadius.vertical(top: Radius.circular(12)))` 使顶部圆角与 HosCard 风格统一

### 步骤 2：信息卡片增强

- 替换 Flutter 原生 `Divider` 为 `HosDivider()`
- 为每行（作者/分类/状态）添加前置图标：
  - 作者 → `Icons.person_outline`
  - 分类 → `Icons.category_outlined`
  - 状态 → `Icons.info_outline`
- 状态值添加颜色指示圆点（6px）：
  - "完结"/"已完成" → `theme.colorTokens.statusSuccess`（绿色）
  - "连载"/"连载中" → `theme.colorTokens.statusInfo`（蓝色）
- HosCard 使用默认 padding（去掉 `vertical: 0`）

### 步骤 3：简介卡片改造

- 将简介整体用 `HosCard` 包裹，标题 "简介" 作为 card 内 header
- 添加展开/收起功能：默认 `maxLines: 3`，文字溢出时显示 "展开" / "收起" 按钮
- 正文字体：`theme.typography.body?.copyWith(height: 1.6)`

### 步骤 4：章节列表增强

- 为每个章节项添加序号 leading（圆形徽章，accent 色背景 + 数字）
- 添加排序提示（可选项）：最新一章标记 "最新" subtitle
- 章节标题字体设为 `fontFamily: "HarmonyOs Sans SC"`
- 章节区域头部改为左右布局（左侧 "章节列表" 标题 + 右侧 "共 N 话" 计数）

### 步骤 5：整体打磨

- 标签 chips 添加 `fontFamily: "HarmonyOs Sans SC"`
- 标题使用 `theme.typography.title1`（20px w600）替代当前的 `title2` + bold
- 标题添加 `fontFamily: "HarmonyOs Sans SC"`
- 统一各区域间距为 8px 网格系统：
  - 标题 → 信息卡：16px
  - 信息卡 → 标签：16px
  - 标签 → 简介：16px
  - 简介 → 章节：24px

---

## 涉及文件

| 文件 | 改动 |
|---|---|
| `lib/presentation/pages/js_gallery/intro/js_intro.dart` | 唯一修改文件，覆盖以上 5 个步骤 |

---

## 不修改

- `intro_provider.dart` / `intro_provider.g.dart` — 数据结构不变
- `detail_item.dart` — 实体不变
- `router.dart` — 路由不变
- 所有行为逻辑（点击跳转、数据加载等）保持不变

---

## 验证方法

1. 运行 `flutter analyze` 确保无静态分析错误
2. 运行应用，进入漫画简介页面验证：
   - 封面图 + 渐变遮罩显示正常
   - 信息卡片图标、颜色圆点显示正确
   - 简介展开/收起功能正常
   - 章节列表序号徽章显示
   - 标签点击跳转正常
   - 切换亮色/暗色主题验证颜色自适应
