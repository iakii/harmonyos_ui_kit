import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';

class WebFPage extends StatefulWidget {
  const WebFPage({super.key});

  @override
  State<WebFPage> createState() => _WebFPageState();
}

class _WebFPageState extends State<WebFPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return HosPage(
      title: 'WebF Page',
      showAppBar: true,
      body: ScrollConfiguration(
        behavior: CustomScrollBehaviour(),
        child: SingleChildScrollView(
          controller: _controller,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: HtmlWidget(
              kHtml,
              customWidgetBuilder: (e) {
                if (!e.classes.contains('carousel')) {
                  return null;
                }

                final srcs = <String>[];
                for (final child in e.children) {
                  for (final grandChild in child.children) {
                    if (grandChild.attributes case {'src': final String src}) {
                      srcs.add(src);
                    }
                  }
                }

                return CarouselSlider(
                  options: CarouselOptions(
                    autoPlay: true,
                    autoPlayAnimationDuration: const Duration(
                      milliseconds: 500,
                    ),
                    autoPlayInterval: const Duration(seconds: 2),
                    enlargeCenterPage: true,
                  ),
                  items: srcs.map(_toItem).toList(growable: false),
                );
              },
              onTapImage: (src) {
                print('onTapImage: ${src.sources}');
              },
            ),
          ),
        ),
      ),
    );
  }

  static Widget _toItem(String src) =>
      Center(child: Image.network(src, fit: BoxFit.cover, width: 1000));
}

class CustomScrollBehaviour extends MaterialScrollBehavior {
  const CustomScrollBehaviour();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.ohos:
        return Scrollbar(
          controller: details.controller,
          radius: Radius.zero,
          thickness: 0,
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    // PointerDeviceKind.invertedStylus,
    // PointerDeviceKind.stylus,
  };
}

const kHtml = '''
<h1>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam ac metus urna. Proin mollis dictum faucibus. Sed tellus leo, aliquam nec gravida sit amet, feugiat nec orci. Nulla eget neque bibendum, gravida elit eget, volutpat purus. Nullam convallis eros neque, ac rhoncus felis pretium a. Maecenas et pulvinar risus. Duis consequat ac magna a ornare. Fusce eget ante efficitur, fermentum turpis id, ullamcorper neque. Duis sed tellus tellus.</h1>

  <img style="border-radius:12px" src="https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&fit=crop&w=1600&height=900" />

<div class="carousel">
  <div class="image">
    <img src="https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&fit=crop&w=1600&height=900" />
  </div>
  <div class="image">
    <img src="https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&fit=crop&w=1600&height=900" />
  </div>
  <div class="image">
    <img src="https://images.unsplash.com/photo-1494256997604-768d1f608cac?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&fit=crop&w=1600&height=900" />
  </div>
  <div class="image">
    <img src="https://images.unsplash.com/photo-1515002246390-7bf7e8f87b54?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&fit=crop&w=1600&height=900" />
  </div>
  <div class="image">
    <img src="https://images.unsplash.com/photo-1519052537078-e6302a4968d4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&fit=crop&w=1600&height=900" />
  </div>
</div>
<p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p>
<p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p>
<p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p><p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p><p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p><p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p><p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p><p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p><p>Proin in ex sed ipsum ullamcorper laoreet at eget elit. In euismod vehicula orci, luctus fermentum eros egestas at. Proin est tortor, egestas id sodales at, feugiat a lacus. Nulla bibendum sed purus vitae auctor. Maecenas vitae erat velit. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Suspendisse mattis ex eget mauris lobortis, ut tincidunt arcu fringilla. Suspendisse ultrices ex tortor, at lobortis felis elementum at. Nunc laoreet sed dui nec gravida. Proin non ipsum augue.</p>
''';
