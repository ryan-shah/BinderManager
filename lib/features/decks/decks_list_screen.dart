import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/decks/deck_repository.dart';
import '../../shared/providers/deck_providers.dart';

/// Decks list (UI_COMPONENTS §5): deck rows with format, card count,
/// Assembled/Shared badges, and an unowned badge; "+ Import deck" CTA.
class DecksListScreen extends ConsumerWidget {
  const DecksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Text('Decks', style: AppTypography.headingLg),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/decks/import'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Import deck'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: decksAsync.when(
                data: (decks) => decks.isEmpty
                    ? _EmptyState(
                        onImport: () => context.go('/decks/import'),
                      )
                    : ListView.builder(
                        itemCount: decks.length,
                        itemBuilder: (context, index) => _DeckRow(
                          deck: decks[index],
                          onTap: () =>
                              context.go('/decks/${decks[index].id}'),
                        ),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load decks: $e',
                    style: AppTypography.body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  const _DeckRow({required this.deck, required this.onTap});

  final DeckListItem deck;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metaParts = <String>[
      if (deck.format != null && deck.format!.isNotEmpty) deck.format!,
      '${deck.cardCount} cards',
    ];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.neutral100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name, style: AppTypography.headingSm),
                  const SizedBox(height: 2),
                  Text(metaParts.join(' · '), style: AppTypography.meta),
                ],
              ),
            ),
            if (deck.unownedCount > 0) ...[
              _Tag('${deck.unownedCount} unowned', amber: true),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (deck.isAssembled) ...[
              const _Tag('ASSEMBLED'),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (deck.isShared) ...[
              const _Tag('SHARED'),
              const SizedBox(width: AppSpacing.sm),
            ],
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, {this.amber = false});

  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: amber ? AppColors.amberBg : AppColors.neutral75,
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(
          color: amber ? AppColors.amberBorder : AppColors.neutral150,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.tag.copyWith(
          color: amber ? AppColors.amberText : AppColors.neutral600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style, size: 48, color: AppColors.neutral300),
          const SizedBox(height: AppSpacing.lg),
          Text('No decks yet', style: AppTypography.headingMd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Import a decklist to start reserving cards.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: onImport,
            child: const Text('Import a deck'),
          ),
        ],
      ),
    );
  }
}
