import 'package:flutter/material.dart';
import '../../app/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Settings', style: AppTypography.headingLg),
      ),
    );
  }
}
