import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/database/corpus_database.dart' as corpus_db;
import '../../../core/import/manabox_parser.dart';
import '../../../core/models/card_identity.dart';

/// Opens the manual-map dialog for an unmatched row. Resolves with the
/// chosen [CardIdentity], or null when cancelled.
Future<CardIdentity?> showMapUnmatchedDialog(
  BuildContext context, {
  required corpus_db.CorpusDatabase corpus,
  required UnmatchedRow row,
}) {
  return showDialog<CardIdentity>(
    context: context,
    builder: (_) => MapUnmatchedDialog(corpus: corpus, row: row),
  );
}

/// Name-search dialog that maps an unmatched CSV row to a corpus printing,
/// with the finish choice constrained to what that printing offers.
class MapUnmatchedDialog extends StatefulWidget {
  const MapUnmatchedDialog({
    super.key,
    required this.corpus,
    required this.row,
  });

  final corpus_db.CorpusDatabase corpus;
  final UnmatchedRow row;

  @override
  State<MapUnmatchedDialog> createState() => _MapUnmatchedDialogState();
}

class _MapUnmatchedDialogState extends State<MapUnmatchedDialog> {
  late final TextEditingController _searchController;
  List<corpus_db.Card> _results = const [];
  corpus_db.Card? _selected;
  Finish? _finish;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: _rawName);
    _search(_rawName);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _rawName {
    for (final entry in widget.row.raw.entries) {
      if (entry.key.toLowerCase() == 'name') return entry.value.trim();
    }
    return '';
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    final results = trimmed.isEmpty
        ? const <corpus_db.Card>[]
        : await widget.corpus.searchByName(trimmed, limit: 20);
    if (!mounted) return;
    setState(() {
      _results = results;
      if (_selected != null &&
          !results.any((c) => c.scryfallId == _selected!.scryfallId)) {
        _selected = null;
        _finish = null;
      }
    });
  }

  List<Finish> _finishesOf(corpus_db.Card card) {
    return card.finishes
        .split(',')
        .map((f) => Finish.tryParse(f.trim()))
        .whereType<Finish>()
        .toList();
  }

  void _select(corpus_db.Card card) {
    final finishes = _finishesOf(card);
    setState(() {
      _selected = card;
      // Prefer the finish the row claimed, when this printing offers it.
      final claimed = widget.row.resolvedIdentity?.finish;
      _finish = finishes.contains(claimed)
          ? claimed
          : (finishes.isEmpty ? null : finishes.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final finishes = _selected == null ? const <Finish>[] : _finishesOf(_selected!);

    return AlertDialog(
      backgroundColor: AppColors.neutral0,
      title: Text('Map to printing', style: AppTypography.headingMd),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search card name…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              style: AppTypography.query,
              onChanged: _search,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text('No matches', style: AppTypography.meta),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final card = _results[index];
                        final selected =
                            _selected?.scryfallId == card.scryfallId;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: AppColors.neutral100,
                          title: Text(card.name, style: AppTypography.body),
                          subtitle: Text(
                            '${card.setCode.toUpperCase()} · '
                            '#${card.collectorNumber} · ${card.rarity}',
                            style: AppTypography.meta,
                          ),
                          onTap: () => _select(card),
                        );
                      },
                    ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text('FINISH', style: AppTypography.sectionLabel),
                  const SizedBox(width: AppSpacing.md),
                  DropdownButton<Finish>(
                    value: _finish,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    style: AppTypography.meta,
                    items: [
                      for (final finish in finishes)
                        DropdownMenuItem(
                          value: finish,
                          child: Text(finish.name, style: AppTypography.meta),
                        ),
                    ],
                    onChanged: (f) => setState(() => _finish = f),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selected != null && _finish != null
              ? () => Navigator.of(context).pop(
                    CardIdentity(_selected!.scryfallId, _finish!),
                  )
              : null,
          child: const Text('Map'),
        ),
      ],
    );
  }
}
