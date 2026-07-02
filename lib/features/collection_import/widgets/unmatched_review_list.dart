import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/import/manabox_parser.dart';

/// The manual review queue: one entry per unmatched CSV row with its reason
/// and Map… / Ignore actions (D8 — rows are never silently dropped).
class UnmatchedReviewList extends StatelessWidget {
  const UnmatchedReviewList({
    super.key,
    required this.rows,
    required this.onMap,
    required this.onIgnore,
    this.enabled = true,
  });

  final List<UnmatchedRow> rows;

  /// Called with the index (into [rows]) the user wants to map.
  final ValueChanged<int> onMap;

  /// Called with the index (into [rows]) the user wants to ignore.
  final ValueChanged<int> onIgnore;

  final bool enabled;

  static const _reasonLabels = {
    UnmatchReason.missingScryfallId: 'no scryfall id',
    UnmatchReason.unknownScryfallId: 'unknown id',
    UnmatchReason.finishUnavailable: 'finish unavailable',
    UnmatchReason.invalidFinish: 'invalid finish',
    UnmatchReason.invalidQuantity: 'invalid quantity',
    UnmatchReason.malformedRow: 'malformed row',
  };

  static String _rawCell(UnmatchedRow row, String header) {
    for (final entry in row.raw.entries) {
      if (entry.key.toLowerCase() == header) return entry.value.trim();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) _buildRow(context, i),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final row = rows[index];
    final name = _rawCell(row, 'name');
    final setCode = _rawCell(row, 'set code');
    final quantity = _rawCell(row, 'quantity');
    final meta = [
      'row ${row.lineNumber}',
      if (setCode.isNotEmpty) setCode.toUpperCase(),
      if (quantity.isNotEmpty) 'qty $quantity',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? '(unnamed row)' : name,
                  style: row.ignored
                      ? AppTypography.headingXs.copyWith(
                          color: AppColors.neutral400,
                          decoration: TextDecoration.lineThrough,
                        )
                      : AppTypography.headingXs,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ReasonChip(label: _reasonLabels[row.reason]!),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(meta, style: AppTypography.meta),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              TextButton(
                onPressed:
                    enabled && !row.ignored ? () => onMap(index) : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.neutral900,
                  textStyle: AppTypography.button,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: const Text('Map…'),
              ),
              TextButton(
                onPressed:
                    enabled && !row.ignored ? () => onIgnore(index) : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.neutral500,
                  textStyle: AppTypography.button,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: Text(row.ignored ? 'Ignored' : 'Ignore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.amberBg,
        border: Border.all(color: AppColors.amberBorder),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        label,
        style: AppTypography.tag.copyWith(color: AppColors.amberText),
      ),
    );
  }
}
