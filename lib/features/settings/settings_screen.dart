import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../shared/providers/corpus_provider.dart';

/// Settings — currently the D11 "Refresh card data" surface.
///
/// The refresh reuses the onboarding corpus import pipeline; completion is
/// handled app-wide by `CorpusRefreshListener`, so navigating away during
/// the (minutes-long) download loses nothing. Currency, layout defaults,
/// and JSON export/import (§12) land with later Phase 4/5 work.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(corpusImportProvider);
    final lastUpdated = ref.watch(corpusLastUpdatedProvider).valueOrNull;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Settings', style: AppTypography.headingLg),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'CARD DATA',
            style: AppTypography.sectionLabel
                .copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CardDataSection(importState: importState, lastUpdated: lastUpdated),
        ],
      ),
    );
  }
}

class _CardDataSection extends ConsumerWidget {
  const _CardDataSection({
    required this.importState,
    required this.lastUpdated,
  });

  final CorpusImportState importState;
  final DateTime? lastUpdated;

  bool get _isRefreshing =>
      importState.phase != 'idle' &&
      importState.error == null &&
      !importState.complete;

  bool get _isStale =>
      lastUpdated != null &&
      DateTime.now().difference(lastUpdated!).inDays > 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_freshnessLabel(), style: AppTypography.bodySm),
        if (_isStale)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Data is older than 7 days — refresh recommended.',
              style: AppTypography.meta.copyWith(color: AppColors.amberText),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh card data'),
          // Completion side effects (search refresh, and with Phase 4
          // integration: binder diff staging) run in CorpusRefreshListener.
          onPressed: _isRefreshing
              ? null
              : () => ref.read(corpusImportProvider.notifier).runImport(),
        ),
        if (_isRefreshing) ...[
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(value: importState.progress),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _progressLabel(),
            style: AppTypography.meta.copyWith(color: AppColors.neutral500),
          ),
        ],
        if (importState.error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Refresh failed: ${importState.error}',
            style:
                AppTypography.bodySm.copyWith(color: AppColors.statusRemoveText),
          ),
        ],
      ],
    );
  }

  String _freshnessLabel() {
    final date = lastUpdated;
    if (date == null) return 'Card data has not been downloaded yet.';
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return 'Last updated: $y-$m-$d';
  }

  String _progressLabel() {
    final buffer = StringBuffer(importState.phase);
    if (importState.cardsImported > 0) {
      buffer.write(' — ${importState.cardsImported} cards');
    }
    return buffer.toString();
  }
}
