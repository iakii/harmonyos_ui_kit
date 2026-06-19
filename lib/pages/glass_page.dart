// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:rohos_app/pages/bottom_bar.dart';

/// 鸿蒙风格胶囊 TabBar。
class HarmonyTabBar extends StatelessWidget {
  const HarmonyTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E0033), Color(0xFF330066)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: Colors.purple.withOpacity(0.4), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: TabBar(
            tabs: const [
              Tab(text: '发现'),
              Tab(text: '我的歌单'),
              Tab(text: '下载'),
            ],
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.2),
            ),
            labelStyle: const TextStyle(
              fontFamily: 'HarmonyOS Sans',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// 液态玻璃效果页面 —— 展示自定义底部导航栏和毛玻璃 TabBar。
///
/// 从 [HookWidget] 迁移到 [HookConsumerWidget]，支持访问 Riverpod providers。
class GlassPage extends HookConsumerWidget {
  const GlassPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(0);
    final fake = useState(false);

    return HosPage(
      showAppBar: false,
      backgroundColor: Colors.blue,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const DefaultTabController(length: 3, child: HarmonyTabBar()),

          const Text('This is the Glass Page'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),

          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: LiquidGlassBottomBar(
                fake: fake.value,
                extraButton: LiquidGlassBottomBarExtraButton(
                  icon: CupertinoIcons.add_circled,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => const CupertinoPageScaffold(
                          navigationBar: CupertinoNavigationBar.large(),
                          child: SizedBox(),
                        ),
                      ),
                    );
                  },
                  label: '',
                ),
                tabs: const [
                  LiquidGlassBottomBarTab(
                    label: 'Home',
                    icon: CupertinoIcons.home,
                  ),
                  LiquidGlassBottomBarTab(
                    label: 'Profile',
                    icon: CupertinoIcons.person,
                  ),
                  LiquidGlassBottomBarTab(
                    label: 'Settings',
                    icon: CupertinoIcons.settings,
                  ),
                ],
                selectedIndex: tab.value,
                onTabSelected: (index) {
                  tab.value = index;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
