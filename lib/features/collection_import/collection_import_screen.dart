import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../core/import/collection_importer.dart';
import '../../shared/providers/collection_import_provider.dart';
import '../../shared/providers/corpus_provider.dart';
import 'widgets/diff_preview.dart';
import 'widgets/import_file_button.dart';
import 'widgets/import_mode_selector.dart';
import 'widgets/map_unmatched_dialog.dart';
import 'widgets/parse_summary.dart';
import 'widgets/replace_warning_banner.dart';
import 'widgets/unmatched_review_list.dart';

/// ManaBox CSV collection import (UI_COMPONENTS §3).
///
/// Desktop: two-pane — file/mode/summary/diff on the left, unmatched review
/// queue on the right. Mobile: single-column wizard. A sticky bottom action
/// bar carries the parse summary plus Cancel / Commit (the D7 gate).
class CollectionImportScreen extends ConsumerWidget {
  const CollectionImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectionImportProvider);
    final mode = layoutModeOf(context);

    final Widget body;
    if (state.phase == CollectionImportPhase.done) {
      body = _buildDone(context, ref, state);
    } else if (mode == LayoutMode.desktop) {
      body = _buildDesktop(context, ref, state);
    } else {
      body = _buildMobile(context, ref, state);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Import collection')),
      body: body,
      bottomNavigationBar: state.phase == CollectionImportPhase.done
          ? null
          : _buildActionBar(context, ref, state),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _cancel(BuildContext context, WidgetRef ref) {
    ref.read(collectionImportProvider.notifier).reset();
    context.go('/collection');
  }

  Future<void> _mapRow(BuildContext context, WidgetRef ref, int index) async {
    final state = ref.read(collectionImportProvider);
    final unmatched = state.parseResult?.unmatched;
    if (unmatched == null || index >= unmatched.length) return;

    final identity = await showMapUnmatchedDialog(
      context,
      corpus: ref.read(corpusDatabaseProvider),
      row: unmatched[index],
    );
    if (identity == null) return;
    await ref
        .read(collectionImportProvider.notifier)
        .mapUnmatched(index, identity);
  }

  // ---------------------------------------------------------------------------
  // Source pane (file, mode, summary, diff)
  // ---------------------------------------------------------------------------

  List<Widget> _buildSourceChildren(
    BuildContext context,
    WidgetRef ref,
    CollectionImportState state,
  ) {
    final notifier = ref.read(collectionImportProvider.notifier);
    final busy = state.phase == CollectionImportPhase.parsing ||
        state.phase == CollectionImportPhase.committing;
    final showReplaceWarning = state.mode == ImportMode.replace &&
        state.previousStackCount > 0 &&
        state.parseResult != null;

    return [
      Text('SOURCE', style: AppTypography.sectionLabel),
      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: Alignment.centerLeft,
        child: ImportFileButton(
          fileName: state.fileName,
          enabled: !busy,
          onFilePicked: notifier.loadFile,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Text('MODE', style: AppTypography.sectionLabel),
      const SizedBox(height: AppSpacing.md),
      ImportModeSelector(
        mode: state.mode,
        enabled: !busy,
        onChanged: notifier.setMode,
      ),
      if (showReplaceWarning) ...[
        const SizedBox(height: AppSpacing.lg),
        ReplaceWarningBanner(
          incomingCount: state.parseResult!.matched.length,
          previousCount: state.previousStackCount,
        ),
      ],
      if (state.phase == CollectionImportPhase.parsing) ...[
        const SizedBox(height: AppSpacing.xl),
        const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        Text('parsing ${state.fileName}…', style: AppTypography.meta),
      ],
      if (state.phase == CollectionImportPhase.committing) ...[
        const SizedBox(height: AppSpacing.xl),
        const LinearProgressIndicator(),
        const SizedBox(height: AppSpacing.sm),
        Text('committing…', style: AppTypography.meta),
      ],
      if (state.error != null) ...[
        const SizedBox(height: AppSpacing.lg),
        Text(
          state.error!,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.statusRemoveText,
          ),
        ),
      ],
      if (state.parseResult != null) ...[
        const SizedBox(height: AppSpacing.xl),
        Text('SUMMARY', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        ParseSummary(result: state.parseResult!),
      ],
      if (state.diff != null) ...[
        const SizedBox(height: AppSpacing.xl),
        Text('CHANGES', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        DiffPreview(diff: state.diff!),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Unmatched review queue
  // ---------------------------------------------------------------------------

  Widget _buildUnmatchedHeader(CollectionImportState state) {
    final count = state.parseResult?.unmatched.length ?? 0;
    return Row(
      children: [
        Text('UNMATCHED', style: AppTypography.sectionLabel),
        if (count > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.amberBg,
              border: Border.all(color: AppColors.amberBorder),
              borderRadius: BorderRadius.circular(AppRadii.xxl),
            ),
            child: Text(
              formatThousands(count),
              style: AppTypography.badge.copyWith(
                color: AppColors.amberText,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnmatchedContent(
    BuildContext context,
    WidgetRef ref,
    CollectionImportState state,
  ) {
    final notifier = ref.read(collectionImportProvider.notifier);

    if (state.parseResult == null) {
      return Center(
        child: Text(
          'Pick a ManaBox CSV to begin',
          style: AppTypography.body.copyWith(color: AppColors.neutral400),
        ),
      );
    }
    if (state.parseResult!.unmatched.isEmpty) {
      return Center(
        child: Text(
          'No unmatched rows',
          style: AppTypography.body.copyWith(color: AppColors.neutral400),
        ),
      );
    }
    return SingleChildScrollView(
      child: UnmatchedReviewList(
        rows: state.parseResult!.unmatched,
        enabled: state.phase == CollectionImportPhase.review,
        onMap: (index) => _mapRow(context, ref, index),
        onIgnore: notifier.ignoreUnmatched,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Layouts
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(
    BuildContext context,
    WidgetRef ref,
    CollectionImportState state,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: _buildSourceChildren(context, ref, state),
          ),
        ),
        Container(width: 1, color: AppColors.neutral100),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                alignment: Alignment.centerLeft,
                child: _buildUnmatchedHeader(state),
              ),
              const Divider(),
              Expanded(
                child: _buildUnmatchedContent(context, ref, state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(
    BuildContext context,
    WidgetRef ref,
    CollectionImportState state,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        ..._buildSourceChildren(context, ref, state),
        if (state.parseResult != null &&
            state.parseResult!.unmatched.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _buildUnmatchedHeader(state),
          const SizedBox(height: AppSpacing.sm),
          UnmatchedReviewList(
            rows: state.parseResult!.unmatched,
            enabled: state.phase == CollectionImportPhase.review,
            onMap: (index) => _mapRow(context, ref, index),
            onIgnore:
                ref.read(collectionImportProvider.notifier).ignoreUnmatched,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Done state
  // ---------------------------------------------------------------------------

  Widget _buildDone(
    BuildContext context,
    WidgetRef ref,
    CollectionImportState state,
  ) {
    final diff = state.diff;
    final summary = diff == null
        ? ''
        : '${formatThousands(diff.adds.length)} added · '
            '${formatThousands(diff.removes.length)} removed · '
            '${formatThousands(diff.changes.length)} changed';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 48,
            color: AppColors.statusAddText,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Import complete', style: AppTypography.headingLg),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(summary, style: AppTypography.meta),
          ],
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: () => _cancel(context, ref),
            child: const Text('Back to collection'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky action bar
  // ---------------------------------------------------------------------------

  Widget _buildActionBar(
    BuildContext context,
    WidgetRef ref,
    CollectionImportState state,
  ) {
    final notifier = ref.read(collectionImportProvider.notifier);
    final committing = state.phase == CollectionImportPhase.committing;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(top: BorderSide(color: AppColors.neutral100)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: state.parseResult != null
                  ? ParseSummary(result: state.parseResult!)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: AppSpacing.md),
            OutlinedButton(
              onPressed: committing ? null : () => _cancel(context, ref),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: state.phase == CollectionImportPhase.review
                  ? notifier.commit
                  : null,
              child: const Text('Commit'),
            ),
          ],
        ),
      ),
    );
  }
}
