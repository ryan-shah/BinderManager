import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../providers/change_staging_provider.dart';
import 'commit_rollback_bar.dart';

/// Surfaces the staged D7 diff on every shell screen: a slim banner pinned
/// under the content with the diff summary and a Review action (§7 pending
/// banner, generalized). Hidden on the review screen itself, which mounts
/// the full Commit/Rollback bar (§13) instead.
class PendingChangesScope extends ConsumerWidget {
  const PendingChangesScope({
    super.key,
    required this.location,
    required this.child,
  });

  /// The current matched route location, to suppress the banner on
  /// `/changes`.
  final String location;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref.watch(changeStagingProvider);
    if (diff == null || location == '/changes') return child;

    return Column(
      children: [
        Expanded(child: child),
        Material(
          color: AppColors.amberBg,
          child: InkWell(
            onTap: () => context.go('/changes'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.amberBorder)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    size: 16,
                    color: AppColors.amberText,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Pending changes — '
                      '${CommitRollbackBar.summaryText(diff)}',
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.amberText),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Review →',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.amberText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
