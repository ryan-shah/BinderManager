import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/models/binder_diff.dart';

/// The sticky Commit / Roll back action bar (§13) — appears wherever a
/// change is staged (D7).
///
/// Context-free by design: it takes the staged diff plus two callbacks, so
/// the change-review screen (§10) and later surfaces (binder view §9) can
/// mount the same bar. Hosts typically place it in a `Scaffold`'s
/// `bottomNavigationBar` slot or pin it below a list.
class CommitRollbackBar extends StatelessWidget {
  const CommitRollbackBar({
    super.key,
    required this.diff,
    required this.onCommit,
    required this.onRollback,
    this.busy = false,
  });

  final StagedDiff diff;
  final VoidCallback onCommit;
  final VoidCallback onRollback;

  /// Disables both actions (e.g. while a commit is in flight).
  final bool busy;

  /// Summary like `4 adds · 1 remove · 2 moves` (zero counts omitted).
  static String summaryText(StagedDiff diff) {
    String plural(int count, String noun) =>
        '$count $noun${count == 1 ? '' : 's'}';

    final parts = [
      if (diff.addCount > 0) plural(diff.addCount, 'add'),
      if (diff.removeCount > 0) plural(diff.removeCount, 'remove'),
      if (diff.moveCount > 0) plural(diff.moveCount, 'move'),
    ];
    if (parts.isEmpty) return 'No placement changes';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(top: BorderSide(color: AppColors.neutral150)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summaryText(diff),
              style: AppTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton(
            onPressed: busy ? null : onRollback,
            child: const Text('Roll back'),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: busy ? null : onCommit,
            child: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Commit'),
          ),
        ],
      ),
    );
  }
}
