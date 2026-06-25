import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:harmonyos_ui/harmonyos_ui.dart';
import 'package:hm_icon/hm_icon.dart';

class Pagination extends StatelessWidget {
  const Pagination({
    super.key,
    required this.theme,
    required this.currentPage,
    required this.isLoading,
    required this.onPrevPage,
    required this.totalPage,
    required this.hasMore,
    required this.onNextPage,
  });

  final HarmonyThemeData theme;
  final int currentPage;
  final bool isLoading;
  final VoidCallback onPrevPage;
  final int totalPage;
  final bool hasMore;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 48,
        height: 136,
        decoration: BoxDecoration(
          color: theme.surfaceColor.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            HosTextButton(
              enabled: currentPage > 1 && !isLoading,
              onPressed: currentPage > 1 && !isLoading ? onPrevPage : null,
              child: Icon(HMIcons.chevronLeftCircle, size: 32),
            ),

            // 页码区（加载中显示小转圈）
            SizedBox(
              width: 80,
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                      ],
                    )
                  : null,
              // : Text(
              //     '$currentPage / $totalPage',
              //     textAlign: TextAlign.center,
              //     style: theme.typography.caption,
              //   ),
            ),

            HosTextButton(
              enabled: hasMore && !isLoading,
              onPressed: hasMore && !isLoading ? onNextPage : null,
              child: Icon(HMIcons.chevronRightCircle, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}
