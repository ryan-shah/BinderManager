import 'package:flutter/material.dart';
import '../../app/theme.dart';

class BindersListScreen extends StatelessWidget {
  const BindersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Binders', style: AppTypography.headingLg),
      ),
    );
  }
}
