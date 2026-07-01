import 'package:flutter/material.dart';
import '../../app/theme.dart';

class CollectionSearchScreen extends StatelessWidget {
  const CollectionSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Collection', style: AppTypography.headingLg),
      ),
    );
  }
}
