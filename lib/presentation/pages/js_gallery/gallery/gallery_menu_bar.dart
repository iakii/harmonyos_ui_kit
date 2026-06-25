import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:rohos_app/domain/entities/menu_item.dart';

/// 菜单 TabBar 组件。
///
/// 纯展示组件，不关心数据来源，通过 [onChanged] 回传选中索引。
class GalleryMenuBar extends StatelessWidget {
  const GalleryMenuBar({
    super.key,
    required this.menus,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<MenuItem> menus;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return HosTabBar(
      tabs: menus.map((m) => m.label).toList(),
      selectedIndex: selectedIndex,
      onChanged: onChanged,
    );
  }
}
