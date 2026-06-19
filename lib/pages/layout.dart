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
  bool _isImmersive = false;
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
      // backgroundColor: HarmonyTheme.of(context).surfaceColor,
      bottomBar: HosBottomNavigation(
        floating: _isImmersive,
        // immersive: false,
        items: [
          HosBottomNavItem(icon: HMIcons.harmonyos, label: '鸿蒙'),
          HosBottomNavItem(icon: HMIcons.house, label: 'JS脚本'),
          HosBottomNavItem(icon: HMIcons.share, label: '玻璃套件'),
          // HosBottomNavItem(icon: HMIcons.a10kRectangle, label: '沉浸式'),
          HosBottomNavItem(icon: HMIcons.glass, label: '毛玻璃'),
        ],
        selectedIndex: _selectedIndex,
        onChanged: (i) {
          setState(() {
            _selectedIndex = i;
          });

          if (i == 1) {
            showHosBottomSheet(
              context: context,
              builder: (context) => SizedBox(
                height: 800,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Bottom sheet content'),
                ),
              ),
            );
          }

          final route = [
            '/',
            '/js_parse',
            '/glass_kit',
            // '/immersive',
            '/glass',
          ][i];
          if (ModalRoute.of(context)?.settings.name != route) {
            context.go(route);
          }
        },
      ),
      // bottomBar: HarmonyImmersiveGlowNavigationBar(
      //   currentIndex: _selectedIndex,
      //   height: 56,
      //   onTap: (value) {
      //     setState(() => _selectedIndex = value);

      //     final route = [
      //       '/',
      //       '/js_parse',
      //       '/glass_kit',
      //       '/immersive',
      //       '/glass',
      //     ][value];
      //     if (ModalRoute.of(context)?.settings.name != route) {
      //       context.go(route);
      //     }
      //   },
      //   materialLevel: HarmonyGlowMaterialLevel.adaptive,
      //   // effectTuning: const HarmonyGlowEffectTuning(
      //   //   glowScale: .9,
      //   //   blurScale: .2,
      //   //   surfaceScale: .2,
      //   //   elasticScale: .8,
      //   //   scatterScale: .35,
      //   // ),
      //   items: const <HarmonyGlowNavigationItem>[
      //     HarmonyGlowNavigationItem(
      //       icon: Icon(Icons.home_outlined),
      //       activeIcon: Icon(Icons.home_rounded),
      //       label: '推荐',
      //     ),
      //     HarmonyGlowNavigationItem(
      //       icon: Icon(Icons.category_outlined),
      //       activeIcon: Icon(Icons.category_rounded),
      //       label: '分类',
      //     ),
      //     // HarmonyGlowNavigationItem(
      //     //   icon: Icon(Icons.apps_outlined),
      //     //   activeIcon: Icon(Icons.apps_rounded),
      //     //   label: '甄选馆',
      //     // ),
      //     // HarmonyGlowNavigationItem(
      //     //   icon: Icon(Icons.account_circle_outlined),
      //     //   activeIcon: Icon(Icons.account_circle_rounded),
      //     //   label: '我的',
      //     // ),
      //   ],
      // ),
    );
  }
}
