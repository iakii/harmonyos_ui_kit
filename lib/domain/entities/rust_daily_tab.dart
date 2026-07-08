import 'package:flutter/material.dart';
import 'package:hm_icon/hm_icon.dart';

/// Rust Daily Tab 数据模型。
///
/// 每个 tab 包含展示标签、请求 URL、唯一标识 key 和可选图标。
class RustDailyTab {
  /// 展示标签。
  final String label;

  /// 请求 URL。
  final String url;

  /// 唯一标识 key，用于 Widget 和状态管理。
  final String key;

  /// Tab 图标。
  final IconData? icon;

  const RustDailyTab({
    required this.label,
    required this.url,
    required this.key,
    this.icon,
  });

  /// 默认的列表 Tab 列表。
  ///
  /// [defaultUrl] 为外部传入的日报 URL（为空时使用内置默认值）。
  static List<RustDailyTab> defaultListTabs({String? defaultUrl}) {
    return [
      const RustDailyTab(
        label: '综合',
        url: 'https://rustcc.cn/latest_articles_paging',
        key: 'comprehensive',
        icon: HMIcons.rectangleStack,
      ),
      RustDailyTab(
        label: '日报',
        url:
            defaultUrl ??
            'https://rustcc.cn/section?id=f4703117-7e6b-4caf-aa22-a3ad3db6898f',
        key: 'daily',
        icon: HMIcons.calendarFill,
      ),
      const RustDailyTab(
        label: '最新回复',
        url: 'https://rustcc.cn/latest_reply_articles_paging',
        key: 'latest_reply',
        icon: HMIcons.messageFill,
      ),
    ];
  }
}
