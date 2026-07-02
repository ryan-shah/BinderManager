import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/import/collection_importer.dart';

/// Replace ⟷ Append segmented control with a one-line explanation of the
/// selected mode (D8).
class ImportModeSelector extends StatelessWidget {
  const ImportModeSelector({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final ImportMode mode;
  final ValueChanged<ImportMode> onChanged;
  final bool enabled;

  static const _explanations = {
    ImportMode.replace:
        'Swaps your ManaBox snapshot to match this file exactly.',
    ImportMode.append:
        'Adds these quantities on top of your existing collection.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<ImportMode>(
          segments: const [
            ButtonSegment(
              value: ImportMode.replace,
              label: Text('Replace'),
            ),
            ButtonSegment(
              value: ImportMode.append,
              label: Text('Append'),
            ),
          ],
          selected: {mode},
          onSelectionChanged:
              enabled ? (selection) => onChanged(selection.first) : null,
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            textStyle: AppTypography.button,
            selectedBackgroundColor: AppColors.neutral900,
            selectedForegroundColor: AppColors.neutral0,
            foregroundColor: AppColors.neutral700,
            side: const BorderSide(color: AppColors.neutral200),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _explanations[mode]!,
          style: AppTypography.bodyXs,
        ),
      ],
    );
  }
}
