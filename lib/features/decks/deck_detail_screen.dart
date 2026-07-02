import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Deck detail: entries, reservation indicators, flags (UI_COMPONENTS §5).
///
/// Skeleton — implemented in Phase 3 Agent F.
class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Deck $deckId', style: AppTypography.headingLg),
      ),
    );
  }
}
