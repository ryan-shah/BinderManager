import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Decklist paste/file import (UI_COMPONENTS §4).
///
/// Skeleton — implemented in Phase 3 Agent F.
class DecklistImportScreen extends StatelessWidget {
  const DecklistImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Import deck', style: AppTypography.headingLg),
      ),
    );
  }
}
