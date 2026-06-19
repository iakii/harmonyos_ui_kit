import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';

class ImmersivePage extends StatefulWidget {
  const ImmersivePage({super.key});

  @override
  State<ImmersivePage> createState() => _ImmersivePageState();
}

class _ImmersivePageState extends State<ImmersivePage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // showAppBar: false,
      appBar: HosAppBar(
        title: ('Immersive Page'),
        immersive: true,
        leading: Icon(HMIcons.harmonyosNext),
      ),
      // backgroundColor: Colors.yellow,
      // showAppBar: false,
      body: ListView(
        children: [
          Image.network(
            'https://cdn.pixabay.com/photo/2026/06/08/10/34/10-34-35-885_1280.jpg',
          ),
          // 在图片/彩色背景上放置半透明发光面板
          Stack(
            children: [
              // 下方的内容（图片、渐变背景等）
              Container(
                height: 600,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
              ),
              HarmonyGlowMaterial(
                materialLevel: HarmonyGlowMaterialLevel.gentle,
                effectTuning: const HarmonyGlowEffectTuning(scatterScale: 1.15),
                borderRadius: BorderRadius.circular(32),
                child: const SizedBox(width: 320, height: 72),
              ),
              // 发光材质面板
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: HarmonyGlowMaterial(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                  materialLevel: HarmonyGlowMaterialLevel.gentle,
                  child: Padding(
                    padding: EdgeInsets.all(100),
                    child: Text('毛玻璃面板内容'),
                  ),
                ),
              ),

              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: HarmonyImmersiveGlowNavigationBar(
                  palette: HarmonyGlowPalette.dark(),
                  currentIndex: index,
                  height: 56,
                  onTap: (value) => setState(() => index = value),
                  materialLevel: HarmonyGlowMaterialLevel.adaptive,
                  effectTuning: const HarmonyGlowEffectTuning(
                    glowScale: .9,
                    blurScale: .2,
                    surfaceScale: .2,
                    elasticScale: .8,
                    scatterScale: .35,
                  ),
                  items: const <HarmonyGlowNavigationItem>[
                    HarmonyGlowNavigationItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home_rounded),
                      label: '推荐',
                    ),
                    HarmonyGlowNavigationItem(
                      icon: Icon(Icons.category_outlined),
                      activeIcon: Icon(Icons.category_rounded),
                      label: '分类',
                    ),
                    HarmonyGlowNavigationItem(
                      icon: Icon(Icons.apps_outlined),
                      activeIcon: Icon(Icons.apps_rounded),
                      label: '甄选馆',
                    ),
                    HarmonyGlowNavigationItem(
                      icon: Icon(Icons.account_circle_outlined),
                      activeIcon: Icon(Icons.account_circle_rounded),
                      label: '我的',
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            height: 200,
            color: Colors.red,
            child: const Center(child: Text('Immersive Glow Effect')),
          ),
          Container(
            height: 200,
            color: Colors.green,
            child: const Center(child: Text('Immersive Glow Effect')),
          ),
          Container(
            height: 200,
            color: Colors.blue,
            child: const Center(child: Text('Immersive Glow Effect')),
          ),
          Image.network(
            'https://cdn.pixabay.com/photo/2026/06/08/10/34/10-34-35-885_1280.jpg',
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(80)),
      //   child: const Icon(Icons.add),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: HarmonyImmersiveGlowNavigationBar(
        currentIndex: index,
        height: 56,
        iconSize: 24,
        // showLabels: false,
        onTap: (value) => setState(() => index = value),
        materialLevel: HarmonyGlowMaterialLevel.gentle,
        // effectTuning: const HarmonyGlowEffectTuning(
        //   glowScale: .9,
        //   blurScale: .2,
        //   surfaceScale: .2,
        //   elasticScale: .8,
        //   scatterScale: .35,
        // ),
        items: const <HarmonyGlowNavigationItem>[
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: '推荐',
          ),
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category_rounded),
            label: '分类',
          ),
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.apps_outlined),
            activeIcon: Icon(Icons.apps_rounded),
            label: '甄选馆',
          ),
          HarmonyGlowNavigationItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
