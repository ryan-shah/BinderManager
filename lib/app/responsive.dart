import 'package:flutter/widgets.dart';
import 'theme.dart';

enum LayoutMode { mobile, desktop }

LayoutMode layoutModeOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width >= kDesktopBreakpoint ? LayoutMode.desktop : LayoutMode.mobile;
}
