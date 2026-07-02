import 'package:flutter/material.dart' hide Card;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/database/corpus_database.dart';
import '../../core/database/tables/deck_tables.dart';
import '../../core/database/user_database.dart';
import '../../core/decks/deck_repository.dart';
import '../../shared/providers/deck_providers.dart';

/// Deck detail (UI_COMPONENTS §5): header with flags and delete, sectioned
/// entry list with reserved indicators and per-entry shared toggles, a
/// collapsible unowned section, and a reservation summary line.
class DeckDetailScreen extends ConsumerWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(deckDetailProvider(deckId));

    return Scaffold(
      body: SafeArea(
        child: detailAsync.when(
          data: (detail) => detail == null
              ? Center(
                  child: Text('Deck not found', style: AppTypography.body),
                )
              : _DeckDetailView(detail: detail),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Failed to load deck: $e', style: AppTypography.body),
          ),
        ),
      ),
    );
  }
}

class _DeckDetailView extends ConsumerWidget {
  const _DeckDetailView({required this.detail});

  final DeckDetail detail;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete deck?'),
        content: Text(
          '"${detail.deck.name}" and its reservations will be removed. '
          'Your collection is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(deckRepositoryProvider).deleteDeck(detail.deck.id);
    if (context.mounted) context.go('/decks');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = detail.deck;
    final reservations = ref.watch(reservationProvider).valueOrNull;
    final cards =
        ref.watch(deckCardsProvider(deck.id)).valueOrNull ?? const {};
    final repository = ref.read(deckRepositoryProvider);

    final owned = detail.entries.where((e) => !e.isUnowned).toList();
    final unowned = detail.entries.where((e) => e.isUnowned).toList();

    final reservedCount = deck.isAssembled
        ? detail.entries
            .where((e) => e.section != DeckSection.maybeboard)
            .fold<int>(0, (sum, e) => sum + e.quantity)
        : 0;
    final unownedQty = unowned.fold<int>(0, (sum, e) => sum + e.quantity);
    final totalQty =
        detail.entries.fold<int>(0, (sum, e) => sum + e.quantity);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // -- Header --
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: 'Back to decks',
              onPressed: () => context.go('/decks'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name, style: AppTypography.headingLg),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (deck.format != null && deck.format!.isNotEmpty)
                        deck.format!,
                      '$totalQty cards',
                    ].join(' · '),
                    style: AppTypography.meta,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete deck',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // -- Flags --
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.neutral150),
          ),
          child: Row(
            children: [
              Expanded(
                child: _LabeledSwitch(
                  label: 'Assembled',
                  value: deck.isAssembled,
                  onChanged: (v) => repository.setDeckAssembled(deck.id, v),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _LabeledSwitch(
                  label: 'Shared',
                  value: deck.isShared,
                  onChanged: (v) => repository.setDeckShared(deck.id, v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // -- Reservation summary --
        Text(
          deck.isAssembled
              ? 'Cards this deck reserves from your collection: $reservedCount'
              : 'Not assembled — this deck reserves nothing.',
          style: AppTypography.meta,
        ),
        const SizedBox(height: AppSpacing.lg),

        // -- Sections --
        for (final section in DeckSection.values)
          if (owned.any((e) => e.section == section)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _sectionLabel(section),
                style: AppTypography.sectionLabel,
              ),
            ),
            for (final entry in owned.where((e) => e.section == section))
              _EntryRow(
                entry: entry,
                card: cards[entry.scryfallId],
                reserved: deck.isAssembled &&
                    section != DeckSection.maybeboard &&
                    (reservations?.reservedOf(entry.scryfallId) ?? 0) > 0,
                onSharedChanged: (v) =>
                    repository.setEntryShared(entry.id, v),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],

        // -- Unowned --
        if (unowned.isNotEmpty)
          Theme(
            data:
                Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'UNOWNED ($unownedQty)',
                style: AppTypography.sectionLabel
                    .copyWith(color: AppColors.amberText),
              ),
              children: [
                for (final entry in unowned)
                  _EntryRow(
                    entry: entry,
                    card: cards[entry.scryfallId],
                    reserved: false,
                    onSharedChanged: (v) =>
                        repository.setEntryShared(entry.id, v),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String _sectionLabel(DeckSection section) => switch (section) {
        DeckSection.main => 'MAIN',
        DeckSection.sideboard => 'SIDEBOARD',
        DeckSection.maybeboard => 'MAYBEBOARD',
      };
}

class _LabeledSwitch extends StatelessWidget {
  const _LabeledSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.body)),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.card,
    required this.reserved,
    required this.onSharedChanged,
  });

  final DeckEntryRow entry;
  final Card? card;
  final bool reserved;
  final ValueChanged<bool> onSharedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral100)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('${entry.quantity}×', style: AppTypography.meta),
          ),
          Expanded(
            child: Text(
              entry.cardName,
              style: AppTypography.bodySm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (entry.printingSpecified && card != null) ...[
            Text(
              '(${card!.setCode.toUpperCase()}) ${card!.collectorNumber}',
              style: AppTypography.meta,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (reserved) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral75,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: Border.all(color: AppColors.neutral150),
              ),
              child: Text('RESERVED', style: AppTypography.tag),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text('Shared', style: AppTypography.bodyXs),
          Switch(
            value: entry.isShared,
            onChanged: onSharedChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
