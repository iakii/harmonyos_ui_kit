import 'package:flutter/material.dart'
    show Widget, Text, TextStyle, FontWeight, Colors, Icons;
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

  if (element.localName == 'li' && element.classes.contains('shared-li')) {
    // debugPrint('List item tapped: ${element.nodes.map((node)=>node.).toList()}');
    final a = element.querySelector('a.title')!;
    final count = element.querySelector('span.show-count');
    final author = element.querySelector('span.author');
    final timestamp = element.querySelector('span.timestamp')!;
    return HosCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                count?.text ?? '0',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Icon(Icons.person, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  author?.text ?? "rustcc",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                timestamp.text,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ).gestures(
      onTap: () {
        router.push(
          "/rust",
          extra: {
            'url': a.attributes['href'] ?? '/',
            'type': "detail",
            'title': a.text,
          },
        );
      },
    );
  }
  // title left
  // if (element.classes.contains('title') && element.classes.contains('left')) {
  //   return MouseRegion(
  //     cursor: SystemMouseCursors.click,
  //     child:
  //         Text(
  //           element.text,
  //           style: const TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             decoration: TextDecoration.underline,
  //             color: Colors.blue,
  //           ),
  //         ).gestures(
  //           onTap: () {
  //             // debugPrint('Title tapped: ${element.attributes['href']}');
  //             router.push("/rust", extra: element.attributes['href'] ?? '/');
  //           },
  //         ),
  //   );
  // }
  return null;
}
