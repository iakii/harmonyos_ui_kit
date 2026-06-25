import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';
import 'package:hm_icon/hm_icon.dart';

/// 图标预览页面 — 网格展示所有 HMIcons，支持搜索和复制。
class IconPreviewPage extends StatefulWidget {
  const IconPreviewPage({super.key});

  @override
  State<IconPreviewPage> createState() => _IconPreviewPageState();
}

class _IconPreviewPageState extends State<IconPreviewPage> {
  final _controller = TextEditingController();
  String _query = '';
  late final List<HMIconEntry> _filtered;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      _filtered = allHMIcons.toList();
    });
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _controller.text.toLowerCase().trim();
    if (q == _query) return;
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _filtered.clear();
        _filtered.addAll(allHMIcons);
      } else {
        _filtered
          ..clear()
          ..addAll(allHMIcons.where((e) => e.name.toLowerCase().contains(q)));
      }
    });
  }

  void _onTap(HMIconEntry entry) {
    final snippet = "HMIcons.${entry.name}";
    Clipboard.setData(ClipboardData(text: snippet));
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制: $snippet'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // 搜索栏
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: '搜索图标…（共 ${allHMIcons.length} 个）',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _controller.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
            ),
          ),
        ),

        // 结果计数
        if (_query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${_filtered.length} 个结果',
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(150),
                fontSize: 13,
              ),
            ),
          ),

        // 图标网格
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    '无匹配图标',
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                )
              : ListView(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1,
                          ),
                      itemBuilder: (context, index) {
                        final entry = _filtered[index];
                        return _IconTile(
                          entry: entry,
                          onTap: () => _onTap(entry),
                        );
                      },
                    ),

                    SizedBox(height: 128),
                  ],
                ),
        ),
      ],
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.entry, required this.onTap});

  final HMIconEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message:
          '${entry.name}\nU+${entry.codePoint.toRadixString(16).toUpperCase().padLeft(5, '0')}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(entry.icon, size: 28, color: colorScheme.onSurface),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurface.withAlpha(160),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
