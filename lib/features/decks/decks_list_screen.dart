import 'package:flutter/material.dart';
import '../../app/theme.dart';

class DecksListScreen extends StatelessWidget {
  const DecksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Decks', style: AppTypography.headingLg),
      ),
    );
  }
}
