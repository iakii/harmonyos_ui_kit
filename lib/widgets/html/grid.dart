import 'package:extended_image/extended_image.dart' show ExtendedImage;
import 'package:flutter/material.dart';
import 'package:harmonyos_ui/harmonyos_ui.dart' show showHosBottomSheet;
import 'package:rohos_app/widgets/loading.dart' show imageLoadState;
import 'package:styled_widget/styled_widget.dart' show StyledWidget;
import 'package:html/dom.dart' as html;

import '../staggered_grid_view/staggered_grid_view.dart';

class HtmlGridView extends StatelessWidget {
  const HtmlGridView({super.key, required this.element});
  final html.Element element;

  @override
  Widget build(BuildContext context) {
    final srcs = <String>[];
    final origins = <String>[];
    for (final child in element.children) {
      if (child.attributes case {'src': final String src}) {
        srcs.add(src);
      }
      if (child.attributes case {'alt': final String alt}) {
        origins.add(alt);
      }
    }

    return StaggeredGridView.countBuilder(
      // controller: _controller,
      crossAxisCount: 3,
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      itemCount: srcs.length,
      itemBuilder: (BuildContext context, int index) {
        final item = srcs[index];
        return ExtendedImage.network(
              item,
              fit: BoxFit.cover,
              headers: {"referer": item, "referrerpolicy": "unsafe-url"},
              handleLoadingProgress: true,
              cache: false,
              loadStateChanged: imageLoadState,
            )
            .clipRRect(all: 12)
            .ripple()
            .gestures(
              onTap: () {
                showHosBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return ListView(
                      children: [
                        Center(
                          child: ExtendedImage.network(
                            origins[index],
                            fit: BoxFit.cover,
                            loadStateChanged: imageLoadState,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
      },
      staggeredTileBuilder: (index) => const StaggeredTile.fit(1),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    );
  }
}
