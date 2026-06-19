---
name: generate-hmicon
description: |
  从 HMSymbolVF.ttf 字体文件自动生成 Flutter HMIcon 包。
  解析 TrueType 字体的 cmap/post 表，提取所有 glyph 的 Unicode 码位和名称，
  生成包含全部图标的 Dart 常量类。适用于字体更新后重新生成图标代码。
---

# generate-hmicon — 从 HMSymbolVF.ttf 生成 HMIcon Flutter 包

## 概述

此 skill 用于从 HarmonyOS NEXT Symbol 变量字体（HMSymbolVF.ttf）自动生成 `hm_icon` Flutter package。生成器是一个纯 Dart 脚本，不依赖任何第三方库，直接解析 TrueType 二进制格式。

## 文件位置

```
third_library/hm_icon/
├── pubspec.yaml                    # 包配置，注册 HMSymbolVF 字体
├── README.md
├── fonts/
│   └── HMSymbolVF.ttf              # 可变字体源文件（~4MB，18 个表）
├── lib/
│   ├── hm_icon.dart                # barrel export（library; + export）
│   └── src/
│       └── hm_icon_data.dart       # 自动生成的图标常量类（~14000 行）
└── tool/
    └── generate_hm_icon.dart       # 字体解析 & 代码生成脚本
```

## 执行方式

### 重新生成图标代码

```bash
cd third_library/hm_icon/tool
dart run generate_hm_icon.dart
```

### 生成后验证

```bash
cd third_library/hm_icon
flutter pub get
flutter analyze
```

## 数据规模

| 项目 | 值 |
|------|-----|
| 图标总数 | ~4664 个 |
| 码位范围 | U+0020 ~ U+F126D（主要在 Private Use Area） |
| 码位分块 | 17 个块，每块 ~250 个图标 |
| 生成文件行数 | ~14000 行 |
| 字体表数 | 18 个（DSIG, GDEF, GSUB, OS/2, STAT, cmap, fvar, glyf, gvar, head, hhea, hmtx, loca, maxp, name, post, vhea, vmtx） |

## 工作原理

### 步骤 1：解析 TTF 表目录
读取字体文件头部 Offset Table（sfVersion, numTables），然后逐个读取 TableRecord（tag, checkSum, offset, length）。

### 步骤 2：解析 cmap 表
cmap 表将 Unicode 码位映射到 glyph index：
- 遍历所有 cmap 子表，优先选择 format 12（全 Unicode 支持），其次 format 4（BMP）
- Format 12 使用顺序分组映射（startCharCode, endCharCode, startGlyphID）
- 展开所有分组，得到完整的 `code -> glyphIndex` 映射

### 步骤 3：解析 post 表
post 表存储 glyph 名称：
- 只处理 Version 2.0（有名称存储）
- 读取 glyph 名称索引数组（uint16 序列）
- 索引 0-257 对应 Macintosh 标准 glyph 名称（如 `space`, `heart`, `arrow_right`）
- 索引 ≥258 对应 Pascal 字符串（1 字节长度 + 字符数据）
- 按顺序扫描字符串池定位每个名称

### 步骤 4：Glyph 名称 → Dart 变量名
转换规则：
1. 将 `.` `-` ` ` 替换为 `_`
2. 按下划线分割成词，首个词全小写，后续词首字母大写（camelCase）
3. Dart 关键字冲突时追加 `_`
4. 大写字母开头或数字开口时自动修正

### 步骤 5：生成 Dart 代码
- 生成 `HMIcons` 类，包含 `const HMIcons._()` 私有构造函数
- 每个图标一个 `static const` 字段：`IconData(0xF0000, fontFamily: fontFamily)`
- 包含 dartdoc 注释（glyph 名 + Unicode 码位）
- 添加 `// ignore_for_file` 指令忽略常量命名和文档注释 lint

### 步骤 6：生成 Barrel 文件
- `library;` 匿名库声明（包含包文档注释）
- `export 'src/hm_icon_data.dart'`

## 包结构设计

### pubspec.yaml 字体注册
```yaml
flutter:
  fonts:
    - family: HMSymbolVF
      fonts:
        - asset: fonts/HMSymbolVF.ttf
```

### 类设计要点
- 类名 `HMIcons`，配合 `const HMIcons._()` 防止实例化
- 所有图标使用 `static const` 声明，编译时确定
- `fontFamily` 提取为单独的 `static const String`，统一引用

## 命名规则速查

| 后缀 | 含义 | 示例 |
|------|------|------|
| `*Fill` | 填充样式 | `starFill`, `heartFill` |
| `*Slash` | 斜线/禁用 | `heartSlash` |
| `*Circle` | 圆形变体 | `checkmarkCircle`, `minusCircle` |
| `*CircleFill` | 圆形填充 | `checkmarkCircleFill` |
| `*Mirroring` | 镜像变体 | `isoDocMirroring` |

## 注意事项

- 跳过 C0/C1 控制字符范围（U+0000-U+001F, U+0080-U+009F）
- 跳过 `.notdef`, `.null`, `nonmarkingreturn` 等非图标 glyph
- 处理 glyph 名称重复（追加 `_2`, `_3` 后缀）
- 生成脚本**不依赖任何第三方包**，可在裸 Dart 环境运行
- 生成代码输出到 `hm_icon/lib/` 目录，覆盖已有文件
