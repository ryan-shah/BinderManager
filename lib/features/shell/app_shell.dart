import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../shared/widgets/data_freshness_banner.dart';

/// Persistent navigation frame wrapping all main routes.
///
/// - Desktop (>= 808 px): left sidebar + top bar + content area.
/// - Mobile  (<  808 px): top app bar + bottom navigation bar + content area.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  final int currentIndex;
  final Widget child;

  static const _destinations = [
    _Destination('Binders', Icons.auto_stories, '/binders'),
    _Destination('Collection', Icons.search, '/collection'),
    _Destination('Decks', Icons.list_alt, '/decks'),
    _Destination('Settings', Icons.settings, '/settings'),
  ];

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_destinations[index].path);
  }

  // ---------------------------------------------------------------------------
  // Desktop layout
  // ---------------------------------------------------------------------------

  Widget _buildDesktop(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        SizedBox(
          width: 208,
          child: ColoredBox(
            color: AppColors.neutral950,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
                    child: Text(
                      'BinderManager',
                      style: AppTypography.headingSm
                          .copyWith(color: AppColors.neutral0),
                    ),
                  ),

                  // "NAVIGATION" section label
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(
                      'NAVIGATION',
                      style: AppTypography.sectionLabel
                          .copyWith(color: AppColors.neutral250),
                    ),
                  ),

                  // Nav items
                  for (var i = 0; i < _destinations.length; i++)
                    _SidebarNavItem(
                      icon: _destinations[i].icon,
                      label: _destinations[i].label,
                      selected: i == currentIndex,
                      onTap: () => _onDestinationSelected(context, i),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // "BINDER SHORTCUTS" section label (placeholder)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(
                      'BINDER SHORTCUTS',
                      style: AppTypography.sectionLabel
                          .copyWith(color: AppColors.neutral250),
                    ),
                  ),

                  // Spacer pushes any future collapse button to the bottom
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),

        // Right side: top bar + content
        Expanded(
          child: Column(
            children: [
              // Top bar
              Container(
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.neutral0,
                  border: Border(
                    bottom: BorderSide(color: AppColors.neutral100),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                alignment: Alignment.centerRight,
                child: const DataFreshnessBanner(
                  // Placeholder date — Agent A will supply a real provider.
                  lastUpdated: null,
                ),
              ),

              // Content
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mobile layout
  // ---------------------------------------------------------------------------

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _destinations[currentIndex].label,
          style: AppTypography.headingMd,
        ),
        backgroundColor: AppColors.neutral0,
        surfaceTintColor: AppColors.neutral0,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.neutral100),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) => _onDestinationSelected(context, i),
          selectedItemColor: AppColors.neutral900,
          unselectedItemColor: AppColors.neutral400,
          backgroundColor: AppColors.neutral0,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: AppTypography.bodyXs.copyWith(
            color: AppColors.neutral900,
          ),
          unselectedLabelStyle: AppTypography.bodyXs.copyWith(
            color: AppColors.neutral400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories),
              label: 'Binders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Collection',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Decks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final mode = layoutModeOf(context);
    return mode == LayoutMode.desktop
        ? _buildDesktop(context)
        : _buildMobile(context);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Destination {
  const _Destination(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral800 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.neutral0 : AppColors.neutral250,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodySm.copyWith(
                color: selected ? AppColors.neutral0 : AppColors.neutral250,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
