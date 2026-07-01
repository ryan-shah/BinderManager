import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Displays the last data-update timestamp, with a warning when data is stale.
///
/// "Stale" means the data is older than 7 days from now.
/// The refresh button is a non-functional placeholder — Agent A will wire it up.
class DataFreshnessBanner extends StatelessWidget {
  const DataFreshnessBanner({super.key, this.lastUpdated});

  /// The date the card corpus was last updated.
  /// When `null` the banner shows nothing.
  final DateTime? lastUpdated;

  bool get _isStale {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inDays > 7;
  }

  @override
  Widget build(BuildContext context) {
    if (lastUpdated == null) return const SizedBox.shrink();

    final dateLabel =
        '${lastUpdated!.year}-${_pad(lastUpdated!.month)}-${_pad(lastUpdated!.day)}';

    if (!_isStale) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 14, color: AppColors.neutral400),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Data updated: $dateLabel',
            style: AppTypography.meta.copyWith(color: AppColors.neutral500),
          ),
        ],
      );
    }

    // Stale state — amber warning
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        border: Border.all(color: AppColors.amberBorder),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.amberDot),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Data is stale (>7 days)',
            style: AppTypography.meta.copyWith(color: AppColors.amberText),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              // Placeholder — Agent A will wire up a real refresh action.
            },
            child: Text(
              'Refresh',
              style: AppTypography.meta.copyWith(
                color: AppColors.amberText,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
