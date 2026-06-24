import 'package:flutter/material.dart' show Widget;
import 'package:html/dom.dart' as html;
import 'carousel.dart';
import 'grid.dart';

Widget? customWidgetBuilder(html.Element element) {
  if (element.classes.contains('grid')) {
    return HtmlGridView(element: element);
  }
  if (element.classes.contains('carousel')) {
    return HtmlCarouselView(element: element);
  }
  return null;
}
