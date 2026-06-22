import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'
    show ConsumerWidget, WidgetRef;

class GalleryLayout extends ConsumerWidget {
  const GalleryLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HosPage(showAppBar: false, title: '测试', body: child);
  }
}
