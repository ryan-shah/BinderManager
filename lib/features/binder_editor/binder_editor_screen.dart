import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Binder editor / rule definition (§8) — Package 0 skeleton.
///
/// Agent G replaces this with the real editor: type (layout/pages/sides),
/// contents query reusing the §6 filter controls, group/sort organization,
/// virtual toggle, and the live match/fit/overflow preview.
class BinderEditorScreen extends StatelessWidget {
  const BinderEditorScreen({super.key, this.binderId});

  /// Null when creating a new binder.
  final String? binderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          binderId == null ? 'New binder' : 'Edit binder',
          style: AppTypography.headingLg,
        ),
      ),
    );
  }
}
