import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/models/binder_diff.dart';
import '../../shared/providers/change_staging_provider.dart';
import '../../shared/providers/corpus_provider.dart';
import '../../shared/providers/user_database_provider.dart';
import '../../shared/widgets/commit_rollback_bar.dart';

/// Card and binder names resolved for the staged diff's rows.
class _ReviewLookups {
  const _ReviewLookups({this.binderNames = const {}, this.cardNames = const {}});

  final Map<String, String> binderNames;
  final Map<String, String> cardNames;

  String binderName(String binderId) => binderNames[binderId] ?? binderId;

  /// Falls back to the scryfallId when the corpus doesn't know the card.
  String cardName(String scryfallId) => cardNames[scryfallId] ?? scryfallId;
}

/// Resolves display names for the staged diff: binder names from the user
/// DB, card names from the corpus. Lookups are deduplicated per unique
/// scryfallId (one `getCard` each), and the whole result caches until the
/// staged diff changes.
final _reviewLookupsProvider =
    FutureProvider.autoDispose<_ReviewLookups>((ref) async {
  final diff = ref.watch(changeStagingProvider);
  if (diff == null) return const _ReviewLookups();

  final userDb = ref.watch(userDatabaseProvider);
  final corpus = ref.watch(corpusDatabaseProvider);

  final binders = await userDb.select(userDb.binders).get();
  final binderNames = {for (final binder in binders) binder.id: binder.name};

  final scryfallIds = <String>{
    for (final entry in diff.entries) entry.identity.scryfallId,
    for (final overflow in diff.overflowChanges) overflow.identity.scryfallId,
  };
  final cardNames = <String, String>{};
  for (final id in scryfallIds) {
    final card = await corpus.getCard(id);
    if (card != null) cardNames[id] = card.name;
  }

  return _ReviewLookups(binderNames: binderNames, cardNames: cardNames);
});

/// Change review — diff & commit/rollback (§10).
///
/// The universal D7 gate: shows the staged diff (grouped by binder, rows
/// typed Add/Remove/Move with exact location instructions), overflow
/// changes, and the sticky Commit / Roll back bar (§13).
class ChangeReviewScreen extends ConsumerStatefulWidget {
  const ChangeReviewScreen({super.key});

  @override
  ConsumerState<ChangeReviewScreen> createState() => _ChangeReviewScreenState();
}

class _ChangeReviewScreenState extends ConsumerState<ChangeReviewScreen> {
  bool _busy = false;
  bool _justCommitted = false;

  Future<void> _commit() async {
    setState(() => _busy = true);
    try {
      await ref.read(changeStagingProvider.notifier).commit();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _justCommitted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commit failed: $error')),
      );
    }
  }

  Future<void> _rollback() async {
    setState(() => _busy = true);
    try {
      await ref.read(changeStagingProvider.notifier).rollback();
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rolled back to the last committed state'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Roll back failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = ref.watch(changeStagingProvider);

    if (diff == null) {
      return Scaffold(
        body: _justCommitted ? const _CommittedState() : const _EmptyState(),
      );
    }

    final lookups = ref.watch(_reviewLookupsProvider).valueOrNull ??
        const _ReviewLookups();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _Header(diff: diff),
          const SizedBox(height: AppSpacing.lg),
          for (final MapEntry(key: binderId, value: entries)
              in diff.entriesByBinder.entries) ...[
            _BinderSection(
              binderName: lookups.binderName(binderId),
              entries: entries,
              lookups: lookups,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (diff.overflowChanges.isNotEmpty)
            _OverflowSection(diff: diff, lookups: lookups),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: CommitRollbackBar(
          diff: diff,
          busy: _busy,
          onCommit: _commit,
          onRollback: _rollback,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 40, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.md),
          Text('No pending changes.', style: AppTypography.body),
        ],
      ),
    );
  }
}

class _CommittedState extends StatelessWidget {
  const _CommittedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle,
              size: 40, color: AppColors.statusAddText),
          const SizedBox(height: AppSpacing.md),
          Text('Committed', style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Planned and committed state now match.',
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.diff});

  final StagedDiff diff;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review changes', style: AppTypography.headingLg),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral75,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Text(diff.trigger.label, style: AppTypography.tag),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                CommitRollbackBar.summaryText(diff),
                style: AppTypography.meta,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BinderSection extends StatelessWidget {
  const _BinderSection({
    required this.binderName,
    required this.entries,
    required this.lookups,
  });

  final String binderName;
  final List<BinderDiffEntry> entries;
  final _ReviewLookups lookups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          binderName.toUpperCase(),
          style: AppTypography.sectionLabel,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(),
                _DiffRow(
                  entry: entries[i],
                  cardName: lookups.cardName(entries[i].identity.scryfallId),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One Add / Remove / Move row with the exact D7 location instruction (§13
/// "Diff row").
class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.entry, required this.cardName});

  final BinderDiffEntry entry;
  final String cardName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          _TypeChip(type: entry.type),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              entry.instruction(cardName),
              style: AppTypography.body,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('×${entry.quantity}', style: AppTypography.meta),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final DiffType type;

  @override
  Widget build(BuildContext context) {
    final (label, background, border, textColor) = switch (type) {
      DiffType.add => (
          'ADD',
          AppColors.statusAddBg,
          AppColors.statusAddBorder,
          AppColors.statusAddText,
        ),
      DiffType.remove => (
          'REMOVE',
          AppColors.statusRemoveBg,
          AppColors.statusRemoveBorder,
          AppColors.statusRemoveText,
        ),
      DiffType.move => (
          'MOVE',
          AppColors.statusMoveBg,
          AppColors.statusMoveBorder,
          AppColors.neutral700,
        ),
    };

    return Container(
      width: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: textColor),
      ),
    );
  }
}

class _OverflowSection extends StatelessWidget {
  const _OverflowSection({required this.diff, required this.lookups});

  final StagedDiff diff;
  final _ReviewLookups lookups;

  @override
  Widget build(BuildContext context) {
    final overflow = diff.overflowChanges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OVERFLOW', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.amberBg,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.amberBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${overflow.length} matched but didn't fit",
                style: AppTypography.body.copyWith(color: AppColors.amberText),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in overflow)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${lookups.cardName(entry.identity.scryfallId)} '
                    '×${entry.quantity} — ${lookups.binderName(entry.binderId)}',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.amberText),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
