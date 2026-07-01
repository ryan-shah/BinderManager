import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Displays a single card in the results list or grid.
///
/// Two variants controlled by [compact]:
/// - **compact** (grid): card image with name, price chip, rarity dot,
///   foil badge, and quantity badge.
/// - **row**: horizontal layout with small image, name, type, set, price, qty.
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.name,
    this.imageUri,
    this.typeLine,
    this.setCode,
    this.rarity,
    this.priceUsd,
    this.finishes,
    this.quantity,
    this.onTap,
    this.compact = true,
  });

  final String name;
  final String? imageUri;
  final String? typeLine;
  final String? setCode;
  final String? rarity;
  final double? priceUsd;

  /// Comma-joined finishes, e.g. "nonfoil,foil".
  final String? finishes;

  /// Collection quantity — badge shown when > 1.
  final int? quantity;
  final VoidCallback? onTap;

  /// `true` = grid card, `false` = row.
  final bool compact;

  // ---------------------------------------------------------------------------
  // Rarity color
  // ---------------------------------------------------------------------------

  static Color _rarityColor(String? rarity) {
    switch (rarity?.toLowerCase()) {
      case 'uncommon':
        return const Color(0xFFA0A0A0); // silver
      case 'rare':
        return const Color(0xFFCAA44E); // gold
      case 'mythic':
        return const Color(0xFFE07020); // orange
      case 'common':
      default:
        return AppColors.neutral300;
    }
  }

  // ---------------------------------------------------------------------------
  // Foil / Etched badge text
  // ---------------------------------------------------------------------------

  static String? _finishBadge(String? finishes) {
    if (finishes == null) return null;
    final parts = finishes.split(',').map((s) => s.trim().toLowerCase());
    if (parts.contains('etched')) return 'ETCHED';
    if (parts.contains('foil') && !parts.contains('nonfoil')) return 'FOIL';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Compact (grid) variant
  // ---------------------------------------------------------------------------

  Widget _buildCompact() {
    final badge = _finishBadge(finishes);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card image with overlays
          Expanded(
            child: Stack(
              children: [
                // Image / placeholder
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    child: imageUri != null
                        ? Image.network(
                            imageUri!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),

                // Qty badge — top-left
                if (quantity != null && quantity! > 1)
                  Positioned(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neutral900,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$quantity',
                        style: AppTypography.badge.copyWith(
                          color: AppColors.neutral0,
                        ),
                      ),
                    ),
                  ),

                // Price chip — bottom-right
                if (priceUsd != null)
                  Positioned(
                    bottom: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral0.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        '\$${priceUsd!.toStringAsFixed(2)}',
                        style: AppTypography.meta,
                      ),
                    ),
                  ),

                // Foil / etched badge — top-right
                if (badge != null)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral900.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.badge.copyWith(
                          color: AppColors.foilText,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Name + rarity dot
          Row(
            children: [
              // Rarity dot
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: AppSpacing.xs),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rarityColor(rarity),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Row variant
  // ---------------------------------------------------------------------------

  Widget _buildRow() {
    final badge = _finishBadge(finishes);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.neutral100),
          ),
        ),
        child: Row(
          children: [
            // Small image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.xs),
              child: SizedBox(
                width: 36,
                height: 50,
                child: imageUri != null
                    ? Image.network(
                        imageUri!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Name + type
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _rarityColor(rarity),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm,
                        ),
                      ),
                    ],
                  ),
                  if (typeLine != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        typeLine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta,
                      ),
                    ),
                ],
              ),
            ),

            // Set code
            if (setCode != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  setCode!.toUpperCase(),
                  style: AppTypography.meta,
                ),
              ),

            // Foil badge
            if (badge != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  badge,
                  style: AppTypography.badge.copyWith(
                    color: AppColors.foilText,
                  ),
                ),
              ),

            // Price
            SizedBox(
              width: 60,
              child: Text(
                priceUsd != null
                    ? '\$${priceUsd!.toStringAsFixed(2)}'
                    : '--',
                textAlign: TextAlign.right,
                style: AppTypography.meta,
              ),
            ),

            // Qty
            if (quantity != null && quantity! > 1)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neutral900,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$quantity',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.neutral0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Placeholder when no image
  // ---------------------------------------------------------------------------

  static Widget _buildPlaceholder() {
    return Container(
      color: AppColors.neutral75,
      child: const Center(
        child: Icon(Icons.style, color: AppColors.neutral300, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact() : _buildRow();
  }
}
