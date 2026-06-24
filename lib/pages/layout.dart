import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key, required this.child});

  final Widget child;

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _selectedIndex = 0;
  bool _isImmersive = true;
  @override
  Widget build(BuildContext context) {
    return HosPage(
      showAppBar: true,
      title: 'HarmonyOS UI',
      leading: Icon(HMIcons.harmonyos),
      actions: [
        IconButton(
          icon: Icon(HMIcons.more),
          tooltip: '图标预览',
          onPressed: () => context.go('/icons'),
        ),
        IconButton(
          icon: Icon(HMIcons.switchCamera),
          tooltip: '切换相机',
          onPressed: () {
            setState(() {
              _isImmersive = !_isImmersive;
            });
            // Handle search action
          },
        ),
      ],
      body: widget.child,
      bottomBar: HosBottomNavigation(
        floating: _isImmersive,
        // immersive: false,
        items: [
          HosBottomNavItem(icon: HMIcons.harmonyos, label: '鸿蒙'),
          HosBottomNavItem(icon: HMIcons.house, label: 'JS脚本'),
          HosBottomNavItem(icon: HMIcons.newMovie, label: 'Rust Daily'),
          HosBottomNavItem(icon: HMIcons.galleryOrg, label: '图集'),
          HosBottomNavItem(icon: HMIcons.dynamicShakeShot, label: '动态'),
        ],
        selectedIndex: _selectedIndex,
        onChanged: (i) {
          setState(() {
            _selectedIndex = i;
          });

          final route = ['/', '/js_parse', '/rust', '/js_gallery', '/webF'][i];
          if (ModalRoute.of(context)?.settings.name != route) {
            context.go(route);
          }
        },
      ),
    );
  }
}
