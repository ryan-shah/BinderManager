import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import 'parse_summary.dart';

/// Amber warning shown when a Replace import would swap a non-empty
/// ManaBox snapshot (D8).
class ReplaceWarningBanner extends StatelessWidget {
  const ReplaceWarningBanner({
    super.key,
    required this.incomingCount,
    required this.previousCount,
  });

  /// Number of stacks the incoming file resolves to.
  final int incomingCount;

  /// Number of manabox stacks currently in the collection.
  final int previousCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        border: Border.all(color: AppColors.amberBorder),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.amberText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This replaces your ManaBox collection: '
              '${formatThousands(incomingCount)} cards, was '
              '${formatThousands(previousCount)} — review before committing',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
