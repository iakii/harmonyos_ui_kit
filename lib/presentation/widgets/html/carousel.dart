import 'package:carousel_slider/carousel_options.dart' show CarouselOptions;
import 'package:carousel_slider/carousel_slider.dart' show CarouselSlider;
import 'package:extended_image/extended_image.dart' show ExtendedImage;
import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart' show HarmonyTheme;
import 'package:html/dom.dart' as html;
import 'package:rohos_app/presentation/widgets/loading.dart'
    show imageLoadState;
import 'package:styled_widget/styled_widget.dart' show StyledWidget;

class HtmlCarouselView extends StatelessWidget {
  const HtmlCarouselView({super.key, required this.element});
  final html.Element element;

  @override
  Widget build(BuildContext context) {
    final srcs = <String>[];
    for (final child in element.children) {
      for (final grandChild in child.children) {
        if (grandChild.attributes case {'src': final String src}) {
          srcs.add(src);
        }
      }
    }

    final theme = HarmonyTheme.of(context);

    return Container(
      height: 156,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          autoPlayAnimationDuration: const Duration(seconds: 1),
          autoPlayInterval: const Duration(seconds: 3),
          enlargeCenterPage: true,
        ),
        items: srcs.map((src) => _toItem(src, theme)).toList(growable: false),
      ),
    );
  }

  Widget _toItem(String src, theme) => Center(
    child: ExtendedImage.network(
      src,
      fit: BoxFit.cover,
      width: double.infinity,
      loadStateChanged: imageLoadState,
    ).clipRRect(all: 8),
  );
}
