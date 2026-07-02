import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/import/manabox_parser.dart';

/// Formats an integer with thousands separators (e.g. `1240` → `1,240`).
String formatThousands(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      );
}

/// One-line parse summary in the system (monospace) voice:
/// `1,240 rows · 1,228 matched · 12 unmatched`.
class ParseSummary extends StatelessWidget {
  const ParseSummary({super.key, required this.result});

  final ManaBoxParseResult result;

  @override
  Widget build(BuildContext context) {
    final matchedRows = result.totalDataRows - result.unmatched.length;
    return Text(
      '${formatThousands(result.totalDataRows)} rows · '
      '${formatThousands(matchedRows)} matched · '
      '${formatThousands(result.unmatched.length)} unmatched',
      style: AppTypography.meta,
      overflow: TextOverflow.ellipsis,
    );
  }
}
