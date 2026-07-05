import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Change review — diff & commit/rollback (§10) — Package 0 skeleton.
///
/// Agent H replaces this with the real review surface: the staged diff
/// grouped by binder, Add/Remove/Move rows with exact location
/// instructions, overflow changes, and the Commit / Roll back bar (§13).
class ChangeReviewScreen extends StatelessWidget {
  const ChangeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Review changes', style: AppTypography.headingLg),
      ),
    );
  }
}
