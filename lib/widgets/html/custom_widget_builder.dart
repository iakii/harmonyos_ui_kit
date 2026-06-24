import 'package:flutter/material.dart'
    show Widget, Text, TextStyle, FontWeight, Colors;
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:html/dom.dart' as html;
import 'package:rohos_app/router.dart' show router;
import 'package:styled_widget/styled_widget.dart';

import 'carousel.dart';
import 'grid.dart';

Widget? customWidgetBuilder(html.Element element) {
  if (element.classes.contains('grid')) {
    return HtmlGridView(element: element);
  }
  if (element.classes.contains('carousel')) {
    return HtmlCarouselView(element: element);
  }
  // title left
  if (element.classes.contains('title') && element.classes.contains('left')) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child:
          Text(
            element.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
          ).gestures(
            onTap: () {
              // debugPrint('Title tapped: ${element.attributes['href']}');
              router.push("/rust", extra: element.attributes['href'] ?? '/');
            },
          ),
    );
  }
  return null;
}
