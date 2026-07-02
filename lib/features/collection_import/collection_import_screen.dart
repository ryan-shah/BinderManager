import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// ManaBox CSV collection import (UI_COMPONENTS §3).
///
/// Skeleton — implemented in Phase 3 Agent E.
class CollectionImportScreen extends StatelessWidget {
  const CollectionImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Import collection', style: AppTypography.headingLg),
      ),
    );
  }
}
