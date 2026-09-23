import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/pagination_data.dart';

/// Reusable, theme-aware pagination footer used by the list screens.
///
/// Shows a "Showing X–Y of Z" summary, prev/next arrows and a compact
/// set of page chips (with ellipsis gaps for large page counts). The
/// active page chip uses the brand gradient.
class PaginationBar extends StatelessWidget {
  final PaginationData data;
  final bool isLoading;

  /// Invoked with the new 0-based page index.
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.data,
    this.isLoading = false,
    required this.onPageChanged,
  });

  String get _summary {
    if (data.totalElements == 0) return 'No records';
    return 'Showing ${data.firstItem}–${data.lastItem} of ${data.totalElements}';
  }

  /// Page numbers to render; `null` marks an ellipsis gap.
  static List<int?> _window(int current, int total) {
    if (total <= 7) return [for (var i = 0; i < total; i++) i];
    final core = <int>{0, total - 1, current, current - 1, current + 1};
    final sorted =
        core.where((p) => p >= 0 && p < total).toList()..sort();
    final out = <int?>[];
    for (var i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i] - sorted[i - 1] > 1) out.add(null);
      out.add(sorted[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _window(data.page, data.totalPages);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.borderC(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _summary,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (isLoading)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Loading...',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSec(context)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ArrowButton(
                icon: Icons.chevron_left_rounded,
                enabled: !isLoading && data.hasPrevious,
                onTap: () => onPageChanged(data.page - 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final p in pages)
                        p == null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(
                                  '...',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textHi(context)),
                                ),
                              )
                            : _PageChip(
                                label: '${p + 1}',
                                selected: p == data.page,
                                onTap: isLoading || p == data.page
                                    ? null
                                    : () => onPageChanged(p),
                              ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ArrowButton(
                icon: Icons.chevron_right_rounded,
                enabled: !isLoading && data.hasNext,
                onTap: () => onPageChanged(data.page + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PageChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 36,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryDarkGradient : null,
              color: selected ? null : AppColors.surfaceVariantColor(context),
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? null
                  : Border.all(color: AppColors.borderC(context)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : AppColors.textSec(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primarySurface
                : AppColors.surfaceVariantColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.primary : AppColors.textHi(context),
          ),
        ),
      ),
    );
  }
}