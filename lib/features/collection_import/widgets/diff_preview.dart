import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/import/collection_importer.dart';
import 'parse_summary.dart';

/// What Commit will change, grouped Add / Remove / Change with quantity
/// before → after per entry (D7 gate).
class DiffPreview extends StatelessWidget {
  const DiffPreview({super.key, required this.diff});

  final ImportDiff diff;

  @override
  Widget build(BuildContext context) {
    if (diff.isEmpty) {
      return Text('No changes to commit', style: AppTypography.meta);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DiffSection(
          label: 'ADD',
          entries: diff.adds,
          color: AppColors.statusAddText,
        ),
        _DiffSection(
          label: 'REMOVE',
          entries: diff.removes,
          color: AppColors.statusRemoveText,
        ),
        _DiffSection(
          label: 'CHANGE',
          entries: diff.changes,
          color: AppColors.neutral600,
        ),
      ],
    );
  }
}

class _DiffSection extends StatelessWidget {
  const _DiffSection({
    required this.label,
    required this.entries,
    required this.color,
  });

  final String label;
  final List<DiffEntry> entries;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${formatThousands(entries.length)})',
            style: AppTypography.sectionLabel.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.cardName,
                      style: AppTypography.bodySm,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${entry.setCode} #${entry.collectorNumber}',
                    style: AppTypography.tag,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    entry.identity.finish.name,
                    style: AppTypography.tag,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${entry.qtyBefore} → ${entry.qtyAfter}',
                    style: AppTypography.meta.copyWith(color: color),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
