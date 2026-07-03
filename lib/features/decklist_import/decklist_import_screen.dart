import 'dart:async';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../core/database/tables/deck_tables.dart';
import '../../core/import/decklist_parser.dart';
import '../../shared/providers/deck_providers.dart';

/// Decklist import (UI_COMPONENTS §4).
///
/// - **Desktop** (>= 808 px): two-pane — left is the paste box, file
///   button, and deck metadata; right is the live sectioned parse preview.
/// - **Mobile**: single scrolling column.
///
/// The printing-fidelity and unowned prompts appear as an AlertDialog on
/// desktop and a bottom sheet on mobile. Commit lives in a sticky bar.
class DecklistImportScreen extends ConsumerStatefulWidget {
  const DecklistImportScreen({super.key});

  @override
  ConsumerState<DecklistImportScreen> createState() =>
      _DecklistImportScreenState();
}

class _DecklistImportScreenState extends ConsumerState<DecklistImportScreen> {
  late final TextEditingController _textController;
  late final TextEditingController _nameController;
  late final TextEditingController _formatController;
  Timer? _debounce;
  bool _promptVisible = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(deckImportProvider);
    _textController = TextEditingController(text: state.sourceText);
    _nameController = TextEditingController(text: state.deckName);
    _formatController = TextEditingController(text: state.format);

    // Prompts pending from a previous visit (state outlives the screen).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = ref.read(deckImportProvider);
      if (s.needsFidelity) {
        _showFidelityPrompt();
      } else if (s.unowned.isNotEmpty) {
        _showUnownedPrompt();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    _nameController.dispose();
    _formatController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onTextChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(deckImportProvider.notifier).parseText(text);
    });
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(label: 'Decklist', extensions: ['txt']);
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await ref.read(deckImportProvider.notifier).loadFile(file.name, bytes);
    if (!mounted) return;
    final state = ref.read(deckImportProvider);
    _textController.text = state.sourceText;
    _nameController.text = state.deckName;
  }

  void _reset() {
    ref.read(deckImportProvider.notifier).reset();
    _textController.clear();
    _nameController.clear();
    _formatController.clear();
  }

  // ---------------------------------------------------------------------------
  // Prompts
  // ---------------------------------------------------------------------------

  Future<void> _showPrompt(WidgetBuilder builder) async {
    if (_promptVisible) return;
    _promptVisible = true;
    try {
      if (layoutModeOf(context) == LayoutMode.desktop) {
        await showDialog<void>(context: context, builder: builder);
      } else {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: builder(context),
            ),
          ),
        );
      }
    } finally {
      _promptVisible = false;
    }
  }

  void _showFidelityPrompt() {
    final notifier = ref.read(deckImportProvider.notifier);
    _showPrompt(
      (context) => _PromptContent(
        title: 'Choose printings',
        body: 'Some cards in this list don\'t say which printing they are. '
            'How should they be filled from your collection?',
        actions: [
          _PromptAction(
            label: 'Cheapest first',
            onTap: () {
              Navigator.of(context).pop();
              notifier.chooseFidelity(FidelityMode.cheapestFirst);
            },
          ),
          _PromptAction(
            label: 'Pick manually',
            onTap: () {
              Navigator.of(context).pop();
              notifier.chooseFidelity(FidelityMode.pickManually);
            },
          ),
        ],
      ),
    );
  }

  void _showUnownedPrompt() {
    final notifier = ref.read(deckImportProvider.notifier);
    final unowned = ref.read(deckImportProvider).unowned;
    _showPrompt(
      (context) => _PromptContent(
        title: 'Cards you don\'t own',
        body: 'This deck names cards that aren\'t in your collection:',
        detail: [
          for (final shortfall in unowned)
            '${shortfall.missing}× ${shortfall.card.name}',
        ].join('\n'),
        actions: [
          _PromptAction(
            label: 'Add to collection',
            onTap: () {
              Navigator.of(context).pop();
              notifier.resolveUnowned(UnownedChoice.addToCollection);
            },
          ),
          _PromptAction(
            label: 'Import & mark unowned',
            onTap: () {
              Navigator.of(context).pop();
              notifier.resolveUnowned(UnownedChoice.importUnowned);
            },
          ),
          _PromptAction(
            label: 'Back out & edit',
            onTap: () {
              Navigator.of(context).pop();
              notifier.resolveUnowned(UnownedChoice.backOut);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showPrintingPicker(int lineIndex, DeckImportLine line) async {
    final notifier = ref.read(deckImportProvider.notifier);
    final resolution = line.resolution;
    if (resolution is! ResolvedByName) return;
    await _showPrompt(
      (context) => _PromptContent(
        title: 'Pick a printing — ${line.raw.name}',
        actions: [
          for (final candidate in resolution.candidates)
            _PromptAction(
              label: '(${candidate.setCode.toUpperCase()}) '
                  '${candidate.collectorNumber}'
                  '${candidate.priceUsd != null ? ' — \$${candidate.priceUsd!.toStringAsFixed(2)}' : ''}',
              onTap: () {
                Navigator.of(context).pop();
                notifier.pickPrinting(lineIndex, candidate);
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deckImportProvider);
    final notifier = ref.read(deckImportProvider.notifier);

    ref.listen<DeckImportState>(deckImportProvider, (previous, next) {
      if (next.needsFidelity && !(previous?.needsFidelity ?? false)) {
        _showFidelityPrompt();
      } else if (next.unowned.isNotEmpty &&
          (previous?.unowned.isEmpty ?? true)) {
        _showUnownedPrompt();
      }
      if (next.phase == DeckImportPhase.done &&
          previous?.phase != DeckImportPhase.done &&
          next.createdDeckId != null) {
        final deckId = next.createdDeckId!;
        notifier.reset();
        context.go('/decks/$deckId');
      }
      // Sync the text field when the provider updates source text
      // (e.g. after a printing pick). Setting controller.text does
      // NOT fire TextField.onChanged, so this won't re-trigger parsing.
      if (next.sourceText != (previous?.sourceText ?? '') &&
          next.sourceText != _textController.text) {
        _textController.text = next.sourceText;
      }
    });

    final desktop = layoutModeOf(context) == LayoutMode.desktop;

    final input = _buildInputColumn(state, notifier);
    final preview = _buildPreview(state);

    return Scaffold(
      body: SafeArea(
        child: desktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: input,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    color: AppColors.neutral100,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [preview],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [input, const SizedBox(height: AppSpacing.lg), preview],
              ),
      ),
      bottomNavigationBar: _buildCommitBar(state, notifier),
    );
  }

  Widget _buildInputColumn(DeckImportState state, DeckImportNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              tooltip: 'Back to decks',
              onPressed: () => context.go('/decks'),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Import deck', style: AppTypography.headingLg),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _textController,
          onChanged: _onTextChanged,
          maxLines: 10,
          style: AppTypography.query,
          decoration: const InputDecoration(
            hintText: '4 Lightning Bolt (M10) 146',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text('or import file'),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('DECK', style: AppTypography.sectionLabel),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _nameController,
          onChanged: (value) => notifier.setMetadata(name: value),
          style: AppTypography.body,
          decoration: const InputDecoration(hintText: 'Deck name'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _formatController,
          onChanged: (value) => notifier.setMetadata(format: value),
          style: AppTypography.body,
          decoration: const InputDecoration(
            hintText: 'Format (e.g. modern)',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: Text('Assembled', style: AppTypography.body)),
            Switch(
              value: state.assembled,
              onChanged: (v) => notifier.setMetadata(assembled: v),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: Text('Shared', style: AppTypography.body)),
            Switch(
              value: state.shared,
              onChanged: (v) => notifier.setMetadata(shared: v),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  Widget _buildPreview(DeckImportState state) {
    if (state.phase == DeckImportPhase.idle) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Paste a decklist to see a live preview.',
          style: AppTypography.bodySm,
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state.phase == DeckImportPhase.parsing) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: LinearProgressIndicator(),
      );
    }
    if (state.phase == DeckImportPhase.error) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.statusRemoveBg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.statusRemoveBorder),
        ),
        child: Text(
          state.error ?? 'Something went wrong.',
          style: AppTypography.bodySm
              .copyWith(color: AppColors.statusRemoveText),
        ),
      );
    }

    final sections = <Widget>[];
    for (final section in DeckSection.values) {
      final rows = <Widget>[];
      for (var i = 0; i < state.lines.length; i++) {
        final line = state.lines[i];
        if (line.raw.section != section) continue;
        rows.add(_buildLineRow(i, line, state));
      }
      if (rows.isEmpty) continue;
      sections
        ..add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            switch (section) {
              DeckSection.main => 'MAIN',
              DeckSection.sideboard => 'SIDEBOARD',
              DeckSection.maybeboard => 'MAYBEBOARD',
            },
            style: AppTypography.sectionLabel,
          ),
        ))
        ..addAll(rows);
    }

    if (state.errors.isNotEmpty) {
      sections
        ..add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            'ERRORS',
            style: AppTypography.sectionLabel
                .copyWith(color: AppColors.statusRemoveText),
          ),
        ))
        ..addAll([
          for (final error in state.errors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                'Line ${error.lineNumber}: ${error.message}',
                style: AppTypography.meta
                    .copyWith(color: AppColors.statusRemoveText),
              ),
            ),
        ]);
    }

    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Nothing parsed yet.',
          style: AppTypography.bodySm,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }

  Widget _buildLineRow(int index, DeckImportLine line, DeckImportState state) {
    final notifier = ref.read(deckImportProvider.notifier);

    final (icon, color) = switch (line.resolution) {
      Unresolved() => (Icons.error_outline, AppColors.statusRemoveText),
      ResolvedByName() when line.planned.isEmpty => (
          Icons.help_outline,
          AppColors.amberDot,
        ),
      _ when line.hasUnowned => (
          Icons.warning_amber_outlined,
          AppColors.amberText,
        ),
      _ => (Icons.check_circle_outline, AppColors.statusAddText),
    };

    // Printing summary: explicit (SET) #, or the resolved printing(s).
    String? printingLabel;
    if (line.planned.isNotEmpty) {
      final card = line.planned.first.card;
      printingLabel =
          '(${card.setCode.toUpperCase()}) ${card.collectorNumber}'
          '${line.planned.length > 1 ? ' +${line.planned.length - 1}' : ''}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.neutral100)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 32,
            child: Text('${line.raw.quantity}×', style: AppTypography.meta),
          ),
          Expanded(
            child: Text(
              line.raw.name,
              style: AppTypography.bodySm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (line.resolution is Unresolved) ...[
            Text(
              'not found',
              style: AppTypography.meta
                  .copyWith(color: AppColors.statusRemoveText),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (printingLabel != null) ...[
            Text(printingLabel, style: AppTypography.meta),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (line.hasUnowned) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: AppColors.amberBg,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: Border.all(color: AppColors.amberBorder),
              ),
              child: Text(
                'UNOWNED',
                style:
                    AppTypography.tag.copyWith(color: AppColors.amberText),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (line.isPendingPick && state.fidelityMode != null) ...[
            TextButton(
              onPressed: () => _showPrintingPicker(index, line),
              child: const Text('Pick'),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text('Shared', style: AppTypography.bodyXs),
          Switch(
            value: line.shared,
            onChanged: (_) => notifier.toggleEntryShared(index),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Commit bar
  // ---------------------------------------------------------------------------

  Widget _buildCommitBar(DeckImportState state, DeckImportNotifier notifier) {
    final totalCards = state.lines.fold<int>(
      0,
      (sum, line) => sum + line.raw.quantity,
    );
    final summary = state.lines.isEmpty
        ? ''
        : '$totalCards cards'
            '${state.errors.isNotEmpty ? ' · ${state.errors.length} errors' : ''}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral0,
        border: Border(top: BorderSide(color: AppColors.neutral100)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(summary, style: AppTypography.meta),
            const Spacer(),
            TextButton(
              onPressed: _reset,
              child: const Text('Reset'),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton(
              onPressed: state.canCommit ? notifier.commit : null,
              child: Text(
                state.phase == DeckImportPhase.committing
                    ? 'Committing...'
                    : 'Commit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prompt widgets (shared between dialog and bottom sheet)
// ---------------------------------------------------------------------------

class _PromptAction {
  const _PromptAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _PromptContent extends StatelessWidget {
  const _PromptContent({
    required this.title,
    this.body,
    this.detail,
    required this.actions,
  });

  final String title;
  final String? body;
  final String? detail;
  final List<_PromptAction> actions;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTypography.headingMd),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(body!, style: AppTypography.bodySm),
        ],
        if (detail != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: SingleChildScrollView(
              child: Text(detail!, style: AppTypography.meta),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton(
              onPressed: action.onTap,
              child: Text(action.label),
            ),
          ),
      ],
    );

    // Inside a dialog route, wrap in Material chrome; the bottom sheet
    // already provides its own.
    if (ModalRoute.of(context) is RawDialogRoute) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: content,
          ),
        ),
      );
    }
    // Constrain height so the detail list scrolls instead of overflowing.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: content,
    );
  }
}
