import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// A horizontal row of removable chips showing active filter terms.
///
/// Parses the query string to extract individual filter terms, displays each as
/// a [Chip] with a remove button, and calls [onChipRemoved] with the updated
/// query when a chip is dismissed.
class AppliedFilterChips extends StatelessWidget {
  const AppliedFilterChips({
    super.key,
    required this.query,
    required this.onChipRemoved,
  });

  final String query;
  final ValueChanged<String> onChipRemoved;

  /// Tokenize the query into individual filter terms.
  ///
  /// Handles:
  /// - Grouped terms like `(t:creature OR t:instant)`
  /// - Quoted oracle text like `o:"draw a card"`
  /// - Simple terms like `c:WU`, `r:rare`, `usd>=5`
  static List<String> tokenize(String query) {
    final tokens = <String>[];
    final q = query.trim();
    if (q.isEmpty) return tokens;

    var i = 0;
    while (i < q.length) {
      // Skip whitespace
      while (i < q.length && q[i] == ' ') {
        i++;
      }
      if (i >= q.length) break;

      if (q[i] == '(') {
        // Grouped term — find matching close paren
        final end = q.indexOf(')', i);
        if (end >= 0) {
          tokens.add(q.substring(i, end + 1));
          i = end + 1;
        } else {
          tokens.add(q.substring(i));
          break;
        }
      } else {
        // Regular term — might contain quotes
        final start = i;
        while (i < q.length && q[i] != ' ') {
          if (q[i] == '"') {
            // Skip to closing quote
            i++;
            while (i < q.length && q[i] != '"') {
              i++;
            }
            if (i < q.length) i++; // skip closing quote
          } else {
            i++;
          }
        }
        tokens.add(q.substring(start, i));
      }
    }

    return tokens;
  }

  /// Human-readable label for a filter token.
  static String _chipLabel(String token) {
    if (token.startsWith('c:')) {
      return 'Colors: ${token.substring(2)}';
    }
    if (token.startsWith('-c:')) {
      return 'Exclude: ${token.substring(3)}';
    }
    if (token.startsWith('(') && token.endsWith(')')) {
      // Grouped types: (t:creature OR t:instant)
      final inner = token.substring(1, token.length - 1);
      final types = RegExp(r't:(\w+)')
          .allMatches(inner)
          .map((m) => m.group(1)!)
          .map((t) => t[0].toUpperCase() + t.substring(1))
          .join(', ');
      return 'Type: $types';
    }
    if (token.startsWith('t:')) {
      final t = token.substring(2);
      return 'Type: ${t[0].toUpperCase()}${t.substring(1)}';
    }
    if (token.startsWith('usd>=')) {
      return 'Min: \$${token.substring(5)}';
    }
    if (token.startsWith('usd<=')) {
      return 'Max: \$${token.substring(5)}';
    }
    if (token.startsWith('s:')) {
      return 'Set: ${token.substring(2).toUpperCase()}';
    }
    if (token.startsWith('r:')) {
      final r = token.substring(2);
      return 'Rarity: ${r[0].toUpperCase()}${r.substring(1)}';
    }
    if (token.startsWith('is:')) {
      final flag = token.substring(3);
      return flag[0].toUpperCase() + flag.substring(1);
    }
    if (token.startsWith('o:"') && token.endsWith('"')) {
      return 'Text: ${token.substring(3, token.length - 1)}';
    }
    if (token == 'unused:true') {
      return 'Idle only';
    }
    return token;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = tokenize(query);
    if (tokens.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: tokens.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final token = tokens[index];
          return Chip(
            label: Text(
              _chipLabel(token),
              style: AppTypography.bodySm,
            ),
            deleteIcon: const Icon(Icons.close, size: 14),
            deleteIconColor: AppColors.neutral500,
            backgroundColor: AppColors.neutral75,
            side: const BorderSide(color: AppColors.neutral200),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onDeleted: () {
              final remaining = List<String>.from(tokens)..removeAt(index);
              onChipRemoved(remaining.join(' '));
            },
          );
        },
      ),
    );
  }
}
